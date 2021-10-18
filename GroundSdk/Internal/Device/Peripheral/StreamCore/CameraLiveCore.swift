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

/// Core class for CameraLive.
public class CameraLiveCore: StreamCore, CameraLive {

    /// Stream server managing the stream.
    private unowned let server: StreamServerCore

    /// Camera live source being played back.
    public let source: CameraLiveSource

    /// Current camera live playback state.
    public var playState: CameraLivePlayState = .none

    /// Constructor
    ///
    /// - Parameters:
    ///    - source: live source to stream
    ///    - server: stream server
    public init(source: CameraLiveSource, server: StreamServerCore) {
        self.source = source
        self.server = server
        super.init()
        self.backend = server.getStreamBackendLive(cameraType: source, streamCore: self)
        self.server.register(stream: self)
    }

    public func play() -> Bool {
        backend.play()
        return true
    }

    public func pause() -> Bool {
        backend.pause()
        return true
    }

    override public func stop() {
        super.stop()
    }

    public override func interrupt() {
        backend.enabled = false
    }

    /// Resume live stream if interrupted.
    public override func resume() {
        backend.enabled = true
    }

    override func onRelease() {
        server.unregister(stream: self)
    }

    override func onPlayStateChanged(playState: StreamPlayState) {
        switch playState {
        case .stopped:
            update(playState: .none).notifyUpdated()
        case .paused:
            update(playState: .paused).notifyUpdated()
        case .playing:
            update(playState: .playing).notifyUpdated()
        }
    }
}

extension CameraLiveCore {

    /// Updates current playback state.
    ///
    /// - Parameter state: new playback state
    /// - Returns: self to allow call chaining
    @discardableResult
    public func update(playState: CameraLivePlayState) -> CameraLiveCore {
        if playState != self.playState {
            self.playState = playState
            changed = true
        }
        return self
    }
}
