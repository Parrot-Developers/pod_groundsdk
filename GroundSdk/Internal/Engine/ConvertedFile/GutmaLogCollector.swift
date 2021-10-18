//    Copyright (C) 2019 Parrot Drones SAS
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

/// Converted Log (GUTMAs) collector.
/// This object is in charge of all file system related actions linked to the GUTMA files.
///
/// Indeed, it is in charge of:
///  - collecting on the iOS device file system a list of converted gutma logs.
///  - cleaning the empty former work directories and the not fully converted log file.
///  - offering an interface to delete a given gutma log
class GutmaLogCollector {

    /// Queue where all I/O operations will run into
    private let ioQueue = DispatchQueue(label: "GutmaLogCollectorQueue")

    /// Url path of the root directory where converted logs are stored on the user device's local file system.
    private let rootDir: URL

    /// Url path of the current work directory where converted logs from remote devices get stored.
    /// This directory should not be scanned or deleted because files might be currently converting in it.
    private let gutmaLogsLocalWorkDir: URL

    /// Constructor
    ///
    /// - Parameters:
    ///   - rootDir: url path of the root directory where files are stored
    ///   - gutmaLogsLocalWorkDir: current work directory where files converted from remote devices get stored
    init(rootDir: URL, gutmaLogsLocalWorkDir: URL) {
        self.rootDir = rootDir
        self.gutmaLogsLocalWorkDir = gutmaLogsLocalWorkDir
    }

    /// Loads the list of local converted log files in background.
    ///
    /// - Note:
    ///    - this function will not look into the `workDir` directory.
    ///    - this function will delete all empty folders and not fully converted files that are not located in
    ///      `workDir`.
    ///
    /// - Parameters:
    ///   - completionCallback: callback of the local GutmaLog list
    ///   - gutmaLogs: set of the files url that are ready.
    func collectGutmaLogs(completionCallback: @escaping (_ gutmaLogs: Set<URL>) -> Void) {

        ioQueue.async {
            do {
                try FileManager.default.createDirectory(
                    at: self.rootDir, withIntermediateDirectories: true, attributes: nil)
            } catch let err {
                ULog.e(.gutmaLogEngineTag, "Failed to create folder at \(self.rootDir.path): \(err)")
                return
            }

            var readyFiles = Set<URL>()
            var toDelete = Set<URL>()

            // For each dirs of the gutmaLog dir
            let dirs = try? FileManager.default.contentsOfDirectory(
                at: self.rootDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            dirs?.forEach { dir in
                // don't look in the work dir for the moment
                if dir != self.gutmaLogsLocalWorkDir {
                    // by default add the directory to the directories to delete. It will be removed from it if we
                    // discover a finalized gutma log inside
                    toDelete.insert(dir)

                    let gutmaLogDirs = try? FileManager.default.contentsOfDirectory(
                        at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    gutmaLogDirs?.forEach { gutmaUrl in
                        if gutmaUrl.isAFinalizedGutmaLog {  // if the gutma log file is finalized
                            // keep the parent folder
                            toDelete.remove(dir)
                            // remove file if processing
                            readyFiles.insert(gutmaUrl)
                        } else {
                            toDelete.insert(gutmaUrl)
                        }
                    }
                }
            }

            // delete all not finalized files and empty directories
            toDelete.forEach {
                self.doDeleteGutmaLog(at: $0)
            }

            DispatchQueue.main.async {
                completionCallback(readyFiles)
            }
        }
    }

    /// Delete a gutma log in background.
    ///
    /// - Parameter url: url of the file to delete
    func deleteGutmaLog(at url: URL) {
        ioQueue.async {
            self.doDeleteGutmaLog(at: url)
        }
    }

    /// Delete a gutma log file
    ///
    /// - Note: This function **must** be called from the `ioQueue`.
    /// - Parameter url: url of the gutma log to delete
    private func doDeleteGutmaLog(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch let err {
            ULog.e(.gutmaLogEngineTag, "Failed to delete \(url.path): \(err)")
        }
    }
}

/// Private extension to URL that adds GutmaLog recognition functions
private extension URL {
    /// Whether the gutma log located at this url is finalized (i.e. fully gutma) or not.
    var isAFinalizedGutmaLog: Bool {
        return pathExtension == "gutma"
    }
}
