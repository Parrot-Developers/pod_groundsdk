//    Copyright (C) 2021 Parrot Drones SAS
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

/// Base class for flight log engines.
class FlightLogEngineBase: EngineBaseCore {
    /// List of flightLogs waiting for upload.
    ///
    /// This list is used as a queue (with FIFO semantics): new flightLogs are added at the end,
    /// flightLog to upload is the first one.
    /// The flightLog to upload is removed from this list after it is fully and correctly uploaded.
    ///
    /// - Note: visibility is internal for testing purposes only.
    var pendingFlightLogUrls: [URL] = []

    /// Url path of the root directory where flightLogs are stored on the user device's local file system.
    ///
    /// This directory is located in the cache folder of the device.
    ///
    /// This directory may contain:
    /// - the current work directory (see `workDir`), which may itself contain temporary flightLogs
    ///   (being currently downloaded from remote devices) and finalized flightLogs (that are ready to be uploaded)
    /// - previous work directories, that may themselves contain finalized flightLogs, or temporary flightLogs that
    ///   failed to be downloaded completely.
    ///
    /// When the engine starts, all finalized flightLogs from all work directories are listed and queued for upload;
    /// temporary flightLogs in previous work directories (other than the work directory) are deleted.
    /// Temporary flightLogs in the work directory are left untouched.
    let engineDir: URL

    /// Url path of the current work directory where flightLogs downloaded from remote devices get stored.
    /// This directory is located in `engineDir`.
    let workDir: URL

    /// Current upload request.
    /// Kept to allow cancellation.
    public var currentUploadRequest: CancelableCore?

    /// Flight logs collector.
    public var collector: FlightLogCollector?

    /// Constructor
    ///
    /// - Parameters:
    ///     - enginesController: engines controller
    ///     - engineDirName: engines directory name
    public init(enginesController: EnginesControllerCore, engineDirName: String) {
        let cacheDirUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        engineDir = cacheDirUrl.appendingPathComponent(engineDirName, isDirectory: true)
        workDir = engineDir.appendingPathComponent(UUID().uuidString, isDirectory: true)
        super.init(enginesController: enginesController)
    }

    /// Required Constructor
    ///
    /// - Parameters:
    ///     - enginesController: engines controller
    /// - Note: This will create a default directory.
    public required init(enginesController: EnginesControllerCore) {
        let cacheDirUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        engineDir = cacheDirUrl.appendingPathComponent("default", isDirectory: true)
        workDir = engineDir.appendingPathComponent(UUID().uuidString, isDirectory: true)
        super.init(enginesController: enginesController)
    }

    public override func startEngine() {
        collector = createCollector()
        collector?.collectFlightLogs { [weak self] flightLogs in
            if let `self` = self, self.started {
                self.pendingFlightLogUrls.append(contentsOf: flightLogs)
                self.queueForProcessing()
            }
        }
    }

    public override func stopEngine() {
        cancelCurrentUpload()
        collector?.cancelCollection()
        collector = nil
        pendingFlightLogUrls = []
    }

    /// Cancel the current upload if there is one.
    public func cancelCurrentUpload() {
        // stop current upload request
        ULog.d(.myparrot, "FLIGHTLOG cancel current upload request \(String(describing: self.currentUploadRequest))")
        self.currentUploadRequest?.cancel()
        self.currentUploadRequest = nil
    }

    /// Creates a collector
    ///
    /// - Returns: a new collector
    /// - Note: Visibility is internal only for testing purposes.
    func createCollector() -> FlightLogCollector {
        return FlightLogCollector(rootDir: engineDir, flightLogsLocalWorkDir: workDir)
    }

    /// Adds a flightLog to the flightLogs to be uploaded.
    ///
    /// If the upload was not started and the upload may start, it will start.
    /// - Parameter flightLogUrl: local url of the flightLog that have just been added
    func add(flightLogUrl: URL) {
        ULog.d(.myparrot, "FLIGHTLOG add a file: \(flightLogUrl)")
        pendingFlightLogUrls.append(flightLogUrl)
        queueForProcessing()
    }

    /// Queue for processing flight logs
    /// This method needs to be overriden
    func queueForProcessing() {}

    /// Url path of the directory dedicated to debug purpose.
    private static let debugDir: URL =
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        .appendingPathComponent("debug", isDirectory: true)

    /// Tells whether build is debug or inhouse.
    static private func isDebugOrInhouse() -> Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.bundleIdentifier?.contains(".inhouse") == true
        #endif
    }

    /// Creates the debug directory (debug or inhouse build only).
    static public func createDebugDir() {
        guard isDebugOrInhouse() else { return }

        do {
            try FileManager.default.createDirectory(at: debugDir, withIntermediateDirectories: true)
        } catch let err {
            ULog.e(.myparrot, "Failed to create folder at \(debugDir.path): \(err)")
        }
    }

    /// Recovers a file after a crash has been detected.
    ///
    /// - Parameter file: file to recover or discard
    /// - Note: for debug or inhouse build, file is moved to a dedicated directory for debug purpose, else file is
    ///         discarded.
    static public func recover(file: URL) {
        do {
            if isDebugOrInhouse() {
                let debugFile: URL = debugDir.appendingPathComponent(file.lastPathComponent, isDirectory: false)
                try FileManager.default.moveItem(at: file, to: debugFile)
            } else {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            ULog.e(.myparrot, "Failed to recover file: \(file)")
        }
    }
}
