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

/// Video resolution.
public enum StreamSharingResolution: CaseIterable {

    /// 1920x1080 pixels (Full HD).
    case res1080p

    /// 1280x720 pixels (HD).
    case res720p

    /// 864x480 pixels.
    case res480p

    /// 640x360 pixels.
    case res360p

    /// 432x240 pixels.
    case res240p
}

/// RTSP transport.
public enum StreamSharingRtspTransport: CaseIterable {

    /// UDP transport protocol.
    case udp

    /// TCP transport protocol.
    case tcp
}

/// Stream sharing overlay unit system
public enum OverlayUnitSystem: CaseIterable {

    /// Metric unit system.
    case metric

    /// Imperial unit system.
    case imperial

    /// Aviation unit system.
    case aviation
}

/// Stream sharing overlay coordinate system
public enum OverlayCoordinateSystem: CaseIterable {

    /// DMS coordinate system.
    case dms

    /// DD coordinate system.
    case dd

    /// MGRS coordinate system.
    case mgrs

    /// UTM coordinate system.
    case utm

    /// SK-42 coordinate system.
    case sk42
}

/// Stream recording service state.
public enum StreamRecordingState {

    /// Service is stopped.
    case stopped

    /// Service is starting.
    case starting

    /// Service is started, no recording in progress.
    case started

    /// Stream recording is in progress.
    case recording

    /// Service is stopping.
    case stopping

    /// An error occured; service is still running but no recording is in progress.
    case error
}

/// Stream recording stop reason
public enum StreamRecordingStopReason {

    /// Unknown error.
    case unknown

    /// User request.
    case userRequest

    /// Record aborted
    case aborted

    /// Peer shutdown
    case peerShutdown

    /// Session changed, triggering a new record
    case newSessionRestart

    /// Restart triggered due to internal reason
    case internalRestart

    /// No space left
    case noSpaceLeft

    /// Internal error
    case internalError
}

/// Streaming service state.
public enum StreamingState {

    /// Service is stopped.
    case stopped

    /// Service is starting.
    case starting

    /// Service is started, no streaming in progress.
    case started

    /// Service is connecting.
    case connecting

    /// Streaming is in progress.
    case streaming

    /// Serivice is stopping.
    case stopping

    /// An unrecoverable error occurred; service should be stopped, then it can be started again.
    case error
}

/// Streaming service error.
public enum StreamingError: String, CustomStringConvertible {

    /// Unknown error.
    case unknown

    /// Client requested the disconnection.
    case clientRequest

    /// Server requested the disconnection.
    case serverRequest

    /// Connection failed due to network error.
    case networkError

    /// Connection refused by the server.
    case refused

    /// Another client is using this connection.
    case alreadyInUse

    /// Connection to streaming server timed out.
    case timeout

    /// Internal error.
    case internalError

    /// Stream URL is invalid.
    case invalidUrl

    public var description: String { rawValue }
}

/// Stream recording component.
public protocol Recording {

    /// Current stream recording state.
    var state: StreamRecordingState { get }

    /// Current or latest completed recording file.
    var file: URL? { get }

    /// Latest stream recording stop reason.
    var stopReason: StreamRecordingStopReason? { get }

    /// Starts the stream recording service.
    ///
    /// - Parameters:
    ///   - directory: file system directory to write files to
    ///   - resolution: recorded video resolution
    ///   - bitrate: video encoder target bitrate, in bit/s; `0` for default value
    ///   - overlay: `true` to enable video overlay
    ///   - unitSystem: unit system of the overlay
    ///   - coordinateSystem: coordinate system of the overlay
    /// - Returns: `true` if recording service will effectively start, otherwise `false`
    func start(directory: URL, resolution: StreamSharingResolution, bitrate: Int, overlay: Bool,
               unitSystem: OverlayUnitSystem, coordinateSystem: OverlayCoordinateSystem) -> Bool

    /// Stops the stream recording service.
    ///
    /// - Returns: `true` if recording service will effectively stop, otherwise `false`
    func stop() -> Bool
}

/// Streaming component.
public protocol Streaming {

    /// Current streaming state.
    var state: StreamingState { get }

    /// Latest raised error.
    var error: StreamingError? { get }

    /// Current stream URL.
    var url: URL? { get }

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
    /// - Returns: `true` if streaming service will effectively start, otherwise `false`
    func start(url: URL, resolution: StreamSharingResolution, maxBitrate: Int, overlay: Bool,
               unitSystem: OverlayUnitSystem, coordinateSystem: OverlayCoordinateSystem,
               rtspTransport: StreamSharingRtspTransport) -> Bool

    /// Stops the streaming service.
    ///
    /// - Returns: `true` if streaming will effectively stop, otherwise `false`
    func stop() -> Bool
}

/// Facility that provides control of stream sharing feature.
public protocol StreamSharing: Facility {

    /// Provides control of stream sharing activation.
    var enabled: Bool { get set }

    /// Provides access to stream recording component.
    var recording: Recording { get }

    /// Provides access to streaming component.
    var streaming: Streaming { get }
}

/// StreamSharing facility descriptor
public class StreamSharingDesc: NSObject, FacilityClassDesc {
    public typealias ApiProtocol = StreamSharing
    public let uid = FacilityUid.streamSharing.rawValue
    public let parent: ComponentDescriptor? = nil
}
