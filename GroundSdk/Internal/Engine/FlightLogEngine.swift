// Copyright (C) 2019 Parrot Drones SAS
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.

import Foundation

/// FlightLog engine.
class FlightLogEngine: FlightLogEngineBase {

    /// flightLogReporter facility
    private let flightLogReporter: FlightLogReporterCore

    /// Name of the directory in which the flightLogs should be stored
    private let flightLogsLocalDirName = "FlightLogs"

    /// Monitor of the connectivity changes
    private var connectivityMonitor: MonitorCore!

    /// Monitor of the userAccount changes
    private var userAccountMonitor: MonitorCore!

    /// User account information
    private var userAccountInfo: UserAccountInfoCore?

    /// Extension of processing log files
    private var processingExtension = "anonymizing"

    /// The uploader.
    /// `nil` until engine is started.
    private var uploader: FlightLogUploader?

    /// Space quota in megabytes
    private var spaceQuotaInMb: Int = 0

    /// Constructor
    ///
    /// - Parameter enginesController: engines controller
    public required init(enginesController: EnginesControllerCore) {
        ULog.d(.flightLogEngineTag, "Loading FlightLogEngine.")
        spaceQuotaInMb = GroundSdkConfig.sharedInstance.flightLogQuotaMb ?? 0
        flightLogReporter = FlightLogReporterCore(store: enginesController.facilityStore)

        super.init(enginesController: enginesController, engineDirName: flightLogsLocalDirName)
        publishUtility(FlightLogStorageCoreImpl(engine: self))
    }

    public override func startEngine() {
        ULog.d(.flightLogEngineTag, "Starting FlightLogEngine.")
        super.startEngine()
        // Get the UserAccount Utility in order to know if the user changes
        let userAccountUtility = utilities.getUtility(Utilities.userAccount)!
        // get userInfo and monitor changes
        userAccountInfo = userAccountUtility.userAccountInfo
        // monitor userAccount changes
        userAccountMonitor = userAccountUtility.startMonitoring(accountDidChange: { (newInfo) in
            // If the user account changes and if private mode is set or old data upload is denied, we delete all files
            if newInfo?.changeDate != self.userAccountInfo?.changeDate
                && (newInfo?.privateMode == true
                        || (newInfo?.account != nil
                                && newInfo?.dataUploadPolicy != .deny // keep old data until upload is allowed
                                && newInfo?.oldDataPolicy == .denyUpload)) {
                ULog.d(.parrotCloudFlightLogTag,
                       "User account change with private mode or old data upload denied -> delete all flight logs")
                self.dropFlightLogs()
                self.userAccountInfo = newInfo
            } else {
                self.userAccountInfo = newInfo
                self.startFlightLogUploadProcess()
            }
        })

        if spaceQuotaInMb != 0 {
            try? FileManager.cleanOldInDirectory(url: engineDir, fileExt: "bin",
                                                    totalMaxSizeMb: spaceQuotaInMb, includingSubfolders: true)
        }

        connectivityMonitor = utilities.getUtility(Utilities.internetConnectivity)!
            .startMonitoring { [unowned self] internetAvailable in
                if internetAvailable {
                    ULog.d(.parrotCloudFlightLogTag, "Internet ready")
                    self.startFlightLogUploadProcess()
                } else {
                    ULog.d(.parrotCloudFlightLogTag, "Internet NOT ready")
                    self.cancelCurrentUpload()
                }
        }
        // can force unwrap because this utility is always published.
        let cloudServer = utilities.getUtility(Utilities.cloudServer)!
        uploader = FlightLogUploader(cloudServer: cloudServer)

        flightLogReporter.publish()
    }

    public override func stopEngine() {
        ULog.d(.flightLogEngineTag, "Stopping FlightLogEngine.")
        userAccountMonitor?.stop()
        userAccountMonitor = nil
        flightLogReporter.unpublish()
        uploader = nil
        connectivityMonitor.stop()
        super.stopEngine()
    }

    /// Queue for processing flight logs
    override func queueForProcessing() {
        if userAccountInfo?.privateMode == true {
            dropFlightLogs()
        } else {
            startFlightLogUploadProcess()
        }
    }

    /// Starts the uploading process of flight log files.
    ///
    /// If an uploading process is already started, we only update the pending count.
    private func startFlightLogUploadProcess() {
        guard GroundSdkConfig.sharedInstance.flightLogServer != nil,
              GroundSdkConfig.sharedInstance.applicationKey != nil else {
              ULog.d(.parrotCloudFlightLogTag, "Flight log server or application key not defined.")
              return
        }
        guard !flightLogReporter.isUploading else {
            flightLogReporter.update(pendingCount: pendingFlightLogUrls.count).notifyUpdated()
            ULog.d(.parrotCloudFlightLogTag, "Did not start flight log upload process (already uploading)")
            return
        }
        ULog.d(.parrotCloudFlightLogTag, "Start flight log upload process")
        processNextFlightLog()
    }

    /// Try to upload the first flightLog of the list.
    ///
    /// It will only start the upload if the engine is not currently uploading a flightLog, if Internet connectivity
    /// is available, if user account is present, if a token is present, and if data upload is allowed.
    private func processNextFlightLog() {
        flightLogReporter.update(pendingCount: pendingFlightLogUrls.count)

        // Check if upload process can go on
        let abortReason: String?
        if userAccountInfo?.account == nil {
            abortReason = "no account"
        } else if userAccountInfo!.token == nil || userAccountInfo!.token! == "" {
            abortReason = "no token"
        } else if userAccountInfo!.dataUploadPolicy == .deny {
            abortReason = "denied by policy"
        } else if uploader == nil {
            abortReason = "no uploader"
        } else if utilities.getUtility(Utilities.internetConnectivity)?.internetAvailable == false {
            abortReason = "no internet"
        } else {
            abortReason = nil
        }

        if let reason = abortReason {
            ULog.d(.parrotCloudFlightLogTag, "Stop flight log upload process (\(reason))")
            flightLogReporter.update(isUploading: false).notifyUpdated()
            return
        }

        guard let baseUrl = URL(string: GroundSdkConfig.sharedInstance.flightLogServer!) else {
            ULog.d(.parrotCloudFlightLogTag, "Stop flight log upload process (server incorrectly configured)")
            flightLogReporter.update(isUploading: false).notifyUpdated()
            return
        }

        guard let flightLog = pendingFlightLogUrls.first else {
            ULog.d(.parrotCloudFlightLogTag, "Stop flight log upload process (no file left)")
            flightLogReporter.update(isUploading: false).notifyUpdated()
            return
        }

        ULog.d(.parrotCloudFlightLogTag, "Process next flight log \(flightLog.absoluteString)")

        if userAccountInfo?.oldDataPolicy == .denyUpload {
            // check if the file is before the authentication date
            // if yes, we remove the file because the user did not accept the download of the data collected
            // before the authentication
            let toRemove: Bool
            if let attrs = try? FileManager.default.attributesOfItem(
                atPath: flightLog.path), let creationDate = attrs[.creationDate] as? Date,
               let userDate = userAccountInfo?.changeDate {
                toRemove = creationDate < userDate
                if toRemove {
                    ULog.d(.parrotCloudFlightLogTag, "Remove (creationDate < userDate)")
                }
            } else {
                ULog.d(.parrotCloudFlightLogTag, "Remove (no date)")
                toRemove = true
            }
            if toRemove {
                deleteFlightLog(at: flightLog, reason: "denied")
                processNextFlightLog()
                return
            }
        }

        if let attrs = try? FileManager.default.attributesOfItem(atPath: flightLog.path) {
            let fileSize = attrs[.size] as? UInt64
            ULog.d(.parrotCloudFlightLogTag,
                   "Flight log \(flightLog.lastPathComponent) size: \(String(describing: fileSize))")
        }

        /// Anonymize file if necessary.
        switch userAccountInfo?.dataUploadPolicy {
        case .anonymous:
            anonymize(baseUrl: baseUrl, flightLog: flightLog, profile: .ANONYMOUS_PROFILE)
        case .noGps:
            anonymize(baseUrl: baseUrl, flightLog: flightLog, profile: .NO_GPS_PROFILE)
        case .full, .noMedia:
            uploadFlight(baseUrl: baseUrl, flightLogUrl: flightLog)
        case .deny, .none:
            /// should not happen
            break
        }
   }

    /// Anonymization of flight log
    ///
    /// - Parameters
    ///    - baseUrl: url of the server
    ///    - flightLogUrl: url of the flight log to upload
    ///    - profile:  anonymization profile
    private func anonymize(baseUrl: URL, flightLog: URL, profile: Profile) {
        var result: AnonymizerResult?
        let outFile: URL = URL(fileURLWithPath: "\(flightLog.path).anon")
        let queue = DispatchQueue(label: "com.parrot.gsdk.FlightLogEngine")

        /// check if file is already here else create it.
        let filePath = outFile.path
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: filePath) {
            self.uploadFlight(baseUrl: baseUrl, flightLogUrl: outFile)
        } else {
            let processingFlightLog = flightLog
                .deletingPathExtension()
                .appendingPathExtension(processingExtension)
            // move file for debug purpose
            do {
                try fileManager.moveItem(at: flightLog, to: processingFlightLog)
            } catch {
                ULog.e(.parrotCloudFlightLogTag, "Failed to rename log to processing file \(flightLog.absoluteString)")
                return
            }
            queue.async {
                result = Anonymizer.convert(flightLog.path, outFile: outFile.path, profile: profile)
                DispatchQueue.main.async { [weak self] in
                    // move file back
                    do {
                        try fileManager.moveItem(at: processingFlightLog, to: flightLog)
                    } catch {
                        ULog.e(.parrotCloudFlightLogTag,
                               "Failed to rename processing file to log \(flightLog.absoluteString)")
                        return
                    }
                    if result == AnonymizerResult.SUCCESS {
                        self?.uploadFlight(baseUrl: baseUrl, flightLogUrl: outFile)
                    } else if result == AnonymizerResult.NOT_NEEDED {
                        self?.uploadFlight(baseUrl: baseUrl, flightLogUrl: flightLog)
                    } else {
                      self?.deleteFlightLog(at: flightLog, reason: "error")
                      self?.processNextFlightLog()
                    }
                }
            }
        }
    }

    /// Upload flight log
    ///
    /// - Parameters
    ///    - baseUrl: url of the server
    ///    - flightLogUrl: url of the flight log to upload
    private func uploadFlight(baseUrl: URL, flightLogUrl: URL) {
        let logFileName = flightLogUrl.lastPathComponent
        ULog.d(.parrotCloudFlightLogTag, "Start uploading \(logFileName)")

        guard currentUploadRequest == nil else {
            ULog.d(.parrotCloudFlightLogTag, "Did not upload flight log (upload request in progress)")
            flightLogReporter.update(isUploading: false).notifyUpdated()
            return
        }

        flightLogReporter.update(isUploading: true).notifyUpdated()
        currentUploadRequest = uploader?.upload(baseUrl: baseUrl, flightLogUrl: flightLogUrl,
                                                token: self.userAccountInfo!.token!) { flightLogUrl, error in
            self.currentUploadRequest = nil
            if let error = error {
                switch error {
                case .badRequest:
                    ULog.d(.parrotCloudFlightLogTag, "Upload error (bad request) \(logFileName)")
                    // delete file and stop uploading to avoid multiple errors
                    self.deleteFlightLog(at: flightLogUrl, reason: "error")
                    self.flightLogReporter.update(isUploading: false).notifyUpdated()
                case .badFlightLog:
                    ULog.d(.parrotCloudFlightLogTag, "Upload error (bad flight log) \(logFileName)")
                    self.deleteFlightLog(at: flightLogUrl, reason: "error")
                    self.processNextFlightLog()
                case .serverError,
                     .connectionError:
                    // Stop uploading if the server is not accessible
                    ULog.d(.parrotCloudFlightLogTag, "Upload error (server or connection) \(logFileName)")
                    self.flightLogReporter.update(isUploading: false).notifyUpdated()
                case .canceled:
                    ULog.d(.parrotCloudFlightLogTag, "Upload canceled \(logFileName)")
                    self.flightLogReporter.update(isUploading: false).notifyUpdated()
                }
            } else {    // success
                ULog.d(.parrotCloudFlightLogTag, "Flight log successfully uploaded \(logFileName)")
                self.deleteFlightLog(at: flightLogUrl, reason: "sent")
                self.processNextFlightLog()
            }
        }
    }

    /// Remove the given flightLog from the pending ones and delete it from the file system.
    ///
    /// - Parameters
    ///    - flightLog: the flightLog to delete
    ///    - reason: the reason why flightLog should be deleted
    private func deleteFlightLog(at flightLogUrl: URL, reason: String) {
        /// remove basic file if it exists
        var flightLogUrlReal = flightLogUrl
        if flightLogUrl.pathExtension == "anon" {
            /// remove anon flightLog
            collector?.deleteFlightLog(at: flightLogUrl)
            flightLogUrlReal = URL(fileURLWithPath: flightLogUrl.path).deletingPathExtension()
        }

        /// remove original file
        ULog.d(.parrotCloudFlightLogTag, "Delete flight log (\(reason)) \(flightLogUrl.lastPathComponent)")
        if pendingFlightLogUrls.first == flightLogUrlReal {
            pendingFlightLogUrls.remove(at: 0)
        } else {
            ULog.w(.parrotCloudFlightLogTag, "Flight log to remove is not the first one of the pending list")
            // fallback
            if let index: Int = pendingFlightLogUrls.firstIndex(where: {$0 == flightLogUrlReal}) {
                pendingFlightLogUrls.remove(at: index)
            } else {
                ULog.w(.parrotCloudFlightLogTag, "Flight log not found in the pending list")
            }
        }
        collector?.deleteFlightLog(at: flightLogUrlReal)
        GroundSdkCore.logEvent(message: "EVT:LOGS;event='delete';reason='\(reason)';" +
            "file='\(flightLogUrlReal.lastPathComponent)'")
    }

    /// Deletes all locally stored flightLogs waiting to be uploaded.
    ///
    /// This is called when the user account changes. All recorded flightLogs are dropped since there is no proper
    /// user account identifier to use for upload anymore.
    private func dropFlightLogs() {

        // stop the upload if any
        cancelCurrentUpload()

        pendingFlightLogUrls.forEach { (flightLogUrl) in
            collector?.deleteFlightLog(at: flightLogUrl)
            GroundSdkCore.logEvent(message: "EVT:LOGS;event='delete';reason='denied';" +
                                    "file='\(flightLogUrl.lastPathComponent)'")
        }

        // clear all pending flightLogs
        pendingFlightLogUrls.removeAll()

        // update the facility
        flightLogReporter.update(isUploading: false).update(pendingCount: 0).notifyUpdated()
    }
}
