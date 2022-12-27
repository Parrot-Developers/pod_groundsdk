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

/// SinkCore Handler
/// Used to close sinkCore when StreamSinkCore is deinit.
public class StreamSinkCore: StreamSink {

    /// SinkCore handled
    weak var sinkCore: SinkCore?

    /// Constructor
    ///
    /// - Parameter sinkCore: sinkCore handled
    init(sinkCore: SinkCore) {
        self.sinkCore = sinkCore
    }

    /// Destructor
    deinit {
        sinkCore?.close()
    }
}

/// Stream play state.
public enum StreamPlayState: Int {
    /// Stream stopped, nothing reserved on the drone.
    case stopped
    /// Stream paused, pipeline ready on the drone.
    case paused
    /// Stream Playing, drone sentds frames.
    case playing

    /// Description.
    public var description: String {
        switch self {
        case .stopped: return "stopped"
        case .paused: return "paused"
        case .playing: return "playing"
        }
    }
}

/// Stream backend.
public protocol StreamCoreBackend {

    /// If `false` the stream is forced to stop regardless of the `state`,
    /// if `true` the stream is enabled and the `state` is effective.
    var enabled: Bool { get set }

    /// Stream play state
    var state: StreamPlayState { get }

    /// Plays the stream.
    func play()

    /// Pauses the stream.
    func pause()

    /// Seeks to a time position.
    ///
    /// - Parameter position: position to seek, in seconds
    func seek(position: Int)

    /// Stops the stream.
    func stop()

    /// Creates a new `SinkCore` on the stream with given `config`.
    ///
    /// - Parameter config: sink configuration
    /// - Returns: the opened sink
    func newSink(config: SinkCoreConfig) -> SinkCore
}

/// Internal Stream implementation.
public class StreamCore: NSObject, Stream {

    /// Track name of default video
    public static let TRACK_DEFAULT_VIDEO: String = "" // or "DefaultVideo"
    /// Track name of thermal video
    public static let TRACK_THERMAL_VIDEO: String = "ParrotThermalVideo"

    /// Listener notified when the stream changes.
    class Listener: NSObject {

        /// Closure called when the stream changes.
        fileprivate let didChange: () -> Void

        /// Closure called to unpublished the stream.
        fileprivate let unpublish: () -> Void

        /// Constructor.
        ///
        /// - Parameters:
        ///    - didChange: closure that should be called when the state changes
        ///    - unpublish: closure that should be called to unpublish the stream
        fileprivate init(didChange: @escaping () -> Void, unpublish: @escaping () -> Void) {
            self.didChange = didChange
            self.unpublish = unpublish
        }
    }

    /// Video stream backend, nil when closed.
    var backend: StreamCoreBackend!

    /// Current stream state.
    public var state: StreamState = .stopped

    /// Listeners list.
    private var listeners: Set<Listener> = []

    /// Whether this stream has changed.
    var changed = false

    /// 'true' when this stream has been released.
    private var released = false

    /// Destructor.
    deinit {
        unpublish()
        listeners.removeAll()
    }

    /// Open a sink on the stream.
    ///
    /// - Parameter config: sink configuration
    /// - Returns: the opened sink
    public func openSink(config: StreamSinkConfig) -> StreamSink {
        let config = config as! SinkCoreConfig
        let sinkCore = backend.newSink(config: config)
        return StreamSinkCore(sinkCore: sinkCore)
    }

    /// Register a new listener.
    ///
    /// - Parameters:
    ///    - didChange: closure that should be called when the state changes
    ///    - unpublish: closure that should be called to unpublish the stream
    /// - Returns: the created listener
    ///
    /// - Note: the returned listener should be unregistered with unregister()
    func register(didChange: @escaping () -> Void, unpublish: @escaping () -> Void) -> Listener {
        let listener = Listener(didChange: didChange, unpublish: unpublish)
        listeners.insert(listener)
        return listener
    }

    /// Unregister a listener.
    ///
    /// - Parameter listener: listener to unregister
    func unregister(listener: Listener) {
        listeners.remove(listener)
    }

    /// Get number of registered listeners.
    ///
    /// Only for testing purpose.
    ///
    /// - Returns: number of registered listeners
    func countListeners() -> Int {
        return listeners.count
    }

    /// Notifies all observers of stream state change, iff state did change since last call to this method.
    public func notifyUpdated() {
        if changed {
            changed = false
            listeners.forEach {
                $0.didChange()
            }
        }
    }

    /// Unpublish the stream.
    private func unpublish() {
        listeners.forEach {
            $0.unpublish()
        }
    }

    /// Stops the stream.
    public func stop() {
        if released {
            ULog.w(.streamTag, "stop failed: stream already released.")
            return
        }

        backend.stop()
    }

    /// Releases the stream.
    ///
    /// Stream must not be used after this method is called.
    public func releaseStream() {
        if released {
            ULog.w(.streamTag, "release failed: stream already released.")
            return
        }
        released = true
        unpublish()
        listeners.removeAll()
    }

    /// Notifies that the stream playback starts.
    /// Subclasses may override this method to properly update their own state.
    func onStart() {}

    /// Notifies that the stream playback stops.
    /// Subclasses may override this method to properly update their own state.
    func onStop() {}

    /// Notifies that this stream is about to be suspended.
    /// Subclasses may override this method to properly update their own state.
    func onSuspension() {}

    /// Notifies that the stream playback state changed.
    ///
    /// Subclasses may override this method to properly update their own state.
    ///
    /// - Parameters:
    ///    - duration: stream duration, in milliseconds, 0 when irrelevant
    ///    - position: playback position, in milliseconds
    ///    - speed: playback speed (multiplier), 0 when paused
    ///    - timestamp: state collection timestamp, based on time provided by 'ProcessInfo.processInfo.systemUptime'
    func onPlaybackStateChanged(duration: Int64, position: Int64, speed: Double, timestamp: TimeInterval) {}

    /// Notifies that the stream play state changed.
    ///
    /// Subclasses may override this method to properly update their own state.
    ///
    /// - Parameter playState: stream play state
    func onPlayStateChanged(playState: StreamPlayState) {}
}

/// Backend callback methods.
extension StreamCore {

    /// Updates current stream state.
    ///
    /// - Parameter state: new stream state
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func update(state: StreamState) -> StreamCore {
        if state != self.state {
            self.state = state
            changed = true
            if state == .started {
                onStart()
            } else if state == .stopped {
                onStop()
            } else if state == .suspended {
                onSuspension()
            }
        }
        return self
    }

    /// Notifies that the stream play state changed.
    ///
    /// - Parameter playState: stream play state
    public func streamPlayStateDidChange(playState: StreamPlayState) {
        onPlayStateChanged(playState: playState)
    }

    /// Notifies that the stream playback state changed.
    ///
    /// - Parameters:
    ///    - duration: stream duration, in milliseconds, 0 when irrelevant
    ///    - position: playback position, in milliseconds
    ///    - speed: playback speed (multiplier), 0 when paused
    ///    - timestamp: state collection timestamp, based on time provided by 'ProcessInfo.processInfo.systemUptime'
    public func streamPlaybackStateDidChange(duration: Int64, position: Int64, speed: Double, timestamp: TimeInterval) {
        onPlaybackStateChanged(duration: duration,
                               position: position,
                               speed: speed,
                               timestamp: timestamp)
    }
}

/// TextureLoaderFrame backend part.
public protocol TextureLoaderFrameBackend: AnyObject {
    /// Handle on the frame.
    var frame: UnsafeRawPointer? {get}

    /// Handle on the frame user data.
    var userData: UnsafeRawPointer? {get}

    /// Length of the frame user data.
    var userDataLen: Int {get}
}

/// Internal TextureLoaderFrame implementation.
public class TextureLoaderFrameCore: TextureLoaderFrame {

    /// Implementation backend.
    private let backend: TextureLoaderFrameBackend

    /// Handle on the frame.
    public var frame: UnsafeRawPointer? {
        return backend.frame
    }

    /// Handle on the frame user data.
    public var userData: UnsafeRawPointer? {
        return backend.userData
    }

    /// Length of the frame user data.
    public var userDataLen: Int {
        return backend.userDataLen
    }

    /// Handle on  media information.
    public var mediaInfo: UnsafeRawPointer?

    /// Constructor
    ///
    /// - Parameter backend: texture loader frame backend
    public init(backend: TextureLoaderFrameBackend) {
        self.backend = backend
    }
}

/// Histogram backend part.
public protocol HistogramBackend: AnyObject {

    /// Histogram channel red.
    var histogramRed: [Float32]? {get}

    /// Histogram channel green.
    var histogramGreen: [Float32]? {get}

    /// Histogram channel blue.
    var histogramBlue: [Float32]? {get}

    /// Histogram channel luma.
    var histogramLuma: [Float32]? {get}
}

/// Internal histogram implementation.
public class HistogramCore: Histogram {

    /// Implementation backend.
    private let backend: HistogramBackend

    /// Histogram channel red.
    public var histogramRed: [Float32]? {
        return backend.histogramRed
    }

    /// Histogram channel green.
    public var histogramGreen: [Float32]? {
        return backend.histogramGreen
    }

    /// Histogram channel blue.
    public var histogramBlue: [Float32]? {
        return backend.histogramBlue
    }

    /// Histogram channel luma.
    public var histogramLuma: [Float32]? {
        return backend.histogramLuma
    }

    /// Constructor
    ///
    /// - Parameter backend: histogram backend
    public init(backend: HistogramBackend) {
        self.backend = backend
    }
}

/// Overlay context backend part.
public protocol OverlayContextBackend: AnyObject {
    /// Area where the frame was rendered (including any padding introduced by scaling).
    var renderZone: CGRect {get}

    /// Render zone handle.
    var renderZoneHandle: UnsafeRawPointer {get}

    /// Area where frame content was rendered (excluding any padding introduced by scaling)
    var contentZone: CGRect {get}

    /// Render zone handle.
    var contentZoneHandle: UnsafeRawPointer {get}

    /// Media Info handle
    var mediaInfoHandle: UnsafeRawPointer {get}

    /// Frame metadata handle.
    var frameMetadataHandle: UnsafeRawPointer? {get}

    /// Histogram.
    var histogram: Histogram? {get}
}

/// Internal context implementation.
public class OverlayContextCore: OverlayContext {

    /// Implementation backend.
    private let backend: OverlayContextBackend

    public var renderZone: CGRect {
        return backend.renderZone
    }

    public var renderZoneHandle: UnsafeRawPointer {
        return backend.renderZoneHandle
    }

    public var contentZone: CGRect {
        return backend.contentZone
    }

    public var contentZoneHandle: UnsafeRawPointer {
        return backend.contentZoneHandle
    }

    public var mediaInfoHandle: UnsafeRawPointer {
        return backend.mediaInfoHandle
    }

    public var frameMetadataHandle: UnsafeRawPointer? {
        return backend.frameMetadataHandle
    }

    public var histogram: Histogram? {
        return backend.histogram
    }

    /// Constructor
    ///
    /// - Parameter backend: histogram backend
    public init(backend: OverlayContextBackend) {
        self.backend = backend
    }
}
