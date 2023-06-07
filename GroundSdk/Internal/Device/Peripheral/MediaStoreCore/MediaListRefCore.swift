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

/// Implementation of a reference on a list of media items
class MediaListRefCore: Ref<[MediaItem]>, MediaOperationRef {
    /// Media store instance
    private let mediaStore: MediaStoreCore
    /// Media store listener
    private var mediaStoreListener: MediaStoreCore.Listener!
    /// Running media browse request, nil if there are no queries running
    private(set) var request: CancelableCore?

    /// A list of the change events that occurred after the initial browse request, that should be
    /// treated upon the completion of the initial browse request.
    private var pendingChangeEvents = [MediaStoreChangeEvent]()

    /// The current storage type that is being browsed.
    private var storageType: StorageType?

    /// The current indexing state.
    private var indexingState: MediaStoreIndexingState {
        mediaStore.indexingState
    }

    /// Convenience accessor to the `value` of the `Ref` returning the `value` typed to a
    /// implementation dependent type.
    private var medias: [MediaItemCore] {
        self.value as! [MediaItemCore]
    }

    /// Constructor
    ///
    /// - Parameters:
    ///   - storage: the storage type
    ///   - mediaStore: media store instance
    ///   - observer: observer notified when the list changes
    init(storage: StorageType? = nil, mediaStore: MediaStoreCore, observer: @escaping Observer) {
        self.storageType = storage
        self.mediaStore = mediaStore
        super.init(observer: observer)
        // register ourself on store change notifications
        mediaStoreListener = mediaStore.register { [unowned self] event in
            // store content changed, update media list
            self.mediaEventOccured(event, forStorageType: storage)
        }
        setup(value: nil)
        // send the initial query
        if indexingState == .indexed {
            browse(storageType: storage)
        }
    }

    /// destructor
    deinit {
        cancel()
        mediaStore.unregister(listener: mediaStoreListener)
    }

    /// Cancels the request
    func cancel() {
        request?.cancel()
        request = nil
    }
}

private extension MediaListRefCore {

    /// Send a request to load media list
    func mediaEventOccured(_ event: MediaStoreChangeEvent, forStorageType storageType: StorageType? = nil) {
        guard mediaStore.published  else {
            // not published, set the media list to nil
            pendingChangeEvents = []
            update(newValue: nil)
            return
        }
        switch event {
        case .indexingStateChanged(oldState: let old, newState: let new):
            // if the new state is indexed then browse the whole media store
            if old != .indexed, new == .indexed {
                browse(storageType: storageType)
            }
        case .webSocketDisconnected:
            // browse media store when web socket disconnected or error occured
            browse(storageType: storageType)
        default:
            // while browsing there can be changes, keep them so they can be replayed after
            // the browsing ends
            if request != nil || self.value == nil {
                pendingChangeEvents.append(event)
            } else {
                let newList = process(event: event, medias: self.medias)
                update(newValue: newList)
            }
        }
    }

    /// Apply the change described by a `MediaStoreChangeEvent` to a given list of medias returning
    /// the resulting list of medias.
    ///
    /// - Parameters:
    ///   - event: the change event describing the change that occured.
    ///   - medias: the list to act upon.
    /// - Returns: a new list that reflects the change as described by the `event`.
    func process(event: MediaStoreChangeEvent, medias: [MediaItemCore]) -> [MediaItemCore] {
        var newList = medias
        switch event {
        case .allMediaRemoved:
            newList = []

        case .createdMedia(let newMedia):
            if storageType == nil || (storageType != nil && newMedia.resources.first?.storage == storageType),
               !newList.contains(newMedia) {
                newList.append(newMedia)
            }

        case .removedMedia(mediaId: let removedMediaId):
            newList.removeAll(where: { $0.uid == removedMediaId })

        case .createdResource(let newResource, mediaId: let mediaId):
            if storageType == nil || (storageType != nil && newResource.storage == storageType),
               let concernedMediaIndex = newList.firstIndex(where: { $0.uid == mediaId }) {
                newList[concernedMediaIndex] = newList[concernedMediaIndex].mediaWithResource(newResource)
            }

        case .removedResource(resourceId: let removedResourceId):
            if let concernedMediaIndex = newList.firstIndex(where: { (media: MediaItemCore) in
                media.resources.contains(where: { $0.uid == removedResourceId })
            }) {
                newList[concernedMediaIndex] = newList[concernedMediaIndex]
                    .mediaWithoutResource(removedResourceId)
            }
        default:
            break
        }
        return newList
    }

    func browse(storageType: StorageType?) {
        guard request == nil else { return }
        pendingChangeEvents = []
        request = mediaStore.backend.browse(storage: storageType, completion: { [weak self] medias in
            // weak self in case backend call callback after cancelling request
            guard let self = self else { return }
            self.request = nil
            var medias = medias
            // copy user data into the new items
            if let currentList = self.value as? [MediaItemCore] {
                for media in medias {
                    media.userData = currentList.first(where: {
                        $0.uid == media.uid
                    })?.userData
                }
            }
            self.pendingChangeEvents.forEach { event in
                medias = self.process(event: event, medias: medias)
            }
            self.pendingChangeEvents = []
            // update the ref with the new list
            self.update(newValue: medias)
        })
    }
}
