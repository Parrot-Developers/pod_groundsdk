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
                ULog.d(.myparrot,
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
        ULog.d(.myparrot, "FLIGHTLOG active connectivityMonitor")
        connectivityMonitor = utilities.getUtility(Utilities.internetConnectivity)!
            .startMonitoring { [unowned self] internetAvailable in
                if internetAvailable {
                    ULog.d(.myparrot, "FLIGHTLOG internet ready")
                    self.startFlightLogUploadProcess()
                } else {
                    ULog.d(.myparrot, "FLIGHTLOG internet NOT ready")
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
        ULog.d(.myparrot, "FLIGHTLOG (local) \(pendingFlightLogUrls)")
        if userAccountInfo?.privateMode == true {
            dropFlightLogs()
        } else {
            startFlightLogUploadProcess()
        }
    }

    /// Start the uploading process of flight log files
    ///
    /// if an upload is already started we are only updating the pending count
    /// uploading process is only started when it is not already uploading files.
    private func startFlightLogUploadProcess() {
        ULog.d(.myparrot, "startFlightLogUploadProcess")
        guard !flightLogReporter.isUploading,
            GroundSdkConfig.sharedInstance.flightLogServer != nil,
            GroundSdkConfig.sharedInstance.applicationKey != nil, userAccountInfo?.token != nil,
            self.userAccountInfo!.token! != "" else {
            flightLogReporter.update(pendingCount: pendingFlightLogUrls.count)
            ULog.d(.myparrot, "startFlightLogUploadProcess abort (was uploading)")
            return
        }
        processNextFlightLog()
    }

    /// Try to upload the first flightLog of the list.
    ///
    /// It will only start the upload if the engine is not currently uploading a flightLog, if Internet connectivity
    /// is available, if user account is present, if a token is present, and if data upload is allowed.
    private func processNextFlightLog() {
        ULog.d(.myparrot, "processNextFlightLog")
        flightLogReporter.update(pendingCount: pendingFlightLogUrls.count)
        if userAccountInfo?.account == nil
            || userAccountInfo?.token == nil
            || userAccountInfo?.token == ""
            || userAccountInfo?.dataUploadPolicy == .deny
            || utilities.getUtility(Utilities.internetConnectivity)?.internetAvailable == false {
            flightLogReporter.update(isUploading: false).notifyUpdated()
            ULog.d(.myparrot, "processNextFlightLog nothing to do")
            return
        }

        if uploader != nil, let baseUrl = URL(string: GroundSdkConfig.sharedInstance.flightLogServer!),
            currentUploadRequest == nil {
            if let flightLog = pendingFlightLogUrls.first {
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
                            ULog.d(.myparrot, "FLIGHTLOG remove (creationDate < userDate)")
                        }
                    } else {
                        ULog.d(.myparrot, "FLIGHTLOG remove (no date)")
                        toRemove = true
                    }
                    if toRemove {
                        deleteFlightLog(at: flightLog, reason: "denied")
                        processNextFlightLog()
                        return
                    }
                }

                if let attrs = try? FileManager.default.attributesOfItem(
                    atPath: flightLog.path) {
                    let fileSize = attrs[.size] as? UInt64
                    ULog.d(.myparrot, "FLIGHTLOG SIZE: \(String(describing: fileSize)) \(flightLog)")
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
            } else {
                flightLogReporter.update(isUploading: false)
                flightLogReporter.notifyUpdated()
            }
        } else {
            ULog.d(.myparrot, "FLIGHTLOG / process Next flight log abort (no uploader)")
            flightLogReporter.notifyUpdated()
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
                ULog.e(.myparrot, "FLIGHTLOG - Anonymization: move flight log failed.")
                return
            }
            queue.async {
                result = Anonymizer.convert(flightLog.path, outFile: outFile.path, profile: profile)
                DispatchQueue.main.async { [weak self] in
                    // move file back
                    do {
                        try fileManager.moveItem(at: processingFlightLog, to: flightLog)
                    } catch {
                        ULog.e(.myparrot, "FLIGHTLOG - Anonymization: move flight log back failed.")
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
        self.flightLogReporter.update(isUploading: true)
        self.currentUploadRequest = uploader?.upload(baseUrl: baseUrl, flightLogUrl: flightLogUrl,
                                token: self.userAccountInfo!.token!) { flightLogUrl, error in
            self.currentUploadRequest = nil
            if let error = error {
                switch error {
                case .badRequest:
                    ULog.d(.myparrot, "FLIGHTLOG .badRequest \(flightLogUrl)")
                    ULog.w(.flightLogEngineTag, "Bad request sent to the server. This should be a dev error.")
                    // delete file and stop uploading to avoid multiple errors
                    self.deleteFlightLog(at: flightLogUrl, reason: "error")
                    self.flightLogReporter.update(isUploading: false).notifyUpdated()
                case .badFlightLog:
                    ULog.d(.myparrot, "FLIGHTLOG .badFlightLog \(flightLogUrl)")
                    self.deleteFlightLog(at: flightLogUrl, reason: "error")
                    self.processNextFlightLog()
                case .serverError,
                     .connectionError:
                    // Stop uploading if the server is not accessible
                    ULog.d(.myparrot, "FLIGHTLOG .serverError or .connectionError \(flightLogUrl)")
                    self.flightLogReporter.update(isUploading: false).notifyUpdated()
                case .canceled:
                    ULog.d(.myparrot, "FLIGHTLOG .canceled \(flightLogUrl)")
                    self.flightLogReporter.update(isUploading: false).notifyUpdated()
                }
            } else {    // success
                ULog.d(.myparrot, "FLIGHTLOG SUCCESS \(flightLogUrl)")
                self.deleteFlightLog(at: flightLogUrl, reason: "sent")
                self.processNextFlightLog()
            }
        }

    self.flightLogReporter.notifyUpdated()
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
        ULog.d(.myparrot, "FLIGHTLOG remove (in upload list) : \(flightLogUrlReal)")
        if self.pendingFlightLogUrls.first == flightLogUrlReal {
            self.pendingFlightLogUrls.remove(at: 0)
        } else {
            ULog.w(.flightLogEngineTag, "Uploaded flightLog is not the first one of the pending")
            // fallback
            if let index: Int = self.pendingFlightLogUrls.firstIndex(where: {$0 == flightLogUrlReal}) {
                self.pendingFlightLogUrls.remove(at: index)
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
