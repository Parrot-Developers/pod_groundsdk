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

class MediaDeleterRefCore: Ref<MediaDeleter>, MediaOperationRef {

    /// Media store instance
    private let mediaStore: MediaStoreCore
    /// active delete request
    private(set) var request: CancelableCore?

    /// Constructor
    ///
    /// - Parameters:
    ///   - mediaStore: media store instance
    ///   - mediaResources: list of media resources to delete
    ///   - observer: observer notified when of delete progress
    init(mediaStore: MediaStoreCore, mediaResources: MediaResourceList, observer: @escaping Observer) {
        self.mediaStore = mediaStore
        super.init(observer: observer)
        if let mediaResources = mediaResources as? MediaResourceListCore {
            request = mediaStore.backend.delete(mediaResources: mediaResources) { [weak self] mediaDeleter in
                // weak self in case backend call callback after cancelling request
                if let `self` = self {
                    `self`.update(newValue: mediaDeleter)
                }
            }
        }
    }

    /// destructor
    deinit {
        cancel()
    }

    /// Cancels the request
    public func cancel() {
        request?.cancel()
        request = nil
    }
}

class AllMediasDeleterRefCore: Ref<AllMediasDeleter>, MediaOperationRef {

    /// Media store instance
    private let mediaStore: MediaStoreCore
    /// active delete request
    private(set) var request: CancelableCore?

    /// Constructor
    ///
    /// - Parameters:
    ///   - mediaStore: media store instance
    ///   - observer: observer notified when of delete progress
    init(mediaStore: MediaStoreCore, observer: @escaping Observer) {
        self.mediaStore = mediaStore
        super.init(observer: observer)
        request = mediaStore.backend.deleteAll { [weak self] mediaDeleter in
            // weak self in case backend call callback after cancelling request
            guard let self = self else { return }
            self.update(newValue: mediaDeleter)
        }
    }

    /// destructor
    deinit {
        cancel()
    }

    /// Cancels the request
    func cancel() {
        request?.cancel()
        request = nil
    }
}
