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
import UIKit

/// Indexing state of the media store.
@objc(GSMediaStoreIndexingState)
public enum MediaStoreIndexingState: Int, CustomStringConvertible {
    /// The media store is not available.
    case unavailable
    /// The media store is indexing.
    case indexing
    /// The media store is indexed and ready to be used.
    case indexed

    /// Debug description.
    public var description: String {
        switch self {
        case .unavailable:  return "unavailable"
        case .indexing:     return "indexing"
        case .indexed:      return "indexed"
        }
    }
}

/// Status of the media task.
@objc(GSMediaTaskStatus)
public enum MediaTaskStatus: Int, CustomStringConvertible {
    /// Task is running.
    case running
    /// Task completed successfully.
    case complete
    /// Task stopped or canceled.
    case error
    /// Task has finished downloading successfully a file from a media.
    case fileDownloaded

    /// Debug description.
    public var description: String {
        switch self {
        case .running:
            return "running"
        case .complete:
            return "complete"
        case .fileDownloaded:
            return "fileDownloaded"
        case .error:
            return "error"
        }
    }
}

public protocol MediaOperation: AnyObject {
}

public protocol MediaOperationRef: MediaOperation, CancelableCore {
    /// Active request
    var request: CancelableCore? { get }
}

/// Media deleter, containing info on a delete medias task.
///
/// - Seealso: `MediaStore.newDeleter(medias:observer:)`
@objcMembers
@objc(GSMediaDeleter)
public class MediaDeleter: NSObject, MediaOperation {
    /// Total number of media to delete.
    public let totalCount: Int

    /// Number of already deleted media.
    public let currentCount: Int

    /// Delete progress status.
    public let status: MediaTaskStatus

    /// Constructor.
    ///
    /// - Parameters:
    ///   - totalCount: total number of media to delete
    ///   - currentCount: number of already deleted media
    ///   - status: initial status
    init(totalCount: Int, currentCount: Int, status: MediaTaskStatus) {
        self.totalCount = totalCount
        self.currentCount = currentCount
        self.status = status
    }
}

/// All media deleter, containing info on a delete all medias task.
///
/// - Seealso: `MediaStore.newAllMediaDeleter(observer:)`
@objcMembers
@objc(GSAllMediaDeleter)
public class AllMediasDeleter: NSObject, MediaOperation {
    /// Delete progress status.
    public let status: MediaTaskStatus

    /// Constructor.
    ///
    /// - Parameters:
    ///   - status: initial status
    init(status: MediaTaskStatus) {
        self.status = status
    }
}

/// A list of media resources to download.
///
/// - Seealso: `MediaResourceListFactory` to create `MediaResourceList`.
@objc(GSMediaResourceList)
public protocol MediaResourceList {

    /// Adds a media resource to the list.
    ///
    /// - Parameters:
    ///   - media: media to add a resource of
    ///   - resource: resource to add
    func add(media: MediaItem, resource: MediaItem.Resource)

    /// Adds all resources of a media to the list
    ///
    /// - Parameters:
    ///   - media: media to add all resources of
    func add(media: MediaItem)
}

/// Factory class to create `MediaResourceList`.
@objcMembers
@objc(GSMediaResourceListFactory)
public class MediaResourceListFactory: NSObject {

    /// Creates a list of media resources containing all resources of the given media list.
    ///
    /// - Parameter mediaList: list of media to include
    /// - Returns: a new MediaResourceList
    public static func listWith(allOf mediaList: [MediaItem]) -> MediaResourceList {
        return MediaResourceListCore(allOf: mediaList)
    }

    /// Creates a list of media resources containing all resources of the given media list but excluding `DNG`.
    ///
    /// - Parameter mediaList: list of media to include
    /// - Returns: a new MediaResourceList
    public static func listWith(allButDngOf mediaList: [MediaItem]) -> MediaResourceList {
        return MediaResourceListCore(allButDngOf: mediaList)
    }

    /// Factory function to create an empty list.
    ///
    /// - Returns: a new MediaResourceList
    public static func emptyList() -> MediaResourceList {
        return MediaResourceListCore()
    }
}

/// Media download type.
public enum DownloadType {
    /// Download original media (with metadata) and digital signature if available.
    case full
    /// Download preview image only (without metadata), if available.
    case preview
}

/// Download destination.
public enum DownloadDestination {
    /// A directory inside the application's `Documents` directory. Root of `Documents` if `directoryName` is `nil`.
    case document(directoryName: String?)
    /// Temporary directory.
    case tmp
    /// Platform gallery (photos app), in an optional album named `albumName`. Album will be created if it doesn't
    /// exists.
    ///
    /// Using this enum will request authorization to access to the PHPhotoLibrary. This request will prompt a Dialog
    /// to the user. If the user refuses access once, this Dialog won't be displayed anymore, the only way to change
    /// authorization anymore will be to go to the phone settings.
    /// If authorization is not given, medias won't be added to the gallery at all.
    case mediaGallery(albumName: String?)
    /// Directory where to download the resources.
    case directory(path: String)
}

/// Storage type
@objc(GSStorageType)
public enum StorageType: Int, CustomStringConvertible {
    /// The removable storage.
    case removable
    /// The internal storage.
    case `internal`

    /// Debug description.
    public var description: String {
        switch self {
        case .removable:
            return "removable"
        case .internal:
            return "internal"
        }
    }
}

/// Media downloader, containing info on a download medias task.
///
/// - Seealso: `MediaStore.newDownloader`
@objcMembers
@objc(GSMediaDownloader)
public class MediaDownloader: NSObject, MediaOperation {
    /// Total number of media to download.
    public let totalMediaCount: Int

    /// Number of already downloaded media.
    public let currentMediaCount: Int

    /// Total number of resources to download.
    public let totalResourceCount: Int

    /// Number of already downloaded resources.
    public let currentResourceCount: Int

    /// Current file download between 0.0 (0%) and 1.0 (100%).
    public let currentFileProgress: Float

    /// Total download progress between 0.0 (0%) and 1.0 (100%).
    public let totalProgress: Float

    /// Download progress status.
    public let status: MediaTaskStatus

    /// Url of downloaded file (if exists) when status is fileDownloaded, nil in other cases.
    public let fileUrl: URL?

    /// Url of downloaded file signature (if exists) when status is fileDownloaded, nil in other cases.
    public let signatureUrl: URL?

    /// Current downloading media.
    public let currentMedia: MediaItem?

    /// Constructor.
    ///
    /// - Parameters:
    ///   - totalMedia: total number of media to download
    ///   - countMedia: number of already downloaded media
    ///   - totalResources: total number of resources to download
    ///   - countResources: number of already downloaded resources
    ///   - currentFileProgress: current file download between 0.0 (0%) and 1.0 (100%)
    ///   - progress: total download progress between 0.0 (0%) and 1.0 (100%)
    ///   - status: download progress status
    ///   - fileUrl : url of downloaded file when progress is at 1.0, nil in other cases
    ///   - signatureUrl : url of downloaded file signature, if exists, when progress is at 1.0, nil in other cases
    init(totalMedia: Int, countMedia: Int, totalResources: Int, countResources: Int,
         currentFileProgress: Float, progress: Float, status: MediaTaskStatus,
         currentMedia: MediaItem? = nil, fileUrl: URL? = nil, signatureUrl: URL? = nil) {
        self.totalMediaCount = totalMedia
        self.currentMediaCount = countMedia
        self.totalResourceCount = totalResources
        self.currentResourceCount = countResources
        self.currentFileProgress = currentFileProgress
        self.totalProgress = progress
        self.status = status
        self.fileUrl = fileUrl
        self.signatureUrl = signatureUrl
        self.currentMedia = currentMedia
    }
}

/// Resource uploader, containing info on a resource upload task.
///
/// - Seealso: `MediaStore.newUploader`
public class ResourceUploader: MediaOperation {
    /// Media item with which uploaded resource files will be associated.
    public let targetMedia: MediaItem

    /// Total number of resources to upload.
    public let totalResourceCount: Int

    /// Number of already uploaded resources.
    public let uploadedResourceCount: Int

    /// Current file upload between 0.0 (0%) and 1.0 (100%).
    public let currentFileProgress: Float

    /// Total upload progress between 0.0 (0%) and 1.0 (100%).
    public let totalProgress: Float

    /// Upload progress status.
    public let status: MediaTaskStatus

    /// Url of the file currenlty being uploaded, or `nil` if not uploading.
    public let currentFileUrl: URL?

    /// Constructor.
    ///
    /// - Parameters:
    ///   - targetMedia: target media item to attach uploaded resource files to
    ///   - totalResourceCount: total number of resources to upload
    ///   - uploadedResourceCount: number of already uploaded resources
    ///   - currentFileProgress: current file upload between 0.0 (0%) and 1.0 (100%)
    ///   - totalProgress: total upload progress between 0.0 (0%) and 1.0 (100%)
    ///   - status: upload progress status
    ///   - currentFileUrl: url of the file currenlty being uploaded
    init(targetMedia: MediaItem, totalResourceCount: Int, uploadedResourceCount: Int, currentFileProgress: Float,
         totalProgress: Float, status: MediaTaskStatus, currentFileUrl: URL? = nil) {
        self.targetMedia = targetMedia
        self.totalResourceCount = totalResourceCount
        self.uploadedResourceCount = uploadedResourceCount
        self.currentFileProgress = currentFileProgress
        self.totalProgress = totalProgress
        self.status = status
        self.currentFileUrl = currentFileUrl
    }
}

/// Aggregated media store.
/// Contains information on all medias stored on a device, aggregating media on different stores.
public protocol MediaStore: Peripheral {

    /// Current indexing state of the media store.
    var indexingState: MediaStoreIndexingState { get }

    /// Total number of photo medias in the media store.
    var photoMediaCount: Int { get }

    /// Total number of video medias in the media store.
    var videoMediaCount: Int { get }

    /// Total number of photo resources in the media store.
    var photoResourceCount: Int { get }

    /// Total number of video resources in the media store.
    var videoResourceCount: Int { get }

    /// Creates a new Media list.
    ///
    /// This function starts loading the media store content, and notifies when it has been loaded
    /// and each time the content changes.
    ///
    /// - Parameters:
    ///   - observer: observer which gets notified when the media list loads or changes
    ///   - medias: list media, `nil` if the store has been removed
    /// - Returns: a reference on a list of `MediaItem`. Caller must keep this instance referenced
    ///   for the observer to be called.
    func newList(observer: @escaping (_ medias: [MediaItem]?) -> Void) -> Ref<[MediaItem]>

    /// Creates a new Media list for a specific storage.
    ///
    /// This function starts loading the media store content on a specific storage, and notifies
    /// when it has been loaded and each time the content changes.
    ///
    /// - Parameters:
    ///   - storage: storage type on which the Media list will be created
    ///   - observer: observer which gets notified when the media list loads or changes
    ///   - medias: list media, `nil` if the store has been removed
    /// - Returns: a reference on a list of `MediaItem`. Caller must keep this instance referenced
    ///   for the observer to be called.
    /// - Note: if storage is `nil`, `MediaItem`s in any storage are returned in the list.
    func newList(storage: StorageType?,
                 observer: @escaping (_ medias: [MediaItem]?) -> Void) -> Ref<[MediaItem]>

    /// Creates a new media thumbnail downloader.
    ///
    /// - Parameters:
    ///   - media: media item to download the thumbnail from
    ///   - observer: observer called when the thumbnail has been downloaded. Observer is called
    ///     immediately if the thumbnail is already cached
    ///   - thumbnail: loaded or cached thumbnail, `nil` if the thumbnail can't be downloaded
    /// - Returns: A reference of the media downloader. Caller must keep this instance referenced
    ///   for the observer to be called.
    /// - Note: Typical usage in a `UITableView` is to call `newMediaThumbnailDownloader()` in
    ///   `UITableViewDataSource.(tableView:cellForRowAt:)` and store the returned `Ref<UIImage>`
    ///   inside the `UITableViewCell`. Then in the `UITableViewCell.prepareForReuse()` function
    ///   set the stored `Ref<UIImage>` to `nil` to cancel the download request.
    func newThumbnailDownloader(media: MediaItem,
                                observer: @escaping (_ thumbnail: UIImage?) -> Void) -> Ref<UIImage>

    /// Create a new resource thumbnail downloader.
    ///
    /// - Parameters:
    ///   - resource: resource item to download the thumbnail from
    ///   - observer: observer called when the thumbnail has been downloaded. Observer is called immediately if the
    ///     thumbnail is already cached
    ///   - thumbnail: loaded or cached thumbnail, `nil` if the thumbnail can't be downloaded
    /// - Returns: A reference of the resource downloader. Caller must keep this instance referenced
    ///   for the observer to be called.
    /// - Note: Typical usage in a `UITableView` is to call `newMediaThumbnailDownloader()` in
    ///   `UITableViewDataSource.(tableView:cellForRowAt:)` and store the returned `Ref<UIImage>`
    ///   inside the `UITableViewCell`. Then in the `UITableViewCell.prepareForReuse()` function
    ///   set the stored `Ref<UIImage>` to `nil` to cancel the download request.
    func newThumbnailDownloader(resource: MediaItem.Resource,
                                observer: @escaping (_ thumbnail: UIImage?) -> Void) -> Ref<UIImage>

    /// Creates a new media resource downloader.
    ///
    /// - Parameters:
    ///   - mediaResources: list of media resources to download
    ///   - type: download type
    ///   - destination: download destination
    ///   - observer: observer called when the `MediaDownloader` changes, indicating download
    ///     progress
    /// - Returns: a reference on a `MediaDownloader`. Caller must keep this instance referenced
    ///   until all media are downloaded. Setting it to `nil` cancels the download.
    /// - Note: If `full` type is selected (default), signatures will also be downloaded. If `preview` type is
    ///   selected, no signature will be downloaded and videos will be ignored.
    func newDownloader(mediaResources: MediaResourceList, type: DownloadType, destination: DownloadDestination,
                       observer: @escaping (_ downloader: MediaDownloader?) -> Void) -> Ref<MediaDownloader>

    /// Creates a new media resource uploader.
    ///
    /// Resource files will be uploaded to the device's internal storage, in the order defined by the specified
    /// `resources` array.
    ///
    /// - Parameters:
    ///   - resources: resource files to upload
    ///   - target: target media item to attach uploaded resource files to
    ///   - observer: observer called when the `ResourceUploader` changes, indicating upload
    ///      progress and status
    /// - Returns: a reference on a `ResourceUploader`. Caller must keep this instance referenced
    ///   for the observer to be called. Setting it to `nil` cancels the upload.
    func newUploader(resources: [URL], target: MediaItem,
                     observer: @escaping (_ uploader: ResourceUploader?) -> Void) -> Ref<ResourceUploader>

    /// Creates a new Media deleter, to delete a list of media.
    ///
    /// - Parameters:
    ///   - medias: medias to delete.
    ///   - observer: observer called when the `MediaDeleter` changes, indicating progress of the
    ///     delete task. Referenced media deleter is `nil` if the delete task was interrupted.
    ///   - deleter: deleter storing the delete progress info
    /// - Returns: a reference on a `MediaDeleter`. Caller must keep this instance referenced until
    ///   all media are deleted. Setting it to `nil` cancels the delete.
    func newDeleter(medias: [MediaItem],
                    observer: @escaping (_ deleter: MediaDeleter?) -> Void) -> Ref<MediaDeleter>

    /// Creates a new Media deleter, to delete a list of media resources.
    ///
    /// - Parameters:
    ///   - mediaResources: list of media resources to delete
    ///   - observer: observer called with `MediaDeleter` changes, indicating progress of the delete
    ///     task. Referenced media deleter is `nil` if the delete task was interrupted.
    ///   - deleter: deleter storing the delete progress info
    /// - Returns: a reference on a `MediaDeleter`. Caller must keep this instance referenced until
    ///   all media are deleted. Setting it to `nil` cancels the delete.
    func newDeleter(mediaResources: MediaResourceList,
                    observer: @escaping (_ deleter: MediaDeleter?) -> Void) -> Ref<MediaDeleter>

    /// Creates a new media deleter to delete all medias.
    ///
    /// - Parameters:
    ///   - observer: observer called when `AllMediasDeleter` changes, indicating progress of the
    ///     delete task. Referenced media deleter is `nil` if the delete task was interrupted.
    ///   - deleter: deleter storing the delete progress info
    /// - Returns: a reference on a `AllMediaDeleter`. Caller must keep this instance referenced
    ///   until all media are deleted. Setting it to `nil` cancels the delete.
    func newAllMediasDeleter(observer: @escaping (_ deleter: AllMediasDeleter?) -> Void) -> Ref<AllMediasDeleter>
}

/// Extension providing default parameter values to functions to ensure backward compatibility.
public extension MediaStore {

    /// Creates a new media resource downloader.
    ///
    /// - Parameters:
    ///   - mediaResources: list of media resources to download
    ///   - type: download type
    ///   - destination: download destination
    ///   - observer: observer called when the `MediaDownloader` changes, indicating download
    ///     progress
    /// - Returns: a reference on a `MediaDownloader`. Caller must keep this instance referenced
    ///   until all media are downloaded. Setting it to `nil` cancels the download.
    func newDownloader(mediaResources: MediaResourceList, type: DownloadType = .full,
                       destination: DownloadDestination,
                       observer: @escaping (_ downloader: MediaDownloader?) -> Void) -> Ref<MediaDownloader> {
        return newDownloader(mediaResources: mediaResources, type: type, destination: destination,
                             observer: observer)
    }
}

/// Objective-C wrapper of Ref<[MediaItem]>. Required because swift generics can't be used from Objective-C.
/// - Note: This class is for Objective-C only and must not be used in Swift.
@objcMembers
public class GSMediaListRef: NSObject {
    /// Wrapper reference.
    private let ref: Ref<[MediaItem]>

    /// Referenced media list.
    public var value: [MediaItem]? {
        return ref.value
    }

    /// Constructor.
    ///
    /// - Parameter ref: wrapper reference
    init(ref: Ref<[MediaItem]>) {
        self.ref = ref
    }
}

/// Objective-C wrapper of Ref<UIImage>. Required because swift generics can't be used from Objective-C.
/// - Note: This class is for Objective-C only and must not be used in Swift.
@objcMembers
public class GSMediaImageRef: NSObject {
    /// Wrapper reference
    private let ref: Ref<UIImage>

    /// Referenced media deleter.
    public var value: UIImage? {
        return ref.value
    }

    /// Constructor.
    ///
    /// - Parameter ref: wrapper reference
    init(ref: Ref<UIImage>) {
        self.ref = ref
    }
}

/// Objective-C wrapper of DownloadDestination. Required because swift enum with optional value can't be used
/// from Objective-C.
/// - Note: This class is for Objective-C only and must not be used in Swift.
@objcMembers
@objc
public class GSDownloadDestination: NSObject {
    /// Wrapped DownloadDestination.
    let destination: DownloadDestination

    /// Init with an optional directory in document directory.
    ///
    /// - Parameter directoryName: directory name
    public init(documentDirectory directoryName: String?) {
        destination = .document(directoryName: directoryName)
    }

    /// Init with a directory path.
    ///
    /// - Parameter path: destination directory where to download the resources
    public init(directory path: String) {
        destination = .directory(path: path)
    }

    /// Init with an optional album name in media gallery.
    ///
    /// - Parameter albumName: album name
    public init(mediaGalleryAlbum albumName: String?) {
        destination = .mediaGallery(albumName: albumName)
    }

    /// Init with tmp directory.
    public override init() {
        destination = .tmp
    }
}

/// Objective-C wrapper of Ref<MediaDownloader>. Required because swift generics can't be used from Objective-C.
/// - Note: This class is for Objective-C only and must not be used in Swift.
@objcMembers
public class GSMediaDownloaderRef: NSObject, MediaOperation {
    /// Wrapper reference.
    private let ref: Ref<MediaDownloader>

    /// Referenced media deleter.
    public var value: MediaDownloader? {
        return ref.value
    }

    /// Constructor.
    ///
    /// - Parameter ref: wrapper reference
    init(ref: Ref<MediaDownloader>) {
        self.ref = ref
    }
}

/// Objective-C wrapper of Ref<MediaDeleter>. Required because swift generics can't be used from Objective-C.
/// - Note: This class is for Objective-C only and must not be used in Swift.
@objcMembers
public class GSMediaDeleterRef: NSObject, MediaOperation {
    /// Wrapper reference
    private let ref: Ref<MediaDeleter>

    /// Referenced media deleter
    public var value: MediaDeleter? {
        return ref.value
    }

    /// Constructor
    ///
    /// - Parameter ref: wrapper reference
    init(ref: Ref<MediaDeleter>) {
        self.ref = ref
    }
}

/// Objective-C wrapper of Ref<AllMediaDeleter>. Required because swift generics can't be used from Objective-C.
/// - Note: This class is for Objective-C only and must not be used in Swift.
@objcMembers
public class GSAllMediasDeleterRef: NSObject, MediaOperation {
    /// Wrapper reference.
    private let ref: Ref<AllMediasDeleter>

    /// Referenced media deleter.
    public var value: AllMediasDeleter? {
        return ref.value
    }

    /// Constructor.
    ///
    /// - Parameter ref: wrapper reference
    init(ref: Ref<AllMediasDeleter>) {
        self.ref = ref
    }
}

/// Objective-C version of MediaStore.
/// - Note: This class is for Objective-C only and must not be used in Swift.
@objc(GSMediaStore)
public protocol GSMediaStore: Peripheral {
    /// Current indexing state of the media store.
    var indexingState: MediaStoreIndexingState { get }

    /// Total number of photo medias in the media store.
    var photoMediaCount: Int { get }

    /// Total number of video medias in the media store.
    var videoMediaCount: Int { get }

    /// Total number of photo resources in the media store.
    var photoResourceCount: Int { get }

    /// Total number of video resources in the media store.
    var videoResourceCount: Int { get }

    /// Creates a new Media list.
    ///
    /// This function starts loading the media store content, and notifies when it has been loaded
    /// and each time the content changes.
    ///
    /// - Parameters:
    ///   - observer: observer which gets notified when the media list loads or changes
    ///   - medias: list media, `nil` if the store has been removed
    /// - Returns: a reference on a list of `MediaItem`. Caller must keep this instance referenced
    ///   for the observer to be called.
    /// - Note: This function is for Objective-C only.
    @objc(newList:)
    func newListRef(observer: @escaping (_ medias: [MediaItem]?) -> Void) -> GSMediaListRef

    /// Creates a new Media list for a specific storage.
    ///
    /// This function starts loading the media store content on a specific storage, and notifies
    /// when it has been loaded and each time the content changes.
    ///
    /// - Parameters:
    ///   - storage: storage type on which the Media list will be created
    ///   - observer: observer which gets notified when the media list loads or changes
    ///   - medias: list media, `nil` if the store has been removed
    /// - Returns: a reference on a list of `MediaItem`. Caller must keep this instance referenced
    ///   for the observer to be called.
    /// - Note: if storage is `nil`, `MediaItem`s in any storage are returned in the list.
    /// - Note: This function is for Objective-C only.
    @objc(newList:storage:)
    func newListRef(storage: StorageType,
                    observer: @escaping (_ medias: [MediaItem]?) -> Void) -> GSMediaListRef

    /// Creates a new media thumbnail downloader.
    ///
    /// - Parameters:
    ///   - media: media item to download the thumbnail from
    ///   - observer: observer called when the thumbnail has been downloaded. Observer is called
    ///     immediately if the thumbnail is already cached
    ///   - thumbnail: loaded or cached thumbnail, `nil` if the thumbnail can't be downloaded
    /// - Returns: A reference of the media downloader. Caller must keep this instance referenced
    ///   for the observer to be called.
    /// - Note: Typical usage in a `UITableView` is to call `newMediaThumbnailDownloader()` in
    ///   `UITableViewDataSource.(tableView:cellForRowAt:)` and store the returned `Ref<UIImage>`
    ///   inside the `UITableViewCell`. Then in the `UITableViewCell.prepareForReuse()` function
    ///   set the stored `Ref<UIImage>` to `nil` to cancel the download request.
    /// - Note: This function is for Objective-C only.
    @objc(newThumbnailDownloaderForMedia:observer:)
    func newThumbnailDownloaderRef(media: MediaItem, observer: @escaping (_ thumbnail: UIImage?) -> Void)
        -> GSMediaImageRef

    /// Creates a new media resource downloader.
    ///
    /// - Parameters:
    ///   - mediaResources: list of media resources to download
    ///   - destination: download destination
    ///   - observer: observer called when the `MediaDownloader` changes, indicating download
    ///     progress
    /// - Returns: a reference on a `GSMediaDownloaderRef`. Caller must keep this instance referenced
    ///   until all media are downloaded. Setting it to `nil` cancels the download.
    /// - Note: If `full` type is selected (default), signatures will also be downloaded. If `preview` type is
    ///   selected, no signature will be downloaded and videos will be ignored.
    /// - Note: This function is for Objective-C only.
    @objc(newDownloaderForMediaResources:destination:observer:)
    func newDownloaderRef(mediaResources: MediaResourceList, destination: GSDownloadDestination,
                          observer: @escaping (_ downloader: MediaDownloader?) -> Void) -> GSMediaDownloaderRef

    /// Creates a new Media deleter, to delete a list of media.
    ///
    /// - Parameters:
    ///   - medias: list of media to delete
    ///   - observer: observer called with `MediaDeleter` changes, indicating progress of the delete
    ///     task. Referenced media deleter is `nil` if the delete task was interrupted.
    ///   - deleter: deleter storing the delete progress info
    /// - Returns: a reference on a `GSMediaDeleterRef`. Caller must keep this instance referenced
    ///   until all media are deleted. Setting it to `nil` cancels the delete.
    /// - Note: This function is for Objective-C only.
    @objc(newDeleterForMedia:observer:)
    func newDeleterRef(medias: [MediaItem], observer: @escaping (_ deleter: MediaDeleter?) -> Void)
        -> GSMediaDeleterRef

    /// Creates a new media deleter to delete all medias.
    ///
    /// - Parameters:
    ///   - observer: observer called when `AllMediasDeleter` changes, indicating progress of the
    ///     delete task. Referenced media deleter is `nil` if the delete task was interrupted.
    ///   - deleter: deleter storing the delete progress info
    /// - Returns: a reference on a `AllMediaDeleter`. Caller must keep this instance referenced
    ///   until all media are deleted. Setting it to `nil` cancels the delete.
    /// - Note: This function is for Objective-C only.
    @objc(newAllMediasDeleterWithObserver:)
    func newAllMediasDeleterRef(observer: @escaping (_ deleter: AllMediasDeleter?) -> Void) -> GSAllMediasDeleterRef
}

/// :nodoc:
/// MediaStore description
@objc(GSMediaStoreDesc)
public class MediaStoreDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = MediaStore
    public let uid = PeripheralUid.mediaStore.rawValue
    public let parent: ComponentDescriptor? = nil
}
