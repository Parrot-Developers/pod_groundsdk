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

/// Flight camera records collector.
/// This class is in charge of all file system related actions linked to the flight camera records.
///
/// Indeed, it is in charge of:
///  - collecting on the iOS device file system a list of flight camera records that are waiting for upload.
///  - cleaning the empty former work directories and the not fully downloaded flight camera records files.
///  - offering an interface to delete a given flight camera record
class FlightCameraRecordCollector {

    /// Queue where all I/O operations will run into
    private let ioQueue = DispatchQueue(label: "com.parrot.gsdk.flightCameraRecordCollector")

    /// Url path of the root directory where records are stored on the user device's local file system.
    private let rootDir: URL

    /// Url path of the current work directory where records downloaded from remote devices get stored.
    /// This directory should not be scanned nor deleted because records might be currently downloading in it.
    private let workDir: URL

    /// Whether collection has been cancelled.
    private var isCancelled: Bool = false

    /// Constructor
    ///
    /// - Parameters:
    ///   - rootDir: url path of the root directory where records are stored
    ///   - workDir: current work directory where records downloaded from remote devices get stored
    init(rootDir: URL, workDir: URL) {
        self.rootDir = rootDir
        self.workDir = workDir
    }

    /// Loads the list of local flightCameraRecords in background.
    ///
    /// - Note:
    ///    - this function will not look into the `workDir` directory.
    ///    - this function will delete all empty folders and not fully downloaded flightCameraRecord that are
    ///      not located in `workDir`.
    ///
    /// - Parameters:
    ///   - completionCallback: callback with the the local flightCameraRecords list
    ///   - flightCameraRecordsUrls: list of the local urls of the records that are ready to upload
    func collectFlightCameraRecords(completionCallback: @escaping (_ flightCameraRecordsUrls: [URL]) -> Void) {
        ioQueue.async {
            do {
                try FileManager.default.createDirectory(
                    at: self.rootDir, withIntermediateDirectories: true, attributes: nil)
            } catch let err {
                ULog.e(.flightCameraRecordEngineTag, "Failed to create folder at \(self.rootDir.path): \(err)")
                return
            }
            FlightLogEngineBase.createDebugDir()

            var toUpload: [URL] = []
            var toDelete: Set<URL> = []

            // For each dir of the flightCameraRecords dir (these are work dirs and former work dirs)
            let dirs = try? FileManager.default.contentsOfDirectory(
                at: self.rootDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            dirs?.forEach { dir in
                // don't look in the work dir for the moment
                if dir != self.workDir {
                    // by default add the directory to the directories to delete. It will be removed from it if we
                    // discover a finalized flightCameraRecord inside
                    toDelete.insert(dir)

                    let recordUrls = try? FileManager.default.contentsOfDirectory(
                        at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    recordUrls?.forEach { recordUrl in
                        guard !self.isCancelled else { return }
                        if recordUrl.isProcessing {
                            FlightLogEngineBase.recover(file: recordUrl)
                            GroundSdkCore.logEvent(
                                message: "EVT:LOGS;event='blur';file='\(recordUrl.lastPathComponent)';result='crash'")
                        } else if recordUrl.isAFinalizedFlightCameraRecord { // if the record is finalized
                            // keep the parent folder
                            toDelete.remove(dir)
                            toUpload.append(recordUrl)
                        } else {
                            toDelete.insert(recordUrl)
                        }
                    }
                }
            }

            // delete all not finalized records and empty directories
            toDelete.forEach {
                self.doDeleteFlightCameraRecord(at: $0)
            }

            DispatchQueue.main.async {
                if !self.isCancelled {
                    completionCallback(toUpload)
                }
            }
        }
    }

    /// Cancels flight camera record collection.
    func cancelCollection() {
        isCancelled = true
    }

    /// Delete a flight camera record in background.
    ///
    /// - Parameter url: url of the flight camera record to delete
    func deleteFlightCameraRecord(at url: URL) {
        ioQueue.async {
            self.doDeleteFlightCameraRecord(at: url)
        }
    }

    /// Delete a flight camera record
    ///
    /// - Note: This function **must** be called from the `ioQueue`.
    /// - Parameter url: url of the flight camera record to delete
    private func doDeleteFlightCameraRecord(at url: URL) {
        ULog.d(.parrotCloudFcrTag, "Delete FCR \(url)")
        do {
            try FileManager.default.removeItem(at: url)
        } catch let err {
            ULog.w(.parrotCloudFcrTag, "Failed to delete \(url.path): \(err)")
        }
    }
}

/// Private extension to URL that adds Flight camera record recognition functions
private extension URL {
    /// Whether the flight camera record located at this url is finalized (i.e. fully downloaded) or not.
    var isAFinalizedFlightCameraRecord: Bool {
        return pathExtension == "jpeg" && !lastPathComponent.contains("-blur")
    }

    /// Whether the flight camera record is processing  (i.e. blurred or generation of json crashed)  or not
    var isProcessing: Bool {
        return pathExtension == "processing"
    }
}
