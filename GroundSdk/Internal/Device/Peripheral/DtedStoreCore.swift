// Copyright (C) 2023 Parrot Drones SAS
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
//

import Foundation

public enum DtedStoreChangeEvent {
    /// A terrain file has been added
    case terrainAdded(_ file: DtedFileCore)
    /// A terrain file has been removed
    case terrainRemoved
    /// All terrain files has been removed
    case allTerrainsRemoved
}

/// Internal DtedStore implementation
public class DtedStoreCore: PeripheralCore, DtedStore {
    public private(set) var fileCount: Int = 0

    /// Listener notified when the dted store content changes
    class Listener: NSObject {
        /// Closure called when the dted store content changes.
        /// - Parameter event: The event that occurred.
        fileprivate let didChange: (_ event: DtedStoreChangeEvent) -> Void

        /// Constructor
        ///
        /// - Parameters:
        ///  - didChange: closure called when the state changes
        ///  - event: The event that occurred
        fileprivate init(didChange: @escaping (_ event: DtedStoreChangeEvent) -> Void) {
            self.didChange = didChange
        }
    }

    /// backend
    unowned let backend: DtedStoreBackend

    /// Listeners
    private var listeners: Set<Listener> = []

    /// not `nil` if the dtedSore content has changed, the event describes how it has changed
    private var storeChangeEvent: DtedStoreChangeEvent?

    /// Constructor
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored
    ///   - backend: Dted store backend
    public init(store: ComponentStoreCore, backend: DtedStoreBackend) {
        self.backend = backend
        super.init(desc: Peripherals.dtedStore, store: store)
    }

    /// Creates a new dted file list.
    ///
    /// This function starts loading the dted store content, and notifies when it has been loaded
    /// and each time the content changes.
    ///
    /// - Parameters:
    ///   - observer: observer which gets notified when the dted list loads or changes
    ///   - files: list dted files, `nil` if the store has been removed
    /// - Returns: a reference on a list of `DtedFile`. Caller must keep this instance referenced
    ///   for the observer to be called.
    public func browse(observer: @escaping (_ files: [DtedFile]?) -> Void) -> Ref<[DtedFile]> {
        return DtedListRefCore(dtedStore: self, observer: observer)
    }

    /// Creates a new dtedFile getter, to get a dted file.
    ///
    /// - Parameters:
    ///   - latitude: the location latitude
    ///   - longitude: the location longitude
    ///   - observer: observer called when the `DtedFile` complete.
    ///   Referenced DTED file is `nil` if the get task was interrupted.
    ///   - file: the file corresponding to the location
    /// - Returns: a reference on a `DtedFile`. Caller must keep this instance referenced
    ///   for the observer to be called. Setting it to `nil` cancels the get.
    public func get(latitude: Double,
                    longitude: Double,
                    observer: @escaping (_ file: DtedFile?) -> Void) -> Ref<DtedFile> {
        return DtedRefCore(dtedStore: self, latitude: latitude, longitude: longitude, observer: observer)
    }

    /// Creates a new dtedFile deleter, to delete a dted file.
    ///
    /// - Parameters:
    ///   - files: dted files to delete.
    ///   - observer: observer called when the `DtedDeleter` changes, indicating progress of the
    ///     delete task. Referenced file deleter is `nil` if the delete task was interrupted.
    ///   - deleter: deleter storing the delete progress info
    /// - Returns: a reference on a `DtedDeleter`. Caller must keep this instance referenced until
    ///   the file's deleted. Setting it to `nil` cancels the delete.
    public func delete(files: [DtedFile], observer: @escaping (_ deleter: DtedDeleter?) -> Void) -> Ref<DtedDeleter> {
        return DtedDeleterRefCore(dtedStore: self, files: files, observer: observer)
    }

    /// Creates a new dtedFile uploader, to delete a dted file.
    ///
    /// - Parameters:
    ///   - files: files URL to upload.
    ///   - observer: observer called when the `DtedUploader` changes, indicating progress of the
    ///     upload task.
    ///   - uploader: uploader progress info
    /// - Returns: a reference on a `DtedUploader`. Caller must keep this instance referenced until
    ///   the file's uploaded. Setting it to `nil` cancels the upload.
    public func uploader(files: [URL],
                         observer: @escaping (DtedUploader?) -> Void) -> Ref<DtedUploader> {
        return DtedUploaderRefCore(dtedStore: self, files: files, observer: observer)
    }

    /// Reset component state. Called when the component is unpublished.
    override func reset() {
        listeners.forEach {
            $0.didChange(.allTerrainsRemoved)
        }
    }

    /// Register a dtedStore listener
    ///
    /// - Parameter didChange: closure to call when the store content changes
    /// - Returns: created listener, to unregister it
    func register(didChange: @escaping (DtedStoreChangeEvent) -> Void) -> Listener {
        let listener = Listener(didChange: didChange)
        if listeners.isEmpty {
            backend.startWatchingContentChanges()
        }
        listeners.insert(listener)
        return listener
    }

    /// Unregister a dtedStore listener
    ///
    /// - Parameter listener: listener to unregister
    func unregister(listener: Listener) {
        listeners.remove(listener)
        if listeners.isEmpty {
            backend.stopWatchingContentChanges()
        }
    }

    /// Notify changes made by previously called setters
    public override func notifyUpdated() {
        // store content changed, notify listeners
        if let storeChangeEvent = self.storeChangeEvent {
            self.storeChangeEvent = nil
            listeners.forEach {
                $0.didChange(storeChangeEvent)
            }
        }
        super.notifyUpdated()
    }
}

/// DtedStore backend.
public protocol DtedStoreBackend: AnyObject {

    /// Start watching dted store content.
    ///
    /// When content watching is started, backend must call `markContentChanged()` when the content of
    /// the dted store changes.
    func startWatchingContentChanges()

    /// Stop watching dted store content.
    func stopWatchingContentChanges()

    /// Browse dted files.
    ///
    /// - Parameters:
    ///   - completion: completion closure called when the request is terminated.
    ///   - files: list of dted files
    /// - Returns: browse request, or `nil` if the request can't be sent
    func browse(completion: @escaping (_ files: [DtedFileCore]) -> Void) -> CancelableCore?

    /// Requests the DTED file from the store at specified location.
    ///
    /// - Parameters:
    ///   - latitude: latitude of location for which file is requested
    ///   - longitude: longitude of location for which file is requested
    ///   - completion: completion closure called when the request is terminated.
    ///   - file: the dted file
    /// - Returns: get request, or `nil` if the request can't be sent
    func get(latitude: Double,
             longitude: Double,
             completion: @escaping (_ files: DtedFileCore?) -> Void) -> CancelableCore?

    /// Uploads dted file.
    ///
    /// - Parameters:
    ///   - files: files URL to upload.
    ///   - progress: upload progress callback
    /// - Returns: resource upload request, or `nil` if the request can't be sent.
    func upload(files: [URL],
                progress: @escaping (DtedUploader?) -> Void) -> CancelableCore?

    /// Delete dted file
    ///
    /// - Parameters:
    ///   - files: files list to delete
    ///   - progress: progress closure called after each deleted files
    /// - Returns: delete request, or `nil` if the request can't be sent
    func delete(files: [DtedFile], progress: @escaping (DtedDeleter) -> Void)
    -> CancelableCore?
}

/// Backend callback methods
extension DtedStoreCore {
    /// Tells that dted store content has change
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func markContentChanged(withEvent event: DtedStoreChangeEvent) -> DtedStoreCore {
        storeChangeEvent = event
        markChanged()
        return self
    }
}

/// Dted uploader core that makes `Core` constructor public.
public class DtedUploaderCore: DtedUploader, CustomDebugStringConvertible {

    /// Constructor.
    ///
    /// - Parameters:
    ///   - totalFileCount: total number of files to upload
    ///   - uploadedFileCount: number of already uploaded files
    ///   - currentFileProgress: current file upload between 0.0 (0%) and 1.0 (100%)
    ///   - totalProgress: total upload progress between 0.0 (0%) and 1.0 (100%)
    ///   - status: upload progress status
    ///   - currentFileUrl: url of the file currenlty being uploaded
    public override init(totalFileCount: Int, uploadedFileCount: Int, currentFileProgress: Float,
                         totalProgress: Float, status: DtedTaskStatus, currentFileUrl: URL? = nil) {
        super.init(totalFileCount: totalFileCount,
                   uploadedFileCount: uploadedFileCount, currentFileProgress: currentFileProgress,
                   totalProgress: totalProgress, status: status, currentFileUrl: currentFileUrl)
    }

    /// Debug description.
    public var debugDescription: String { """
                uploaded: \(uploadedFileCount)/\(totalFileCount) \
                progress: \(currentFileProgress) totalProgress: \(totalProgress) status: \(status) \
                currentFile: \(String(describing: currentFileUrl))
                """
    }
}
