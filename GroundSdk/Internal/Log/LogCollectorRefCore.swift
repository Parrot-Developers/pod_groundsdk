// Copyright (C) 2022 Parrot Drones SAS
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
import SdkCore

/// LogCollector Reference implementation.
class LogCollectorRefCore: Ref<LogCollector> {

    /// Queue where all I/O operations will run into.
    private let ioQueue = DispatchQueue(label: "com.parrot.gsdk.logCollector", qos: .background)

    /// Destination directory URL.
    private let destinationDirectory: URL

    /// Temporary directory URL.
    private var temporaryDirectory: URL?

    /// References on active log downloaders.
    private var downloaders: [Ref<LatestLogDownloader>] = []

    /// Collector states, by their associated source.
    private var states: [LogCollectorSource: LogCollectorState] = [:]

    /// Constructor
    ///
    /// - Parameters:
    ///   - sources: sources of the logs to collect
    ///   - directory: destination directory
    ///   - observer: observer notified of download progress
    init(from sources: Set<LogCollectorSource>,
         toDirectory directory: URL,
         observer: @escaping Observer) {
        destinationDirectory = directory
        super.init(observer: observer)

        // create temporary directories
        let droneDir, remoteDir, appDir: URL
        do {
            let fileManager = FileManager.default
            let tmpDir = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask,
                                             appropriateFor: directory, create: true)
            droneDir = tmpDir.appendingPathComponent("drone")
            remoteDir = tmpDir.appendingPathComponent("mpp")
            appDir = tmpDir.appendingPathComponent("app")
            try fileManager.createDirectory(at: droneDir, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: remoteDir, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
            temporaryDirectory = tmpDir
        } catch let err {
            ULog.e(.logCollectorTag, "Failed to create temporary directories: \(err)")
            update(newValue: LogCollector(globalStatus: .failed, states: states, destination: nil))
            return
        }

        // start logs collection
        for source in sources {
            switch source {
            case .drone(let drone):
                let downloader = drone.getPeripheral(Peripherals.latestLogDownloader) { [weak self] downloader in
                    self?.states[source] = downloader?.state
                    self?.updateValue()
                }
                downloaders.append(downloader)
                downloader.value?.downloadLogs(toDirectory: droneDir)
            case .remoteControl(let rc):
                let downloader = rc.getPeripheral(Peripherals.latestLogDownloader) { [weak self] downloader in
                    self?.states[source] = downloader?.state
                    self?.updateValue()
                }
                downloaders.append(downloader)
                downloader.value?.downloadLogs(toDirectory: remoteDir)
            case .application(let logDirectory):
                let srcUrl = logDirectory.appendingPathComponent("log.bin")
                let dstUrl = appDir.appendingPathComponent("log.bin")
                var fileSize: UInt64?
                states[source] = LogCollectorState(status: .collecting)
                if let attrs = try? FileManager.default.attributesOfItem(atPath: srcUrl.path) {
                    fileSize = attrs[.size] as? UInt64
                    states[source]?.totalSize = fileSize
                }
                updateValue()

                ioQueue.async {
                    do {
                        try FileManager.default.copyItem(at: srcUrl, to: dstUrl)
                        self.states[source]?.status = .collected
                        self.states[source]?.collectedSize = fileSize
                    } catch let err {
                        ULog.e(.logCollectorTag, "Failed to copy file at \(srcUrl) to \(dstUrl): \(err)")
                        self.states[source]?.status = .failed
                    }
                    DispatchQueue.main.async {
                        self.updateValue()
                    }
                }
            }
        }
    }

    /// Destructor
    deinit {
        for downloader in downloaders {
            downloader.value?.cancelDownload()
        }
    }

    /// Updates the referenced LogCollector according to the states of all log collectors.
    /// When logs collection has completed successfully for all sources, the archive is created.
    private func updateValue() {
        if value?.globalStatus == .collecting && states.values.allSatisfy({ $0.status == .collected }) {
            update(newValue: LogCollector(globalStatus: .archiving, states: states, destination: nil))
            ioQueue.async {
                let archiveUrl = self.createZipArchive()
                DispatchQueue.main.async {
                    self.update(newValue: LogCollector(globalStatus: archiveUrl == nil ? .failed : .done,
                                                       states: self.states,
                                                       destination: archiveUrl))
                }
            }
        } else {
            let collecting = states.values.contains(where: { $0.status == .collecting })
            let failed = states.values.contains(where: { $0.status == .failed })
            if collecting || failed {
                update(newValue: LogCollector(globalStatus: failed ? .failed : .collecting,
                                              states: states,
                                              destination: nil))
            }
        }
    }

    /// Creates an archive file from the content of the temporary directory.
    ///
    /// - Returns: created archive file URL, or `nil` if an error occured
    private func createZipArchive() -> URL? {
        guard let tmpDir = temporaryDirectory else {
            return nil
        }

        // first remove any existing archive
        let fileManager = FileManager.default
        let dstUrl = destinationDirectory.appendingPathComponent("logs.zip")
        do {
            if fileManager.fileExists(atPath: dstUrl.path) {
                try fileManager.removeItem(at: dstUrl)
            }
        } catch let err {
            ULog.e(.logCollectorTag, "Failed to remove archive file \(dstUrl): \(err)")
        }

        // zip directory content
        var archiveUrl: URL?
        var error: NSError?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: tmpDir, options: [.forUploading], error: &error) { (zipUrl) in
            // move archive file to a destination directory
            do {
                try fileManager.moveItem(at: zipUrl, to: dstUrl)
                archiveUrl = dstUrl
            } catch let err {
                ULog.e(.logCollectorTag, "Failed to create archive file from \(tmpDir): \(err)")
            }
        }

        // remove temporary directory which is no longer needed
        do {
            try fileManager.removeItem(at: tmpDir)
        } catch let err {
            ULog.e(.logCollectorTag, "Failed to remove temporary directory \(tmpDir): \(err)")
        }

        return archiveUrl
    }
}
