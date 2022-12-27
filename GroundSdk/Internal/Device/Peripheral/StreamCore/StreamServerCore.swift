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

/// Stream Source Backend.
public protocol StreamSourceBackend: AnyObject {
    /// Opens the source.
    func open()
}

/// Video stream server backend.
public protocol StreamServerBackend: AnyObject {

    /// 'true' when streaming is enabled.
    var enabled: Bool { get set }

    /// Creates a new MediaReplayCore instance to stream the given media source.
    func newMediaReplay(source: MediaSourceCore) -> MediaReplayCore

    /// Releases the given media replay stream.
    func releaseMediaReplay(stream: MediaReplayCore)

    /// Retrieves a camera live stream.
    ///
    /// There is only one live stream instance for each CameraLiveSource, which is shared among all open references.
    ///
    /// - Parameter source: the camera live source of the live stream to retrieve
    /// - Returns: the camera live stream researched
    func getCameraLive(source: CameraLiveSource) -> CameraLiveCore
}

/// Internal stream server peripheral implementation
public class StreamServerCore: PeripheralCore, StreamServer {

    /// Implementation backend.
    private unowned let backend: StreamServerBackend

    /// 'true' when streaming is enabled.
    private var _enabled = false

    /// Issued stream references.
    private let refs = [Ref<StreamCore>]()

    /// 'true' when streaming is enabled.
    public var enabled: Bool {
        get {
            return _enabled
        }
        set (enabled) {
            backend.enabled = enabled
        }
    }

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: Stream server backend
    public init(store: ComponentStoreCore, backend: StreamServerBackend) {
        self.backend = backend
        super.init(desc: Peripherals.streamServer, store: store)
    }

    /// Retrieves default live stream and registers an observer notified each time it changes.
    ///
    /// - Parameters:
    ///    - observer: observer notified each time this stream changes
    /// - Returns: reference to the default live stream
    public func live(observer: @escaping (CameraLive?) -> Void) -> Ref<CameraLive> {
        return live(source: CameraLiveSource.unspecified, observer: observer)
    }

    /// Retrieves live stream and registers an observer notified each time it changes.
    ///
    /// - Parameters:
    ///    - source: type of camera live source to stream
    ///    - observer: observer notified each time this stream changes
    /// - Returns: reference to the requested live stream
    public func live(source: CameraLiveSource, observer: @escaping (CameraLive?) -> Void) -> Ref<CameraLive> {
        return CameraLiveRefCore(observer: observer, stream: backend.getCameraLive(source: source))
    }

    /// Retrieves replay stream and registers an observer notified each time it changes.
    ///
    /// - Parameters:
    ///    - source: media replay source to stream
    ///    - observer: observer notified each time this stream changes
    /// - Returns: reference to the requested replay stream
    public func replay(source: MediaReplaySource, observer: @escaping (MediaReplay?) -> Void) -> Ref<MediaReplay>? {
        let stream = backend.newMediaReplay(source: source as! MediaSourceCore)
        return MediaReplayRefCore(observer: observer, stream: stream) { [weak self] in
            self?.backend.releaseMediaReplay(stream: stream)
        }
    }
}

/// Backend callback methods
extension StreamServerCore {

    /// Updates the streaming enabled flag.
    ///
    /// - Parameter enable: new streaming enabled flag
    /// - Returns: self to allow call chaining
    @discardableResult
    public func update(enable: Bool) -> StreamServerCore {
        if enable != _enabled {
            _enabled = enable
            markChanged()
            notifyUpdated()
        }
        return self
    }
}

/// Extension that implements the StreamServer protocol for the Objective-C API
extension StreamServerCore: GSStreamServer {

    public func live(source: CameraLiveSource,
                     observer: @escaping (_ stream: CameraLive?) -> Void) -> GSCameraLiveRef {
        return GSCameraLiveRef(ref: live(source: source, observer: observer))
    }

    public func replay(source: MediaReplaySource, observer: @escaping (MediaReplay?) -> Void) -> GSMediaReplayRef? {
        let ref: Ref<MediaReplay>? = replay(source: source, observer: observer)
        return ref != nil ? GSMediaReplayRef(ref: ref!) : nil
    }
}
