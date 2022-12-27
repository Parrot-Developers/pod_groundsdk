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
        fileprivate let loadedCallback: (UIImage?) -> Void

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

        /// Cancel the requests
        func cancel() {
            cache?.cancelRequest(self)
        }
    }

    /// Cache entry
    private enum CacheEntry {
        /// a cached image
        case image(mediaUid: ThumbnailOwner.Uid, imageData: Data)
        /// an active request, i.e a request with client waiting callback call
        case activeRequest(owner: ThumbnailOwnerNode, requests: [ThumbnailRequest])

        /// Unique identifier of the entry.
        /// This identifier is only unique for a given drone.
        public var uid: ThumbnailOwner.Uid {
            switch self {
            case .image(let mediaUid, imageData: _): return mediaUid
            case .activeRequest(owner: let ownerNode, requests: _): return ownerNode.content!.uid
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
            case .activeRequest:
                if currentDownloadRequest?.id == uid {
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
        ULog.d(.coreMediaTag, "getThumbnail, create new activeRequest \(owner.uid)")
        let request = ThumbnailRequest(cache: self, mediaUid: owner.uid, loadedCallback: completion)
        let ownerNode = ThumbnailOwnerNode(content: owner)
        let node = CacheNode(content: .activeRequest(owner: ownerNode, requests: [request]))
        self.cache[owner.uid] = node
        // move to the top of the lru
        cacheLru.insert(node)
        queueRequest(node: ownerNode)
        return request
    }

    private func existingRequest(forNode node: CacheNode, withOwner owner: ThumbnailOwner,
                         completion: @escaping (UIImage?) -> Void) -> ThumbnailRequest? {
        // move to the top of the lru
        cacheLru.remove(node)
        cacheLru.insert(node)
        switch node.content! {
        case .image(_, let thumbnailData):
            // existing image data, call the loaded callback now
            completion(UIImage(data: thumbnailData))
        case .activeRequest(let ownerNode, let requests):
            ULog.d(.coreMediaTag, "getThumbnail, adding callback to activeRequest \(owner.uid)")
            // active request add new client reference
            let request = ThumbnailRequest(cache: self, mediaUid: ownerNode.content!.uid,
                                           loadedCallback: completion)
            node.content = .activeRequest(owner: ownerNode, requests: requests + [request])
            return request
        }
        return nil
    }

    /// Cancel a thumbnail request
    ///
    /// - Parameter request: request to cancel
    private func cancelRequest(_ request: ThumbnailRequest) {
        guard let node = cache[request.mediaUid],
              case .activeRequest(let ownerNode, let requests) = node.content! else {
            return
        }
        let remainingRequests = requests.filter { $0 !== request }
        let owner = ownerNode.content!
        if remainingRequests.isEmpty {
            // if no remaining callback owners exist then transform the request to background one
            removeRequest(ownerNode: ownerNode)
            cache[owner.uid] = nil
            cacheLru.remove(node)
            ULog.d(.coreMediaTag, "cancel request \(request) for media '\(owner.uid)'")
        } else {
            // otherwise update the active request with the remaining request owners
            node.content = .activeRequest(owner: ownerNode, requests: remainingRequests)
            ULog.d(.coreMediaTag, "remove request \(request) for media '\(owner.uid)' ")
        }
    }

    /// Queue a thumbnail download request
    ///
    /// - Parameter owner: owner to download the thumbnail for
    /// - Returns: node added to the downloadRequests queue
    private func queueRequest(node: ThumbnailOwnerNode) {
        ULog.d(.coreMediaTag, "queue download thumbnail request for media '\(node.content!.uid)'")
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
        ULog.d(.coreMediaTag, "remove download request for media '\(owner.uid)'")
        downloadRequests.remove(ownerNode)
        if let currentDownloadRequest = self.currentDownloadRequest,
           currentDownloadRequest.id == owner.uid {
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
        ULog.d(.coreMediaTag, "downloading thumbnail for media '\(uid)'")
        currentDownloadRequest = mediaStoreBackend
            .downloadThumbnail(for: owner) { [unowned self] thumbnailData in
                // if should retry current download request, re insert the
                // request and stop any further treatment
                if self.retryCurrentDownloadRequest {
                    self.retryCurrentDownloadRequest = false
                    self.downloadRequests.insert(downloadRequest)
                    self.currentDownloadRequest = nil
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
    func handleFailedThumbnail(uid: String) {
        ULog.e(.coreMediaTag, "failed to cache thumbnail \(uid)")
        guard let node = cache[uid],
              let content = node.content else { return }

        // notify the absence of a thumbnail to observers
        if case .activeRequest(_, let requests) = content {
            requests.forEach {
                $0.loadedCallback(nil)
            }
        }
        // download failed or cancelled, clean lists
        cacheLru.remove(node)
        cache[uid] = nil
    }

    /// Insert a downloaded thumbnail into the cache
    ///
    /// - Parameters:
    ///   - mediaUid: uid of the media
    ///   - thumbnailData: thumbnail data
    func insertThumbnailInCache(uid: String, data: Data) {
        if let node = cache[uid], let content = node.content {
            if case .activeRequest(_, let requests) = content {
                let image = UIImage(data: data)
                requests.forEach { $0.loadedCallback(image) }
            }
            node.content = .image(mediaUid: uid, imageData: data)
            totalSize += data.count
            ULog.i(.coreMediaTag, "cached thumbnail \(uid) totalCacheSize:\(totalSize)")
        }
        if totalSize > maxSize {
            cleanLeastRecentlyUsedEntries()
        }
    }

    /// Remove old cache entries until the cache is lower that it's maximum size
    func cleanLeastRecentlyUsedEntries() {
        cacheLru.reverseWalk { node in
            switch node.content! {
            case .image(let mediaUid, let thumbnailData):
                cache[mediaUid] = nil
                totalSize -= thumbnailData.count
                cacheLru.remove(node)
                ULog.d(.coreMediaTag, "removed cached thumbnail for media '\(mediaUid)';"
                       + " new cacheSize: \(totalSize)")
            default:
                break
            }
            return totalSize > maxSize
        }
    }
}
