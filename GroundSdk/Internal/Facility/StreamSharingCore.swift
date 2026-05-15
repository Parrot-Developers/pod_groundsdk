// Copyright (C) 2024 Parrot Drones SAS
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

/// Engine-specific backend for StreamSharing.
protocol StreamSharingBackend: AnyObject {

    /// Controls stream sharing enabled state.
    ///
    /// - Parameter enable: `true` to enable stream sharing, `false` to disable it
    func enableStreaming(enable: Bool)

    /// Starts the stream recording service.
    ///
    /// - Parameters:
    ///   - directory: file system directory to write files to
    ///   - resolution: recorded video resolution
    ///   - bitrate: video encoder target bitrate, in bit/s; `0` for default value
    ///   - overlay: `true` to enable video overlay
    ///   - unitSystem: unit system of the overlay
    ///   - coordinateSystem: coordinate system of the overlay
    func startRecording(directory: URL, resolution: StreamSharingResolution, bitrate: Int, overlay: Bool,
                        unitSystem: OverlayUnitSystem, coordinateSystem: OverlayCoordinateSystem)

    /// Stops the stream recording service.
    func stopRecording()

    /// Starts the streaming service.
    ///
    /// - Parameters:
    ///   - url: URL to stream to
    ///   - resolution: streamed video resolution
    ///   - maxBitrate: video encoder maximum bitrate, in bit/s; `0` for default value
    ///   - overlay: `true` to enable video overlay
    ///   - unitSystem: unit system of the overlay
    ///   - coordinateSystem: coordinate system of the overlay
    ///   - rtspTransport: RTSP transport
    func startStreaming(url: URL, resolution: StreamSharingResolution, maxBitrate: Int, overlay: Bool,
                        unitSystem: OverlayUnitSystem, coordinateSystem: OverlayCoordinateSystem,
                        rtspTransport: StreamSharingRtspTransport)

    /// Stops the streaming service.
    func stopStreaming()
}

/// Recording implementation.
class RecordingCore: Recording {

    /// Stream sharing facility.
    private let streamSharing: StreamSharingCore

    var state: StreamRecordingState = .stopped

    var file: URL?

    var stopReason: StreamRecordingStopReason?

    /// Constructor.
    ///
    /// - Parameter streamSharing: stream sharing facility
    init(streamSharing: StreamSharingCore) {
        self.streamSharing = streamSharing
    }

    func start(directory: URL, resolution: StreamSharingResolution, bitrate: Int, overlay: Bool,
               unitSystem: OverlayUnitSystem, coordinateSystem: OverlayCoordinateSystem) -> Bool {
        guard streamSharing.enabled, state == .stopped else { return false }

        streamSharing.backend.startRecording(directory: directory, resolution: resolution, bitrate: bitrate,
                                             overlay: overlay, unitSystem: unitSystem,
                                             coordinateSystem: coordinateSystem)
        update(state: .starting)
        stopReason = nil
        streamSharing.notifyUpdated()
        return true
    }

    func stop() -> Bool {
        guard streamSharing.enabled, state == .started || state == .recording || state == .error else { return false }

        streamSharing.backend.stopRecording()
        update(state: .stopping)
        streamSharing.notifyUpdated()
        return true
    }

    /// Updates the recording state.
    ///
    /// - Parameter state: new recording state
    /// - Returns: self to allow call chaining
    @discardableResult
    func update(state newState: StreamRecordingState?) -> RecordingCore {
        if let newState, state != newState {
            state = newState
            streamSharing.markChanged()
        }
        return self
    }

    /// Updates the recording file.
    ///
    /// - Parameter file: new recording file
    /// - Returns: self to allow call chaining
    @discardableResult
    func update(file newFile: URL?) -> RecordingCore {
        if let newFile = newFile, file != newFile {
            file = newFile
            streamSharing.markChanged()
        }
        return self
    }

    /// Updates the recording stop reason.
    ///
    /// - Parameter stopReason: new recording stop reason
    /// - Returns: self to allow call chaining
    @discardableResult
    func update(stopReason newStopReason: StreamRecordingStopReason?) -> RecordingCore {
        if let newStopReason, stopReason != newStopReason {
            stopReason = newStopReason
            streamSharing.markChanged()
        }
        return self
    }
}

/// Streaming implementation.
class StreamingCore: Streaming {

    /// Stream sharing facility.
    private let streamSharing: StreamSharingCore

    var state: StreamingState = .stopped

    var error: StreamingError?

    var url: URL?

    /// Constructor.
    ///
    /// - Parameter streamSharing: stream sharing facility
    init(streamSharing: StreamSharingCore) {
        self.streamSharing = streamSharing
    }

    func start(url: URL, resolution videoResolution: StreamSharingResolution, maxBitrate: Int, overlay: Bool,
               unitSystem: OverlayUnitSystem, coordinateSystem: OverlayCoordinateSystem,
               rtspTransport: StreamSharingRtspTransport) -> Bool {
        guard streamSharing.enabled, state == .stopped else { return false }

        streamSharing.backend.startStreaming(url: url, resolution: videoResolution, maxBitrate: maxBitrate,
                                             overlay: overlay, unitSystem: unitSystem,
                                             coordinateSystem: coordinateSystem, rtspTransport: rtspTransport)
        update(state: .starting)
        error = nil
        streamSharing.notifyUpdated()
        return true
    }

    func stop() -> Bool {
        guard streamSharing.enabled, state == .started || state == .streaming || state == .error ||
                state == .connecting else { return false }

        streamSharing.backend.stopStreaming()
        update(state: .stopping)
        error = nil
        streamSharing.notifyUpdated()
        return true
    }

    /// Updates the streaming state.
    ///
    /// - Parameter state: new streaming state
    /// - Returns: self to allow call chaining
    @discardableResult
    func update(state newState: StreamingState) -> StreamingCore {
        if state != newState {
            state = newState
            streamSharing.markChanged()
        }
        return self
    }

    /// Updates the streaming error.
    ///
    /// - Parameter error: new streaming error
    /// - Returns: self to allow call chaining
    @discardableResult
    func update(error newError: StreamingError?) -> StreamingCore {
        if let newError = newError, error != newError {
            error = newError
            streamSharing.markChanged()
        }
        return self
    }

    /// Updates the streaming url.
    ///
    /// - Parameter url: the streaming url
    /// - Returns: self to allow call chaining
    @discardableResult
    func update(url newUrl: URL?) -> StreamingCore {
        if let newUrl = newUrl, url != newUrl {
            url = newUrl
            streamSharing.markChanged()
        }
        return self
    }
}

/// Internal stream sharing facility implementation.
class StreamSharingCore: FacilityCore, StreamSharing {

    var enabled: Bool {
        get {
            return _enabled
        }
        set (enabled) {
            guard enabled != _enabled else { return }

            backend.enableStreaming(enable: enabled)
            _enabled = enabled
            if !enabled {
                _recording.update(state: .stopped)
                _streaming.update(state: .stopped)
            }
            forceNotifyUpdated()
        }
    }

    var recording: Recording {
        return _recording
    }

    var streaming: Streaming {
        return _streaming
    }

    /// Internal implementation for stream sharing enabled state.
    private var _enabled = false

    /// Internal implementation for recording component.
    private(set) var _recording: RecordingCore!

    /// Internal implementation for streaming component.
    private(set) var _streaming: StreamingCore!

    /// Implementation backend.
    fileprivate unowned let backend: StreamSharingBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: component store owning this component
    ///   - backend: stream sharing backend
    init(store: ComponentStoreCore, backend: StreamSharingBackend) {
        self.backend = backend
        super.init(desc: Facilities.streamSharing, store: store)

        _recording = RecordingCore(streamSharing: self)
        _streaming = StreamingCore(streamSharing: self)
    }
}
