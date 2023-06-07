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

/// A media websocket event
public enum MediaStoreChangeEvent {
    /// The first resource of a new media has been created.
    /// - Parameter media: The media that was created
    case createdMedia(_ media: MediaItemCore)
    /// A new resource of an existing media has been created.
    /// - Parameter resource: The resource that was created
    case createdResource(_ resource: MediaItemResourceCore, mediaId: String)
    /// The last resource of a media has been removed.
    /// - Parameter mediaId: The id of the media that was removed
    case removedMedia(mediaId: String)
    /// A resource of a media has been removed, the media still has remaining resource
    /// - Parameter resourceId: The id of the resource that was removed
    case removedResource(resourceId: String)
    /// All media were removed
    case allMediaRemoved
    /// The indexing state changed
    /// - Parameters:
    ///   - oldState: the old indexing state
    ///   - newState: the new indexing state
    case indexingStateChanged(oldState: MediaStoreIndexingState,
                              newState: MediaStoreIndexingState)
    /// The websocket disconnected
    case webSocketDisconnected
}

/// MediaResourceList concrete implementation
public class MediaResourceListCore: MediaResourceList {

    /// List entry
    struct Entry {
        /// media
        let media: MediaItemCore
        /// resources
        let resources: [MediaItemResourceCore]
        /// `true` if `resources` contains all resources of the media
        var allResourcesOfMedia: Bool {
            return media.resources.filter {return resources.contains($0 as! MediaItemResourceCore)}.count
                == media.resources.count
        }
    }

    /// Entry list
    private (set) var mediaResourceList = [Entry]()

    /// Constructor with all resources of a list of media
    ///
    /// - Parameter mediaList: list of media to include
    convenience init(allOf mediaList: [MediaItem]) {
        self.init()
        self.mediaResourceList = mediaList.map { (media: MediaItem) in
            Entry(media: media as! MediaItemCore,
                resources: media.resources as! [MediaItemResourceCore])
        }
    }

    /// Constructor with all resources of the given media list but excluding `DNG`
    ///
    /// - Parameter mediaList: list of media to include
    convenience init(allButDngOf mediaList: [MediaItem]) {
        self.init()
        for media in mediaList {
            for resource in media.resources where resource.format != .dng {
                self.add(media: media, resource: resource)
            }
        }
    }

    /// Add a media resource to the list
    ///
    /// - Parameters:
    ///   - media: media to add a resource of
    ///   - resource: resource to add
    public func add(media: MediaItem, resource: MediaItem.Resource) {
        if let idx = mediaResourceList.firstIndex(where: { $0.media === media }) {
            mediaResourceList[idx] = Entry(
                media: mediaResourceList[idx].media,
                resources: mediaResourceList[idx].resources + [resource as! MediaItemResourceCore])
        } else {
            mediaResourceList.append(
                Entry(media: media as! MediaItemCore, resources: [resource as! MediaItemResourceCore]))
        }
    }

    /// Add all resources of a media to the list
    ///
    /// - Parameters:
    ///   - media: media to add all resources of
    public func add(media: MediaItem) {
        if let idx = mediaResourceList.firstIndex(where: {$0.media === media}) {
            mediaResourceList[idx] = Entry(
                media: mediaResourceList[idx].media, resources: media.resources as! [MediaItemResourceCore])
        } else {
            mediaResourceList.append(
                Entry(media: media as! MediaItemCore, resources: media.resources as! [MediaItemResourceCore]))
        }
    }

    /// Create a media resources iterator
    ///
    /// - Returns: a new media resources iterator
    public func makeIterator() -> Iterator {
        return Iterator(list: mediaResourceList)
    }

    /// Media resources iterator
    public class Iterator: IteratorProtocol {
        /// List to iterate
        private let list: [Entry]
        /// Number of media in the iterator
        public var mediaCount: Int { list.count }
        /// Number of resources in the iterator
        public let resourceCount: Int
        /// Total resources size in the iterator
        public let totalSize: UInt64
        /// Index of the current media
        fileprivate private(set) var currentMediaIdx = 0
        /// Index of the current resource
        fileprivate private(set) var currentResourceIdx = 0
        /// Iterated resources total size
        fileprivate private(set) var currentSize = UInt64(0)
        /// Size of the current resource
        public var currentResourceSize: UInt64 {
            return currentResource?.size ?? 0
        }

        /// Current iterated entry
        private var currentEntry: MediaResourceListCore.Entry?
        /// Current iterated resource
        private var currentResource: MediaItemResourceCore?
        /// Iterator of entry list
        private var entriesIterator: AnyIterator<MediaResourceListCore.Entry>
        /// Iterator of current media resources
        private var resourcesIterator: AnyIterator<MediaItemResourceCore>?

        /// Constructor
        ///
        /// - Parameter list: list to iterate on
        fileprivate init(list: [Entry]) {
            self.list = list
            self.resourceCount = list.reduce(0) { sum, entry in
                sum + entry.resources.count
            }
            self.totalSize = list.reduce(0) { sum, entry in
                sum + entry.resources.reduce(0) { sum_, resource in
                    sum_ + resource.size
                }
            }
            entriesIterator = AnyIterator<MediaResourceListCore.Entry>(list.makeIterator())
        }

        /// Advances to the next element and returns it, or `nil` if no next element
        /// exists. Once `nil` has been returned, all subsequent calls return `nil`.
        ///
        /// - Returns: next entry, `nil` at the end of the list
        public func next() -> (media: MediaItemCore, resource: MediaItemResourceCore)? {
            var next: (media: MediaItemCore, resource: MediaItemResourceCore)?
            // move to the next resource
            if let resourcesIterator = resourcesIterator {
                currentResource = resourcesIterator.next()
                if let currentResource = currentResource {
                    next = (currentEntry!.media, currentResource)
                }
            }
            if next == nil {
                // no next resource in current entry. Move to the next entry
                repeat {
                    currentEntry = entriesIterator.next()
                    if let currentEntry = currentEntry {
                        currentMediaIdx += 1
                        resourcesIterator = AnyIterator<MediaItemResourceCore>(currentEntry.resources.makeIterator())
                        currentResource = resourcesIterator!.next()
                        if let currentResource = currentResource {
                            next = (currentEntry.media, currentResource)
                        }
                    }
                } while next == nil && currentEntry != nil
            }
            if let next = next {
                currentResourceIdx += 1
                currentSize += next.resource.size
            }
            return next
        }

        /// Advance to the resource of the current media or to the next media if the list contains
        /// all resources of the current media.
        ///
        /// - Returns: next entry, `nil` at the end of the list. If all resource of the current
        ///   media are in the list, returned tuple field `resource` is nil
        public func nextMediaOrResource() -> (media: MediaItemCore, resource: MediaItemResourceCore?)? {
            var next: (media: MediaItemCore, resource: MediaItemResourceCore?)?
            // move to the next resource
            if let resourcesIterator = resourcesIterator {
                currentResource = resourcesIterator.next()
                if let currentResource = currentResource {
                    next =  (currentEntry!.media, currentResource)
                    currentResourceIdx += 1
                    currentSize += currentResource.size
                }
            }
            if next == nil {
                // no next resource in current entry. Move to the next entry
                repeat {
                    currentEntry = entriesIterator.next()
                    if let currentEntry = currentEntry {
                        currentMediaIdx+=1
                        if !currentEntry.allResourcesOfMedia {
                            resourcesIterator =
                                AnyIterator<MediaItemResourceCore>(currentEntry.resources.makeIterator())
                            currentResource = resourcesIterator!.next()
                            if let currentResource = currentResource {
                                currentResourceIdx+=1
                                currentSize +=  currentResource.size
                                next = (currentEntry.media, currentResource)
                            }
                        } else {
                            resourcesIterator = nil
                            currentResource = nil
                            currentResourceIdx += currentEntry.resources.count
                            currentSize += currentEntry.resources.reduce(0) {$0 + $1.size}
                            next = (currentEntry.media, nil)
                        }
                    }
                } while next == nil && currentEntry != nil
            }
            return next
        }
    }
}

/// Media downloader implementation
public class MediaDownloaderCore: MediaDownloader {
    /// Construct a new media downloader based on MediaResourceListCore.Iterator progress
    ///
    /// - Parameters:
    ///   - iterator: media list iterator providing progress information on overall resource list download
    ///   - currentFileProgress: progress on the current file download (0.0 to 1.0)
    ///   - status: download status
    ///   - currentMedia : current downloading media
    ///   - fileUrl : url of downloaded file when progress is at 1.0, nil in other cases
    ///   - signatureUrl : url of downloaded signature when progress is at 1.0, nil in other cases
    public init(mediaResourceListIterator iterator: MediaResourceListCore.Iterator,
                currentFileProgress: Float, status: MediaTaskStatus, currentMedia: MediaItem? = nil,
                fileUrl: URL? = nil, signatureUrl: URL? = nil) {
        let progress = (Float(iterator.currentSize - iterator.currentResourceSize) +
            Float(iterator.currentResourceSize) * currentFileProgress) / Float(iterator.totalSize)
        super.init(totalMedia: iterator.mediaCount, countMedia: iterator.currentMediaIdx,
                   totalResources: iterator.resourceCount, countResources: iterator.currentResourceIdx,
                   currentFileProgress: currentFileProgress,
                   progress: progress, status: status, currentMedia: currentMedia, fileUrl: fileUrl,
                   signatureUrl: signatureUrl)
    }
}

/// Resource uploader core that makes `Core` constructor public.
public class ResourceUploaderCore: ResourceUploader, CustomDebugStringConvertible {

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
    public override init(targetMedia: MediaItem, totalResourceCount: Int, uploadedResourceCount: Int,
                         currentFileProgress: Float, totalProgress: Float, status: MediaTaskStatus,
                         currentFileUrl: URL? = nil) {
        super.init(targetMedia: targetMedia, totalResourceCount: totalResourceCount,
                   uploadedResourceCount: uploadedResourceCount, currentFileProgress: currentFileProgress,
                   totalProgress: totalProgress, status: status, currentFileUrl: currentFileUrl)
    }

    /// Debug description.
    public var debugDescription: String { """
        target: \(targetMedia.uid) uploaded: \(uploadedResourceCount)/\(totalResourceCount) \
        progress: \(currentFileProgress) totalProgress: \(totalProgress) status: \(status) \
        currentFile: \(String(describing: currentFileUrl))
        """
    }
}

/// Media deleter core that makes `Core` constructor public
public class MediaDeleterCore: MediaDeleter {

    /// Constructor
    ///
    /// - Parameters:
    ///    - iterator: media list iterator providing progress information on overall resource list to delete
    ///    - status: delete status
    public init(mediaResourceListIterator iterator: MediaResourceListCore.Iterator, status: MediaTaskStatus) {
        if status == .running {
            // when running, increment media counter when all resources of the media have been deleted
            super.init(totalCount: iterator.mediaCount, currentCount: iterator.currentMediaIdx - 1, status: status)
        } else {
            super.init(totalCount: iterator.mediaCount, currentCount: iterator.currentMediaIdx, status: status)
        }
    }
}

/// All medias deleter core that makes `Core` constructor public
public class AllMediasDeleterCore: AllMediasDeleter {
    /// Constructor
    ///
    /// - Parameter status: initial status
    public override init(status: MediaTaskStatus) {
        super.init(status: status)
    }
}

/// MediaStore backend.
public protocol MediaStoreBackend: AnyObject {

    /// Start watching media store content.
    ///
    /// When content watching is started, backend must call `markContentChanged()` when the content of
    /// the media store changes.
    func startWatchingContentChanges()

    /// Stop watching media store content.
    func stopWatchingContentChanges()

    /// Browse medias.
    ///
    /// - Parameters:
    ///   - completion: completion closure called when the request is terminated.
    ///   - medias: list of medias
    /// - Returns: browse request, or `nil` if the request can't be sent
    func browse(completion: @escaping (_ medias: [MediaItemCore]) -> Void) -> CancelableCore?

    /// Browse medias in a specific storage.
    ///
    /// - Parameters:
    ///   - storage: storage type to browse
    ///   - completion: completion closure called when the request is terminated.
    ///   - medias: list of medias
    /// - Returns: browse request, or `nil` if the request can't be sent
    func browse(storage: StorageType?,
                completion: @escaping (_ medias: [MediaItemCore]) -> Void) -> CancelableCore?

    /// Download a thumbnail
    ///
    /// - Parameters:
    ///   - media: media item to download the thumbnail
    ///   - completion: closure called when the thumbnail has been downloaded or if there is an error.
    ///   - thumbnailData: downloaded thumbnail data, `nil` if there is a error
    /// - Returns: download thumbnail request, or `nil` if the request can't be sent
    func downloadThumbnail(for owner: MediaStoreThumbnailCacheCore.ThumbnailOwner,
                           completion: @escaping (_ thumbnailData: Data?) -> Void) -> IdentifiableCancelableCore?

    /// Download media resources
    ///
    /// - Parameters:
    ///   - mediaResources: list of media resources to download
    ///   - type: download type
    ///   - destination: download destination
    ///   - progress: download progress callback
    /// - Returns: download media resources request, or `nil` if the request can't be sent
    func download(mediaResources: MediaResourceListCore, type: DownloadType, destination: DownloadDestination,
                  progress: @escaping (MediaDownloader) -> Void) -> CancelableCore?

    /// Uploads media resources.
    ///
    /// - Parameters:
    ///   - resources: resource files to upload
    ///   - target: target media item to attach uploaded resource files to
    ///   - progress: upload progress callback
    /// - Returns: resource upload request, or `nil` if the request can't be sent.
    func upload(resources: [URL], target: MediaItemCore,
                progress: @escaping (ResourceUploader?) -> Void) -> CancelableCore?

    /// Delete medias resources
    ///
    /// - Parameters:
    ///   - mediaResources: list of media resources to delete
    ///   - progress: progress closure called after each deleted files
    /// - Returns: delete request, or `nil` if the request can't be sent
    func delete(mediaResources: MediaResourceListCore, progress: @escaping (MediaDeleter) -> Void)
        -> CancelableCore?

    /// Delete all medias
    ///
    /// - Parameter progress: progress closure called when the state of the delete task changes
    /// - Returns: delete request, or `nil` if the request can't be sent
    func deleteAll(progress: @escaping (AllMediasDeleter) -> Void) -> CancelableCore?

    /// The current indexing state of the media store.
    var indexingState: MediaStoreIndexingState { get }
}

/// Internal MediaStore implementation
public class MediaStoreCore: PeripheralCore, MediaStore {
    /// Listener notified when the media store content changes
    class Listener: NSObject {
        /// Closure called when the media store content changes.
        /// - Parameter event: The event that occurred.
        fileprivate let didChange: (_ event: MediaStoreChangeEvent) -> Void

        /// Constructor
        ///
        /// - Parameters:
        ///  - didChange: closure called when the state changes
        ///  - event: The event that occurred
        fileprivate init(didChange: @escaping (_ event: MediaStoreChangeEvent) -> Void) {
            self.didChange = didChange
        }
    }

    /// backend
    unowned let backend: MediaStoreBackend

    /// Thumbnail cache
    private let thumbnailCache: MediaStoreThumbnailCacheCore

    /// Listeners
    private var listeners: Set<Listener> = []

    public private(set) var indexingState = MediaStoreIndexingState.unavailable
    public private(set) var photoMediaCount = 0
    public private(set) var videoMediaCount = 0
    public private(set) var photoResourceCount = 0
    public private(set) var videoResourceCount = 0

    /// not `nil` if the mediastore content has changed, the event describes how it has changed
    private var storeChangeEvent: MediaStoreChangeEvent?

    /// Constructor
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored
    ///   - backend: MediaStore backend
    public init(store: ComponentStoreCore, thumbnailCache: MediaStoreThumbnailCacheCore, backend: MediaStoreBackend) {
        self.backend = backend
        self.thumbnailCache = thumbnailCache
        super.init(desc: Peripherals.mediaStore, store: store)
    }

    /// Create a new Media list request.
    ///
    /// This function starts loading the media store content, and notify when the it has been loaded and each time
    /// the content changes.
    ///
    /// - Parameter observer: observer  notified when the media list has been loaded or has change.
    /// - Returns: a reference on a list of MediaItem
    public func newList(observer: @escaping Ref<[MediaItem]>.Observer) -> Ref<[MediaItem]> {
        return MediaListRefCore(mediaStore: self, observer: observer)
    }

    /// Creates a new Media list for a specific storage.
    ///
    /// This function starts loading the media store content on  a specific storage, and notify when it has been loaded
    /// and each time the content changes.
    ///
    /// - Parameters:
    ///   - storage: storage type on which the Media list will be created
    ///   - observer: observer  notified when the media list has been loaded or has change.
    ///   - medias: list media, `nil` if the store has been removed
    /// - Returns: a reference on a list of MediaItem. Caller must keep this instance referenced for the observer to be
    ///   called.
    public func newList(storage: StorageType?,
                        observer: @escaping (_ medias: [MediaItem]?) -> Void) -> Ref<[MediaItem]> {
        return MediaListRefCore(storage: storage, mediaStore: self, observer: observer)
    }

    /// Create a new media thumbnail downloader
    ///
    /// - Parameters:
    ///   - media: media item to download the thumbnail from
    ///   - observer: observer called when the thumbnail has been downloaded. Observer is called immediately if the
    ///     thumbnail is already cached, and may be called with a nil image if the thumbnail can't be downloaded
    /// - Returns: A reference of the media downloader. Caller must keep this instance referenced for the observer
    ///   to be called.
    public func newThumbnailDownloader(
        media: MediaItem, observer: @escaping (_ thumbnail: UIImage?) -> Void) -> Ref<UIImage> {

        return MediaThumbnailRefCore(thumbnailCache: self.thumbnailCache,
                                     owner: .media(media as! MediaItemCore),
                                     observer: observer)
    }

    /// Create a new resource thumbnail downloader
    ///
    /// - Parameters:
    ///   - resource: resource item to download the thumbnail from
    ///   - observer: observer called when the thumbnail has been downloaded. Observer is called immediately if the
    ///     thumbnail is already cached, and may be called with a nil image if the thumbnail can't be downloaded
    /// - Returns: A reference of the media downloader. Caller must keep this instance referenced for the observer
    ///   to be called.
    public func newThumbnailDownloader(
        resource: MediaItem.Resource, observer: @escaping (_ thumbnail: UIImage?) -> Void) -> Ref<UIImage> {
            return MediaThumbnailRefCore(thumbnailCache: self.thumbnailCache,
                                         owner: .resource(resource as! MediaItemResourceCore),
                                         observer: observer)
        }

    /// Create a new media resource downloader
    ///
    /// - Parameters:
    ///   - mediaResources: list of media resources to download
    ///   - type: download type
    ///   - destination: download destination
    ///   - observer: observer called when the Media downloader changes, indicating download progress
    /// - Returns: a reference on a MediaDownloader. Caller must keep this instance referenced until all media are
    ///   downloaded. Setting it to nil cancel the download.
    public func newDownloader(mediaResources: MediaResourceList, type: DownloadType, destination: DownloadDestination,
                              observer: @escaping (MediaDownloader?) -> Void) -> Ref<MediaDownloader> {
        return MediaDownloaderRefCore(mediaStore: self, mediaResources: mediaResources as! MediaResourceListCore,
                                      type: type, destination: destination, observer: observer)
    }

    /// Creates a new media resource uploader.
    ///
    /// Resource files will be uploaded to the device's internal storage, in the order defined by the specified
    /// `resources` array.
    ///
    /// - Parameters:
    ///   - resources: resource files to upload
    ///   - target: target media item to attach uploaded resource files to
    ///   - observer: observer notified of upload progress and status
    /// - Returns: a reference on a ResourceUploader. Caller must keep this instance referenced for the observer to be
    ///   called.
    public func newUploader(resources: [URL], target: MediaItem,
                            observer: @escaping (ResourceUploader?) -> Void) -> Ref<ResourceUploader> {
        return ResourceUploaderRefCore(mediaStore: self, resources: resources, target: target as! MediaItemCore,
                                       observer: observer)
    }

    /// Create a new Media deleter, to delete a list of media
    ///
    /// - Parameters:
    ///   - medias: medias to delete.
    ///   - observer: observer notified progress of the delete task.
    /// - Returns: a reference on a MediaDeleter.
    public func newDeleter(medias: [MediaItem], observer: @escaping Ref<MediaDeleter>.Observer) -> Ref<MediaDeleter> {
        return MediaDeleterRefCore(mediaStore: self, mediaResources: MediaResourceListFactory.listWith(allOf: medias),
                                   observer: observer)
    }

    /// Create a new Media deleter, to delete a list of media resources
    ///
    /// - Parameters:
    ///   - mediaResources: list of media resources to delete
    ///   - observer: observer notified progress of the delete task. Referenced media deleter is nil if the delete
    ///     task is interrupted.
    ///   - deleter: deleter storing the delete progress info
    /// - Returns: a reference on a MediaDeleter. Caller must keep this instance referenced until all media are
    ///   deleted. Setting it to nil cancel the delete.
    public func newDeleter(mediaResources: MediaResourceList, observer: @escaping (_ deleter: MediaDeleter?) -> Void)
        -> Ref<MediaDeleter> {
            return MediaDeleterRefCore(mediaStore: self, mediaResources: mediaResources, observer: observer)
    }

    public func newAllMediasDeleter(observer: @escaping (AllMediasDeleter?) -> Void) -> Ref<AllMediasDeleter> {
        return AllMediasDeleterRefCore(mediaStore: self, observer: observer)
    }

    /// Reset component state. Called when the component is unpublished.
    override func reset() {
        listeners.forEach {
            $0.didChange(.allMediaRemoved)
        }
        thumbnailCache.clear()
    }

    /// Register a mediaStore listener
    ///
    /// - Parameter didChange: closure to call when the store content changes
    /// - Returns: created listener, to unregister it
    func register(didChange: @escaping (MediaStoreChangeEvent) -> Void) -> Listener {
        let listener = Listener(didChange: didChange)
        if listeners.isEmpty {
            backend.startWatchingContentChanges()
        }
        listeners.insert(listener)
        return listener
    }

    /// Unregister a mediaStore listener
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
            handleCacheInvalidation(storeChangeEvent)
            self.storeChangeEvent = nil
            listeners.forEach {
                $0.didChange(storeChangeEvent)
            }
        }
        super.notifyUpdated()
    }

    /// Handles thumbnail cache invalidation based on a change event.
    ///
    /// - Parameters:
    ///   - event: the change event
    private func handleCacheInvalidation(_ event: MediaStoreChangeEvent) {
        switch event {
        case .removedResource(resourceId: let id),
                .createdResource(_, mediaId: let id):
            thumbnailCache.invalidate(id)
        case .allMediaRemoved:
            thumbnailCache.clear()
        default:
            break
        }
    }
}

/// Objective-C extension adding MediaStoreCore swift methods that can't be automatically converted.
/// Those methods should no be used from swift
extension MediaStoreCore: GSMediaStore {

    /// Create a new Media list request for a storage.
    ///
    /// This function starts loading the media store content, and notify when the it has been loaded and each time
    /// the content changes.
    ///
    /// - Parameters:
    ///     - storage: the storage type where to browse
    ///     - observer: observer  notified when the media list has been loaded or has change.
    /// - Returns: a reference on a list of MediaItem
    public func newListRef(storage: StorageType, observer: @escaping ([MediaItem]?) -> Void) -> GSMediaListRef {
        return GSMediaListRef(ref: newList(storage: storage, observer: observer))
    }

    /// Create a new Media list request.
    ///
    /// This function starts loading the media store content, and notify when the it has been loaded and each time
    /// the content changes.
    ///
    /// - Parameter observer: observer  notified when the media list has been loaded or has change.
    /// - Returns: a reference on a list of MediaItem
    public func newListRef(observer: @escaping ([MediaItem]?) -> Void) -> GSMediaListRef {
        return GSMediaListRef(ref: newList(observer: observer))
    }

    /// Create a new thumbnail downloader
    ///
    /// - Parameters:
    ///   - media: media item to download the thumbnail from
    ///   - observer: observer called when the thumbnail has been downloaded. Observer is called immediately if the
    ///     thumbnail is already cached
    ///   - thumbnail: loaded or cached thumbnail, nil if the thumbnail can't be downloaded
    /// - Returns: A reference of the media downloader. Caller must keep this instance referenced for the observer
    ///   to be called.
    public func newThumbnailDownloaderRef(media: MediaItem, observer: @escaping (UIImage?) -> Void) -> GSMediaImageRef {
        return GSMediaImageRef(ref: newThumbnailDownloader(media: media, observer: observer))
    }

    /// Create a new media resource downloader
    ///
    /// - Parameters:
    ///   - mediaResources: list of media resources to download
    ///   - destination: download destination
    ///   - observer: observer called when the Media downloader changes, indicating download progress
    /// - Returns: a reference on a MediaDownloader. Caller must keep this instance referenced until all media are
    ///   downloaded. Setting it to nil cancel the download.
    public func newDownloaderRef(mediaResources: MediaResourceList, destination: GSDownloadDestination,
                                 observer: @escaping (MediaDownloader?) -> Void) -> GSMediaDownloaderRef {
        return GSMediaDownloaderRef(ref: newDownloader(
            mediaResources: mediaResources, destination: destination.destination, observer: observer))
    }

    /// Create a new Media deleter, to delete a list of media
    ///
    /// - Parameters:
    ///   - medias: medias to delete.
    ///   - observer: observer notified progress of the delete task.
    /// - Returns: a reference on a MediaDeleter.
    public func newDeleterRef(medias: [MediaItem], observer: @escaping (MediaDeleter?) -> Void) -> GSMediaDeleterRef {
        return GSMediaDeleterRef(ref: newDeleter(medias: medias, observer: observer))
    }

    public func newAllMediasDeleterRef(observer: @escaping (AllMediasDeleter?) -> Void) -> GSAllMediasDeleterRef {
        return GSAllMediasDeleterRef(ref: newAllMediasDeleter(observer: observer))
    }
}

/// Backend callback methods
extension MediaStoreCore {

    /// Updates the indexing state
    ///
    /// - Parameter indexingState: new indexing state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    @objc
    public func update(indexingState newValue: MediaStoreIndexingState) -> MediaStoreCore {
        if indexingState != newValue {
            indexingState = newValue
            markChanged()
        }
        return self
    }

    /// Updates the number of photo media in the media store
    ///
    /// - Parameter photoMediaCount: new number of photo medias
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(photoMediaCount newValue: Int) -> MediaStoreCore {
        if photoMediaCount != newValue {
            photoMediaCount = newValue
            markChanged()
        }
        return self
    }

    /// Updates the number of video medias in the media store
    ///
    /// - Parameter videoMediaCount: new number of video medias
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(videoMediaCount newValue: Int) -> MediaStoreCore {
        if videoMediaCount != newValue {
            videoMediaCount = newValue
            markChanged()
        }
        return self
    }

    /// Updates the number of photo resources in the media store
    ///
    /// - Parameter photoResourceCount: new number of photo resources
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(photoResourceCount newValue: Int) -> MediaStoreCore {
        if photoResourceCount != newValue {
            photoResourceCount = newValue
            markChanged()
        }
        return self
    }

    /// Updates the number of video resources in the media store
    ///
    /// - Parameter videoResourceCount: new number of video resources
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(videoResourceCount newValue: Int) -> MediaStoreCore {
        if videoResourceCount != newValue {
            videoResourceCount = newValue
            markChanged()
        }
        return self
    }

    /// Tells that media store content has change
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func markContentChanged(withEvent event: MediaStoreChangeEvent) -> MediaStoreCore {
        storeChangeEvent = event
        markChanged()
        return self
    }
}
