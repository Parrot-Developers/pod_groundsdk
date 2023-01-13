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

/// Media store thumbnail cache
public class MediaStoreThumbnailCacheCore {
    private typealias CacheNode = LinkedList<CacheEntry>.Node
    private typealias ThumbnailOwnerNode = LinkedList<ThumbnailOwner>.Node

    /// Owner of the thumbnail
    public enum ThumbnailOwner {
        // swiftlint:disable:next nesting
        public typealias Uid = String
        /// The thumbnail belongs to a media
        case media(MediaItemCore)
        /// The thumbnail belongs to a resource
        case resource(MediaItemResourceCore)

        /// Unique identifier of the owner.
        /// This identifier is only unique for a given drone.
        public var uid: Uid {
            switch self {
            case .media(let media): return media.uid
            case .resource(let resource): return resource.uid
            }
        }
    }

    /// A request for a thumbnail
    private class ThumbnailRequest: CancelableCore {
        /// cache instance
        private weak var cache: MediaStoreThumbnailCacheCore?
        /// uid of the requested thumbnail media
        fileprivate let mediaUid: String
        /// callback
        private let loadedCallback: (UIImage?) -> Void
        /// indicates whether the request was canceled
        fileprivate private(set) var canceled: Bool = false

        /// Constructor
        ///
        /// - Parameters:
        ///   - cache: cache instance
        ///   - mediaUid: uid of the requested thumbnail media
        ///   - loadedCallback: callback
        init(cache: MediaStoreThumbnailCacheCore, mediaUid: String,
             loadedCallback: @escaping (UIImage?) -> Void) {
            self.cache = cache
            self.mediaUid = mediaUid
            self.loadedCallback = loadedCallback
        }

        /// Cancel the request
        func cancel() {
            guard !canceled else { return }
            canceled = cache?.cancelRequest(self) == true
        }

        /// Fullfils the request by providing the data to the callback.
        /// - Parameter image: The image to provide to the callback
        func fullfil(_ image: UIImage?) {
            loadedCallback(image)
        }
    }

    /// Cache entry
    private enum CacheEntry {
        /// a cached image
        case image(uid: ThumbnailOwner.Uid, data: Data)
        /// an active request, i.e. a request with client waiting callback call
        case request(owner: ThumbnailOwnerNode, requests: [ThumbnailRequest])

        /// Unique identifier of the entry.
        /// This identifier is only unique for a given drone.
        public var uid: ThumbnailOwner.Uid {
            switch self {
            case .image(let mediaUid, data: _): return mediaUid
            case .request(owner: let ownerNode, requests: _): return ownerNode.content!.uid
            }
        }
    }

    /// Media store backend instance
    private unowned let mediaStoreBackend: MediaStoreBackend
    /// Cache, by media uid
    private var cache = [ThumbnailOwner.Uid: CacheNode]()
    /// List of cache entries, by usage order
    private var cacheLru = LinkedList<CacheEntry>()
    /// Cache maximum size
    private let maxSize: Int
    /// Cache total size
    private var totalSize = 0

    /// Pending download requests
    private let downloadRequests = LinkedList<ThumbnailOwner>()
    /// Current download requests
    private var currentDownloadRequest: IdentifiableCancelableCore?

    /// Indicates wether the current/active download request should enqueued for re-execution.
    /// This means that the current/active request will be cancelled.
    private var retryCurrentDownloadRequest: Bool = false

    /// Constructor
    ///
    /// - Parameters:
    ///   - mediaStoreBackend: media store backend
    ///   - size: maximum cache size
    public init(mediaStoreBackend: MediaStoreBackend, size: Int) {
        self.mediaStoreBackend = mediaStoreBackend
        self.maxSize = size
    }

    /// Clear cache content, stop all pending requests
    func clear() {
        currentDownloadRequest?.cancel()
        downloadRequests.reset()
        cacheLru.reset()
        cache = [:]
        totalSize = 0
    }

    /// Invalidate a cache entry related to a media uid.
    ///
    /// - Parameters:
    ///   - uid: the media uid of the cache entry to invalidate.
    func invalidate(_ uid: ThumbnailOwner.Uid) {
        func empty(entry: CacheEntry) {
            switch entry {
            case .image:
                cache[entry.uid] = nil
            case .request:
                if currentDownloadRequest?.id == uid {
                    ULog.d(.coreMediaTag, "invalidated active request for media '\(uid)'. Mark for retry")
                    retryCurrentDownloadRequest = true
                    currentDownloadRequest?.cancel()
                }
            }
        }
        if let entry = cache[uid]?.content {
            // fast path
            empty(entry: entry)
        } else if let splitIndex = uid.firstIndex(of: "_") {
            // slow path
            let prefix = uid[..<splitIndex]
            let concernedKeys = cache.keys.filter({ $0.hasPrefix(prefix) })
            for key in concernedKeys {
                let entry = cache[key]!.content!
                empty(entry: entry)
            }
        }
    }

    /// Get a thumbnail
    ///
    /// - Parameters:
    ///   - owner: owner to get the thumbnail for
    ///   - loadedCallback: callback called when the thumbnail has been downloaded, called immediately if the thumbnail
    ///     is already cached
    /// - Returns: a canceallable request if the image is not already in the cache
    func getThumbnail(for owner: ThumbnailOwner, loadedCallback: @escaping (UIImage?) -> Void) -> CancelableCore? {
        // thumbnail returned to caller
        var request: ThumbnailRequest?
        // check if there is a node in the cache
        if let node = cache[owner.uid] {
            // existing request/node, update it
            request = existingRequest(forNode: node, withOwner: owner, completion: loadedCallback)
        } else {
            // create a new download request
            request = newRequest(withOwner: owner, completion: loadedCallback)
        }
        return request
    }
}

private extension MediaStoreThumbnailCacheCore {

    private func newRequest(withOwner owner: ThumbnailOwner,
                            completion: @escaping (UIImage?) -> Void) -> ThumbnailRequest {
        // create a new node and queue download
        let request = ThumbnailRequest(cache: self, mediaUid: owner.uid, loadedCallback: completion)
        let ownerNode = ThumbnailOwnerNode(content: owner)
        let node = CacheNode(content: .request(owner: ownerNode, requests: [request]))
        cache[owner.uid] = node
        // move to the top of the lru
        cacheLru.insert(node)
        ULog.d(.coreMediaTag, "created new request for media '\(owner.uid)'")
        queueRequest(node: ownerNode)
        return request
    }

    private func existingRequest(forNode node: CacheNode, withOwner owner: ThumbnailOwner,
                         completion: @escaping (UIImage?) -> Void) -> ThumbnailRequest? {
        // move to the top of the lru
        cacheLru.remove(node)
        cacheLru.insert(node)
        switch node.content! {
        case .image(_, let data):
            // existing image data, call the loaded callback now
            completion(UIImage(data: data))
        case .request(let ownerNode, let requests):
            // existing request add new client reference
            let request = ThumbnailRequest(cache: self, mediaUid: ownerNode.content!.uid,
                                           loadedCallback: completion)
            let newRequests = requests + [request]
            node.content = .request(owner: ownerNode, requests: newRequests)
            ULog.d(.coreMediaTag, "added callback to existing request (\(newRequests.count)) for media '\(owner.uid)'")
            return request
        }
        return nil
    }

    /// Cancel a thumbnail request
    ///
    /// - Parameter request: request to cancel
    /// - Returns `true` if it was removed from the cache, or `false` if there are still requests
    ///   pending
    private func cancelRequest(_ request: ThumbnailRequest) -> Bool {
        guard let node = cache[request.mediaUid],
              case .request(let ownerNode, let requests) = node.content! else {
            return false
        }
        let remainingRequests = requests.filter { $0 !== request }
        let owner = ownerNode.content!
        if remainingRequests.isEmpty {
            // if no callback owners remain then remove the request
            removeRequest(ownerNode: ownerNode)
            cache[owner.uid] = nil
            cacheLru.remove(node)
            return true
        } else {
            // otherwise update the existing request with the remaining request owners
            node.content = .request(owner: ownerNode, requests: remainingRequests)
            ULog.d(.coreMediaTag, "removed request for media '\(owner.uid)' ")
            return false
        }
    }

    /// Queue a thumbnail download request
    ///
    /// - Parameter owner: owner to download the thumbnail for
    /// - Returns: node added to the downloadRequests queue
    private func queueRequest(node: ThumbnailOwnerNode) {
        ULog.d(.coreMediaTag, "queued download request for media '\(node.content!.uid)'")
        downloadRequests.enqueue(node)
        // kick off download state machine if not active
        processNextRequest()
    }

    /// Dequeue a download request
    ///
    /// This will also cancel the request if it was active
    ///
    /// - Parameter downloadNode: download request note to dequeue
    private func removeRequest(ownerNode: ThumbnailOwnerNode) {
        let owner = ownerNode.content!
        let uid = owner.uid
        downloadRequests.remove(ownerNode)
        ULog.d(.coreMediaTag, "removed request for media '\(uid)'")
        if let currentDownloadRequest = self.currentDownloadRequest,
           currentDownloadRequest.id == uid {
            ULog.d(.coreMediaTag, "canceled active request for media '\(uid)'")
            currentDownloadRequest.cancel()
        }
    }

    /// Download the next thumbnail if there is no active request
    func processNextRequest() {
        guard currentDownloadRequest == nil,
        let downloadRequest = downloadRequests.pop() else {
            return
        }
        let owner = downloadRequest.content!
        let uid = owner.uid
        ULog.d(.coreMediaTag, "starting download for media '\(uid)'")
        currentDownloadRequest = mediaStoreBackend
            .downloadThumbnail(for: owner) { [unowned self] thumbnailData in
                // if should retry current download request, re insert the
                // request and stop any further treatment
                if self.retryCurrentDownloadRequest {
                    self.retryCurrentDownloadRequest = false
                    self.downloadRequests.insert(downloadRequest)
                    self.currentDownloadRequest = nil
                    ULog.d(.coreMediaTag, "retrying canceled request for media '\(uid)'")
                    self.processNextRequest()
                    return
                }

                if let thumbnailData = thumbnailData {
                    self.insertThumbnailInCache(uid: uid, data: thumbnailData)
                } else {
                    self.handleFailedThumbnail(uid: uid)
                }
                self.currentDownloadRequest = nil
                self.processNextRequest()
        }
        // download request failed to start
        if currentDownloadRequest == nil {
            handleFailedThumbnail(uid: uid)
            processNextRequest()
        }
    }

    /// Handles the fetch failure of a thumbnail with a given uid.
    ///
    /// - Parameters:
    ///   - uid: the media uid that the corresponding thumbnail download request failed.
    private func handleFailedThumbnail(uid: String) {
        ULog.e(.coreMediaTag, "failed to cache media '\(uid)'")
        guard let node = cache[uid],
              let content = node.content else { return }

        var activeRequests  = [ThumbnailRequest]()
        // notify the absence of a thumbnail to observers
        if case .request(_, let requests) = content {
            activeRequests = requests.filter { !$0.canceled }
            // call only canceled callbacks
            requests.forEach {
                $0.fullfil(nil)
            }
        }
        // download failed or cancelled, clean lists
        cacheLru.remove(node)
        cache[uid] = nil
        // insert again non cancelled requests
        if !activeRequests.isEmpty,
           case .request(let ownerNode, _) = content {
            let updatedNode = CacheNode(content: .request(owner: ownerNode, requests: activeRequests))
            cache[uid] = updatedNode
            cacheLru.insert(updatedNode)
        }
    }

    /// Insert a downloaded thumbnail into the cache
    ///
    /// - Parameters:
    ///   - mediaUid: uid of the media
    ///   - thumbnailData: thumbnail data
    func insertThumbnailInCache(uid: String, data: Data) {
        if let node = cache[uid], let content = node.content {
            if case .request(_, let requests) = content {
                let image = UIImage(data: data)
                requests.forEach { $0.fullfil(image) }
            }
            node.content = .image(uid: uid, data: data)
            totalSize += data.count
            ULog.i(.coreMediaTag, "cached media '\(uid)' totalCacheSize:\(totalSize)")
        }
        if totalSize > maxSize {
            cleanLeastRecentlyUsedEntries()
        }
    }

    /// Remove old cache entries until the cache is lower that it's maximum size
    private func cleanLeastRecentlyUsedEntries() {
        cacheLru.reverseWalk { node in
            switch node.content! {
            case .image(let uid, let data):
                cache[uid] = nil
                totalSize -= data.count
                cacheLru.remove(node)
                ULog.d(.coreMediaTag, "removed cached media '\(uid)';"
                       + " new cacheSize: \(totalSize)")
            default:
                break
            }
            return totalSize > maxSize
        }
    }
}
