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

/// Utility protocol allowing to manage stream sharing.
public protocol StreamSharingManager: UtilityCore {

    /// Tells whether recording service or streaming service is currently started.
    var serviceStarted: Bool { get }

    /// Starts stream sharing backend.
    func start()

    /// Stops stream sharing backend.
    func stop()

    /// Sets the native SdkCoreStream.
    ///
    /// - Parameter sdkCoreStream: the SdkCoreStream
    func setStream(sdkCoreStream: ArsdkStream?)

    /// Starts the stream recording service.
    ///
    /// - Parameters:
    ///   - mediaDir: file system directory to write files to
    ///   - privateDir: file system directory to write private files to
    ///   - resolution: recorded video resolution
    ///   - bitrate: video encoder target bitrate, in bit/s; `0` for default value
    ///   - overlay: `true` to enable video overlay
    ///   - unitSystem: unit system of the overlay
    ///   - coordinateSystem: coordinate system of the overlay
    func startRecording(mediaDir: URL, privateDir: URL, resolution: StreamSharingResolution,
                        bitrate: Int, overlay: Bool, unitSystem: OverlayUnitSystem,
                        coordinateSystem: OverlayCoordinateSystem)

    /// Stops the stream recording service.
    func stopRecording()

    /// Finalizes current record
    func finalizeRecord(reason: ArsdkStreamRecordStopReason)

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

    /// Informs the overlayer that a recording started or stopped.
    ///
    /// - Parameters:
    ///   - recording: `true` if recording is started on drone
    ///   - duration: current recording capture duration
    func setRecordingState(recording: Bool, duration: TimeInterval)

    /// Informs the overlayer about the current recording mode.
    ///
    /// - Parameters:
    ///   - resolution: recording resolution
    ///   - framerate: recording framerate
    ///   - isThermal: `true` if thermal mode is enabled
    func setRecordingFormat(resolution: ArsdkStreamOverlayResolution, framerate: Float, isThermal: Bool)

    /// Informs the overlayer about the current battery level of the controller.
    ///
    /// - Parameter level: battery level
    func setControllerBatteryLevel(level: Int)

    /// Starts monitoring this utility.
    ///
    /// - Parameters:
    ///    - didEnable: called back when stream sharing is enabled
    ///    - serviceDidStart: called back when stream recording service or streaming service is started
    ///    - recordingStateDidChange: called back when recording state changes
    ///    - streamingStateDidChange: called back when streaming state changes
    func startMonitoring(didEnable: @escaping () -> Void,
                         serviceDidStart: @escaping () -> Void,
                         recordingStateDidChange: @escaping (StreamRecordingState?, _ file: URL?,
                                                             _ reason: StreamRecordingStopReason?) -> Void,
                         streamingStateDidChange: @escaping (StreamingState, _ error: StreamingError?,
                                                        _ url: URL?) -> Void)
    -> MonitorCore
}

/// Stream sharing utility description.
public class StreamSharingManagerCoreDesc: NSObject, UtilityCoreApiDescriptor {
    public typealias ApiProtocol = StreamSharingManager
    public let uid = UtilityUid.streamSharingManager.rawValue
}
