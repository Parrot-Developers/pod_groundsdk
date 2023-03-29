// Copyright (C) 2021 Parrot Drones SAS
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

/// ResourceUploader Reference implementation.
class ResourceUploaderRefCore: Ref<ResourceUploader>, MediaOperationRef {

    /// Active upload request.
    private(set) var request: CancelableCore?

    /// Constructor.
    ///
    /// - Parameters:
    ///   - mediaStore: media store instance
    ///   - resources: resource files to upload
    ///   - target: target media item to attach uploaded resource files to
    ///   - observer: observer notified of upload progress and status
    init(mediaStore: MediaStoreCore, resources: [URL], target: MediaItemCore, observer: @escaping Observer) {
        super.init(observer: observer)
        self.request = mediaStore.backend
            .upload(resources: resources, target: target) { [weak self] resourceUploader in
                // weak self in case backend call callback after cancelling request
                guard let self = self else { return }
                self.update(newValue: resourceUploader)
            }
    }

    /// Destructor.
    deinit {
        cancel()
    }

    /// Cancels the request
    public func cancel() {
        request?.cancel()
        request = nil
    }
}
