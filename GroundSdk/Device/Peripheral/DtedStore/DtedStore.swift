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

import Foundation

/// Status of the file task.
public enum DtedTaskStatus: Int, CustomStringConvertible {
    /// Task is running.
    case running
    /// Current file has been successfully uploaded (transient status).
    case currentUploadSuccess
    /// Task completed successfully.
    case complete
    /// Task stopped or canceled.
    case aborted

    /// Debug description.
    public var description: String {
        switch self {
        case .running:
            return "running"
        case .currentUploadSuccess:
            return "currentUploadSuccess"
        case .complete:
            return "complete"
        case .aborted:
            return "aborted"
        }
    }
}

public protocol DtedOperation: AnyObject {
}

public protocol DtedOperationRef: DtedOperation, CancelableCore {
    /// Active request
    var request: CancelableCore? { get }
}

public class DtedUploader: DtedOperation {

    /// Total number of files to upload.
    public let totalFileCount: Int

    /// Number of already uploaded files.
    public let uploadedFileCount: Int

    /// Current file upload between 0.0 (0%) and 1.0 (100%).
    public let currentFileProgress: Float

    /// Total upload progress between 0.0 (0%) and 1.0 (100%).
    public let totalProgress: Float

    /// Upload progress status.
    public let status: DtedTaskStatus

    /// Url of the file currenlty being uploaded, or `nil` if not uploading.
    public let currentFileUrl: URL?

    /// Constructor.
    ///
    /// - Parameters:
    ///   - totalFileCount: total number of files to upload
    ///   - uploadedFileCount: number of already uploaded files
    ///   - currentFileProgress: current file upload between 0.0 (0%) and 1.0 (100%)
    ///   - totalProgress: total upload progress between 0.0 (0%) and 1.0 (100%)
    ///   - status: upload progress status
    ///   - currentFileUrl: url of the file currenlty being uploaded
    init(totalFileCount: Int, uploadedFileCount: Int, currentFileProgress: Float,
         totalProgress: Float, status: DtedTaskStatus, currentFileUrl: URL? = nil) {
        self.totalFileCount = totalFileCount
        self.uploadedFileCount = uploadedFileCount
        self.currentFileProgress = currentFileProgress
        self.totalProgress = totalProgress
        self.status = status
        self.currentFileUrl = currentFileUrl
    }
}

public class DtedDeleter: NSObject, DtedOperation {
    /// Total number of file to delete.
    public let totalCount: Int

    /// Number of already deleted files.
    public let currentCount: Int

    /// Delete progress status.
    public let status: DtedTaskStatus

    /// Constructor.
    ///
    /// - Parameters:
    ///   - totalCount: total number of file to delete
    ///   - currentCount: number of already deleted files
    ///   - status: initial status
   public init(totalCount: Int, currentCount: Int, status: DtedTaskStatus) {
        self.totalCount = totalCount
        self.currentCount = currentCount
        self.status = status
    }
}

/// Digital Terrain Elevation Data files store for Drone devices.
/// Provides access to a drone's DTED file store, allowing the application to browse, delete such
/// files from the drone, as well as to upload such files to the drone store.

public protocol DtedStore: Peripheral {
    /// Total number of files in the dted store.
    var fileCount: Int { get }

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
    func browse(observer: @escaping (_ files: [DtedFile]?) -> Void) -> Ref<[DtedFile]>

    /// Requests the DTED file from the store at specified location.
    ///
    /// - Parameters:
    ///   - latitude: latitude of location for which file is requested
    ///   - longitude: longitude of location for which file is requested
    ///   - observer: observer called when the `DtedFile` complete.
    ///   Referenced DTED file is `nil` if the get task was interrupted.
    ///   - file: the file corresponding to the location
    /// - Returns: a reference on a `DtedFile`. Caller must keep this instance referenced
    ///   for the observer to be called. Setting it to `nil` cancels the get.
    func get(latitude: Double, longitude: Double,
                observer: @escaping (_ file: DtedFile?) -> Void) -> Ref<DtedFile>

    /// Creates a new dtedFile deleter, to delete a dted file.
    ///
    /// - Parameters:
    ///   - files: files to delete.
    ///   - observer: observer called when the `DtedDeleter` changes, indicating progress of the
    ///     delete task. Referenced file deleter is `nil` if the delete task was interrupted.
    ///   - deleter: deleter storing the delete progress info
    /// - Returns: a reference on a `DtedDeleter`. Caller must keep this instance referenced until
    ///   the file's deleted. Setting it to `nil` cancels the delete.
    func delete(files: [DtedFile],
                observer: @escaping (_ deleter: DtedDeleter?) -> Void) -> Ref<DtedDeleter>

    /// Creates a new dtedFile getter, to get a dted file.
    ///
    /// - Parameters:
    ///   - file: file URL to upload.
    ///   - observer: observer called when the `DtedUploader` changes, indicating progress of the
    ///     upload task.
    ///   - uploader: uploader progress info
    /// - Returns: a reference on a `DtedUploader`. Caller must keep this instance referenced until
    ///   the file's uploaded. Setting it to `nil` cancels the upload.
    func uploader(files: [URL],
                  observer: @escaping (_ uploader: DtedUploader?) -> Void) -> Ref<DtedUploader>

}

/// Dted description
public class DtedStoreDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = DtedStore
    public let uid = PeripheralUid.dtedStore.rawValue
    public let parent: ComponentDescriptor? = nil
}
