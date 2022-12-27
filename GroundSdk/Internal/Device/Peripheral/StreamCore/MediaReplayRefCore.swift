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

/// MediaReplay Reference implementation
class MediaReplayRefCore: Ref<MediaReplay> {

    /// Media replay stream instance
    private var stream: MediaReplayCore? {
        value as? MediaReplayCore
    }

    /// Media replay stream listener
    private var streamListener: MediaReplayCore.Listener!

    /// Action to execute to release the stream when the reference is released; no-op by default
    private let releaseStream: () -> Void

    /// Constructor
    ///
    /// - Parameters:
    ///   - observer: observer notified of state change
    ///   - stream: media replay stream instance
    ///   - releaseStream: action to execute to release the stream when the reference is released; no-op by default
    init(observer: @escaping Observer, stream: MediaReplayCore, releaseStream: @escaping () -> Void = {}) {
        self.releaseStream = releaseStream
        super.init(observer: observer)
        // register ourself on change notifications
        streamListener = stream.register(
            didChange: { [unowned self] in
                // update stream
                self.update(newValue: stream)
            },
            unpublish: { [unowned self] in
                // unpublish stream
                self.update(newValue: nil)
        })
        setup(value: stream)
    }

    /// Destructor
    deinit {
        stream?.unregister(listener: streamListener)
        releaseStream()
    }
}
