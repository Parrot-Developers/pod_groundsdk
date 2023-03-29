//    Copyright (C) 2020 Parrot Drones SAS
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

/// Engine managing the application/sdk event logger.
class EventLogEngine: EngineBaseCore {
    /// Event logger facility for which this engine is the backend
    private var eventLoggerFacility: EventLoggerCore!

    /// Name of the directory in which the event logs should be stored
    private let eventLogLocalDirName = "eventLog"

    /// Internal logger
    private var logRecorder: EventLogRecorder?

    /// Flight log storage utility
    private var flightLogStorage: FlightLogStorageCore!

    /// Folder monitor
    private var folderMonitor: FolderMonitor!

    /// Monitor of the userAccount changes
    private var userAccountMonitor: MonitorCore!

    /// Index of the current event log
    private var index: Int = 0

    /// Current session id
    private var sessionId: String?

    /// Start date of the current event log
    private var currentLogDate: Date?

    /// Start date of the next event log
    private var nextLogDate: Date?

    /// Background timestamp
    private var backgroundTimeStamp: Double?

    /// Constructor.
    ///
    /// - Parameter enginesController: engines controller
    public required init(enginesController: EnginesControllerCore) {
        ULog.d(.eventLogEngineTag, "Loading EventLogEngine.")

        super.init(enginesController: enginesController)

        eventLoggerFacility = EventLoggerCore(store: enginesController.facilityStore, backend: self)
        publishUtility(EventLogUtilityCoreImpl(engine: self))
    }

    override func startEngine() {
        ULog.d(.eventLogEngineTag, "Starting EventLogEngine.")

        sessionId = UUID().uuidString
        let roProperties: Dictionary = [
            "app.sessionid": sessionId ?? "0",
            "phone.os": UIDevice.current.systemName,
            "phone.os_version": UIDevice.current.systemVersion,
            "phone.manufacturer": "Apple",
            "phone.model": UIDevice.identifier,
            "ro.parrot.build.product": AppInfoCore.appBundle,
            "ro.parrot.build.version": AppInfoCore.appVersion,
            "ro.parrot.gsdk.product": AppInfoCore.sdkBundle,
            "ro.parrot.gsdk.version": AppInfoCore.sdkVersion
        ]

        let rwProperties: Dictionary = [
            "app.drone.bootid": String(repeating: "0", count: 32)
        ]

        // EventLogEngine is only enabled if FlightLogEngine is enabled
        flightLogStorage = utilities.getUtility(Utilities.flightLogStorage)
        let workDir = flightLogStorage.workDir
        do {
            try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true, attributes: nil)
        } catch let err {
            ULog.e(.eventLogEngineTag, "Failed to create folder at \(workDir.path): \(err)")
        }

        folderMonitor = FolderMonitor(url: workDir, handler: handleNewFile)
        // Monitoring a folder that has just been created may fail, so we add a timer to fix this
        Timer.scheduledTimer(withTimeInterval: 0.001, repeats: false) { _ in
            self.folderMonitor.startMonitoring()
        }

        let userAccount = utilities.getUtility(Utilities.userAccount)!
        userAccountMonitor = userAccount.startMonitoring(accountDidChange: { (userAccountInfo) in
            if userAccountInfo?.privateMode == true {
                ULog.d(.eventLogEngineTag, "Private mode enabled: stopping logger and deleting current event log.")
                self.logRecorder = nil
                self.deleteCurrentEventLog()
            } else if self.logRecorder == nil {
                ULog.d(.eventLogEngineTag, "Private mode disabled: starting logger.")
                let logConfig = LogEventRecorderConfig(workDir)
                self.logRecorder = ULog.redirectToLogEvent(config: logConfig,
                                                           roProperties: roProperties as [String: String],
                                                           rwProperties: rwProperties as [String: String])
                self.index = 0
                self.currentLogDate = Date()
            }
        })

        let notificationCenter = NotificationCenter.default
        if #available(iOS 13.0, *) {
            notificationCenter.addObserver(
                self, selector: #selector(appMovedToBackground),
                name: UIScene.didEnterBackgroundNotification, object: nil)
            notificationCenter.addObserver(
                self, selector: #selector(appMovedToForeground),
                name: UIScene.willEnterForegroundNotification, object: nil)
        } else {
            notificationCenter.addObserver(
                self, selector: #selector(appMovedToBackground),
                name: UIApplication.didEnterBackgroundNotification, object: nil)
            notificationCenter.addObserver(
                self, selector: #selector(appMovedToForeground),
                name: UIApplication.willEnterForegroundNotification, object: nil)
        }
        eventLoggerFacility.publish()
    }

    override func stopEngine() {
        ULog.d(.eventLogEngineTag, "Stopping EventLogEngine.")

        userAccountMonitor?.stop()
        userAccountMonitor = nil
        eventLoggerFacility.unpublish()
        logRecorder = nil
        folderMonitor.stopMonitoring()
        let notificationCenter = NotificationCenter.default
        if #available(iOS 13.0, *) {
            notificationCenter.removeObserver(self, name: UIScene.didEnterBackgroundNotification, object: nil)
            notificationCenter.removeObserver(self, name: UIScene.willEnterForegroundNotification, object: nil)
        } else {
            notificationCenter.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            notificationCenter.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        }
    }

    /// Updates drone boot id in event log file.
    ///
    /// - Parameter bootId: new drone boot id
    func update(bootId: String) {
        logRecorder?.updateProperty(key: "app.drone.bootid", value: bootId)
    }

    /// Closes current event log session and starts a new one, creating a new log file.
    func newSession() {
        ULog.d(.eventLogEngineTag, "New event log session requested.")
        logRecorder?.rotateLogFile()
        nextLogDate = Date()
    }

    /// Handles new file detected in work directory.
    ///
    /// - Parameter file: new file
    private func handleNewFile(file: URL) {
        // Considering only files appearing after log rotation.
        guard file.lastPathComponent.range(of: "log-\\d+.bin", options: .regularExpression) != nil else {
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.system
        dateFormatter.locale = NSLocale.system
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZZZ"

        let currentDateStr = dateFormatter.string(from: currentLogDate ?? Date())
        let fileName = "log-\(index)-\(sessionId?.prefix(5) ?? "")-\(currentDateStr).bin"
        let srcFile = file.resolvingSymlinksInPath()
        let dstFile = srcFile.deletingLastPathComponent().appendingPathComponent(fileName)

        ULog.d(.eventLogEngineTag, "New file detected: \(srcFile) - renaming it to: \(fileName)")

        index += 1 // it follows internal logger index, which is incremented on each log rotation
        currentLogDate = nextLogDate

        do {
            try FileManager.default.moveItem(at: srcFile, to: dstFile)
            flightLogStorage?.notifyFlightLogReady(flightLogUrl: dstFile)
        } catch {
            ULog.e(.eventLogEngineTag, "Failed to rename event log file: \(file.absoluteString)")
            flightLogStorage?.notifyFlightLogReady(flightLogUrl: srcFile)
        }
    }

    /// Deletes current event log file.
    private func deleteCurrentEventLog() {
        let fileManager = FileManager.default
        let url = flightLogStorage.workDir.appendingPathComponent("log.bin")
        do {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        } catch let err {
            ULog.e(.eventLogEngineTag, "Failed to delete \(url.path): \(err)")
        }
    }

    @objc private func appMovedToBackground() {
        backgroundTimeStamp = NSDate().timeIntervalSince1970
    }

    @objc private func appMovedToForeground() {
        if let backgroundTimeStamp = backgroundTimeStamp,
           NSDate().timeIntervalSince1970 - backgroundTimeStamp > 3 {
            newSession()
        }
        backgroundTimeStamp = nil
    }
}

/// Extension of the engine that implements the EventLogger backend
extension EventLogEngine: EventLoggerBackend {
    func log(_ message: String) {
        ULog.d(.eventLogEngineTag, message)
    }
}

/// Utility class monitoring a folder for new files.
private class FolderMonitor {
    /// URL for the directory being monitored
    private let url: URL

    /// Handler called when a new file is detected
    private let onNewFile: ((URL) -> Void)

    /// File descriptor for the monitored directory
    private var fileDescriptor: CInt = -1

    /// Dispatch source monitoring the directory
    private var dispatchSource: DispatchSourceFileSystemObject?

    /// Dispatch queue used for sending file changes in the directory
    private let dispatchQueue = DispatchQueue(label: "com.parrot.gsdk.folderMonitor", attributes: .concurrent)

    /// List of file paths in the monitored folder
    private var folderContent: [URL]?

    /// Constructor.
    ///
    /// - Parameters:
    ///   - url: URL of the directory to monitor
    ///   - handler: handler called when a new file is detected
    init(url: URL, handler: @escaping (URL) -> Void) {
        self.url = url
        self.onNewFile = handler
    }

    /// Starts listening for changes to the directory.
    func startMonitoring() {
        guard fileDescriptor == -1 && dispatchSource == nil else {
            return
        }

        fileDescriptor = open(url.path, O_EVTONLY)
        dispatchSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor,
                                                                   eventMask: .write, queue: dispatchQueue)
        dispatchSource?.setEventHandler { [weak self] in
            if let self = self,
                let files = try? FileManager.default.contentsOfDirectory(
                    at: self.url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                if let newFile = files.first(where: { !(self.folderContent?.contains($0) ?? false) }) {
                    self.onNewFile(newFile)
                }
                self.folderContent = files
            }
        }

        dispatchSource?.setCancelHandler { [weak self] in
            guard let strongSelf = self else { return }
            close(strongSelf.fileDescriptor)
            strongSelf.fileDescriptor = -1
            strongSelf.dispatchSource = nil
        }

        dispatchSource?.resume()
    }

    /// Stops listening for changes to the directory, if the source has been created.
    func stopMonitoring() {
        dispatchSource?.cancel()
    }
}
