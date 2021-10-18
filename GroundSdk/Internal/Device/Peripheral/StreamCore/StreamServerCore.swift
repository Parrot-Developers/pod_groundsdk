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

    /// Retrieves live stream backend.
    ///
    /// - Parameters:
    ///    - cameraType: camera type of the live stream to open
    ///    - stream: stream owner of the backend
    /// - Returns: a new live stream backend
    func getStreamBackendLive(cameraType: CameraLiveSource, stream: StreamCore) -> StreamBackend

    /// Retrieves media stream backend.
    ///
    /// - Parameters:
    ///    - url: url of the media stream to open
    ///    - trackName: track name of the stream to open
    ///    - stream: stream owner of the backend
    /// - Returns: a new media stream backend
    func getStreamBackendMedia(url: String, trackName: String?, stream: StreamCore) -> StreamBackend

    /// Registers a stream.
    ///
    /// - Parameter stream: stream to register
    func register(stream: StreamCore)

    /// Unregisters a stream.
    ///
    /// - Parameter stream: stream to unregister
    func unregister(stream: StreamCore)

    /// Retrieves a camera live stream.
    ///
    /// - Parameter source: the camera live source of the live stream to retrieve
    /// - Returns: the camera live stream researched or `nil` if there not already exists
    func getCameraLive(source: CameraLiveSource) -> CameraLiveCore?
}

/// Internal stream server peripheral implementation
public class StreamServerCore: PeripheralCore, StreamServer {

    /// Implementation backend.
    private unowned let backend: StreamServerBackend

    /// 'true' when streaming is enabled.
    private var _enabled = false

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
        return CameraLiveRefCore(observer: observer, stream: getCameraLive(source: source))
    }

    /// Retrieves replay stream and registers an observer notified each time it changes.
    ///
    /// - Parameters:
    ///    - source: media replay source to stream
    ///    - observer: observer notified each time this stream changes
    /// - Returns: reference to the requested replay stream
    public func replay(source: MediaReplaySource, observer: @escaping (MediaReplay?) -> Void) -> Ref<MediaReplay>? {
        return MediaReplayRefCore(observer: observer,
                                  stream: newMediaReplay(source: source as! MediaSourceCore))
    }

    /// Get shared camera live stream
    ///
    /// - Parameter resource: live source to be streamed
    /// - Returns: shared camera live stream instance
    func getCameraLive(source: CameraLiveSource) -> CameraLiveCore {
        if let live = backend.getCameraLive(source: source) {
            return live
        } else {
            return CameraLiveCore(source: source, server: self)
        }
    }

    /// Create a new media replay stream
    ///
    /// - Parameter resource: media source to be streamed
    /// - Returns: a new media replay stream instance
    func newMediaReplay(source: MediaSourceCore) -> MediaReplayCore {
        return MediaReplayCore(server: self, source: source)
    }

    /// Retrieves live stream backend.
    ///
    /// - Parameters:
    ///    - cameraType: camera type of the live stream to open
    ///    - stream: stream owner of the backend
    /// - Returns: a new live stream backend
    func getStreamBackendLive(cameraType: CameraLiveSource, streamCore: StreamCore) -> StreamBackend {
        return backend.getStreamBackendLive(cameraType: cameraType, stream: streamCore)
    }

    /// Retrieves media stream backend.
    ///
    /// - Parameters:
    ///    - url: url of the media stream to open
    ///    - trackName: track name of the stream to open
    ///    - stream: stream owner of the backend
    /// - Returns: a new media stream backend
    func getStreamBackendMedia(url: String, trackName: String?, streamCore: StreamCore) -> StreamBackend {
        return backend.getStreamBackendMedia(url: url, trackName: trackName, stream: streamCore)
    }

    /// Register a stream.
    ///
    /// - Parameter stream: stream to register
    func register(stream: StreamCore) {
        backend.register(stream: stream)
    }

    /// Unregister a stream.
    ///
    /// - Parameter stream: stream to unregister
    func unregister(stream: StreamCore) {
        backend.unregister(stream: stream)
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
