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

/// LatestLogDownloader backend part.
public protocol LatestLogDownloaderBackend: AnyObject {

    /// Downloads the device logs for the current boot id.
    func downloadLogs(toDirectory directory: URL)

    /// Cancels an ongoing log download.
    func cancelDownload()
}

/// Internal implementation of the LatestLogDownloader.
public class LatestLogDownloaderCore: PeripheralCore, LatestLogDownloader {

    /// Implementation backend.
    private unowned let backend: LatestLogDownloaderBackend

    public private(set) var state: LogCollectorState

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: LatestLogDownloader backend
    public init(store: ComponentStoreCore, backend: LatestLogDownloaderBackend) {
        state = LogCollectorState()
        self.backend = backend
        super.init(desc: Peripherals.latestLogDownloader, store: store)
    }

    public func downloadLogs(toDirectory directory: URL) {
        backend.downloadLogs(toDirectory: directory)
    }

    public func cancelDownload() {
        backend.cancelDownload()
    }
}

/// Backend callback methods
extension LatestLogDownloaderCore {

    /// Updates download status.
    ///
    /// - Parameter status: new status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(status: LogCollectorStatus) -> LatestLogDownloaderCore {
        if state.status != status {
            state.status = status
            markChanged()
        }
        return self
    }

    /// Updates total size.
    ///
    /// - Parameter totalSize: new total size
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(totalSize: UInt64?) -> LatestLogDownloaderCore {
        if state.totalSize != totalSize {
            state.totalSize = totalSize
            markChanged()
        }
        return self
    }

    /// Updates collected size.
    ///
    /// - Parameter collectedSize: new collected size
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(collectedSize: UInt64?) -> LatestLogDownloaderCore {
        if state.collectedSize != collectedSize {
            state.collectedSize = collectedSize
            markChanged()
        }
        return self
    }
}
