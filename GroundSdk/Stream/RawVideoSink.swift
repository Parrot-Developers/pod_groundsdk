// Copyright (C) 2022 Parrot Drones SAS
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

/// A frame data plane.
public protocol RawVideoSinkFramePlane {

    /// Plane binary data.
    var data: Data { get }

    /// Plane stride, in bytes.
    var stride: UInt64 { get }
}

/// A frame delivered by the sink.
public protocol RawVideoSinkFrame {

    /// Copies this frame.
    ///
    /// Copied instance and its data are completely separate from the source and MUST be released
    /// independently when not used anymore, otherwise its memory will be leaked.
    ///
    /// Note however that the copy is guaranteed to be backed by native heap memory, and not by hardware/decoder
    /// buffers (as may be the case with `RawVideoSinkFrame` instances that are delivered directly to the
    /// `RawVideoSinkListener.frameReady`).
    /// Thus, a frame copy can be kept unreleased for as long as needed by the client and will never cause a video
    /// pipeline stall/crash.
    ///
    /// - Returns a new frame copy.
    func copy() -> RawVideoSinkFrame

    /// Native pointer on to the `struct mbuf_raw_video_frame` C structure which is this frame native backend.
    ///
    /// - important: This pointer remains valid until this frame is released.
    var nativePtr: UnsafeMutableRawPointer { get }

    /// Frame data planes.
    ///
    /// Depending on the format `VideoFormat.Raw` (reported by `RawVideoSinkListener.didStart` callback),
    /// the frame may be constituted of up to 4 data planes.
    ///
    /// - important: Planes pointers remains valid until this frame is released.
    var planes: [RawVideoSinkFramePlane] { get }

    /// Frame timestamp, in timeScale units.
    var timestamp: UInt64 { get }

    /// Time timestamp scale, in Hz.
    var timeScale: UInt { get }

    /// Capture time of the frame, in microseconds on the monotonic clock of the drone, or `0` if unknown.
    var captureTimestamp: UInt64 { get }

    /// `true` when the frame is not intended to be displayed.
    ///
    /// This flag is usually applied during a pipeline initialization to the first few frames.
    /// Such frames are not intended to be displayed nor used for vision algorithms, but may still carry
    /// interesting metadata.
    var silent: Bool { get }

    /// `true` when the frame contains a visual error.
    ///
    /// This flag indicates that the frame is valid, but may contain visual errors.
    /// A frame with this flag can be displayed, but should not be used for vision algorithms.
    var visualError: Bool { get }

    /// Frame metadata.
    var metadata: Vmeta_TimedMetadata? { get }
}

/// Raw video sink listener.
public protocol RawVideoSinkListener: AnyObject {

    /// Notifies that the `sink` starts.
    ///
    /// - Parameter sink: raw video sink
    /// - Parameter videoFormat: provides information on the format of the delivered frames
    func didStart(sink: RawVideoSink, videoFormat: VideoFormat)

    /// Delivers a `frame` to the `sink`.
    ///
    /// Client owns the delivered frame and MUST release it when no longer needed, otherwise its memory will
    /// be leaked.
    ///
    /// In addition, `Frame` instances that are delivered directly to the sink through this callback may be backed
    /// by hardware/decoder buffers and not by usual native heap memory.
    /// Thus, it is important to release those frames as fast as possible, to prevent any video pipeline
    /// stall/crash.
    ///
    /// In case a longer processing time is required on the frame, consider working on a `Frame.copy` and `release`
    /// the delivered frame immediately.
    ///
    /// - Parameters:
    ///   - sink: raw video sink
    ///   - frame: new frame available
    func frameReady(sink: RawVideoSink, frame: RawVideoSinkFrame)

    /// Notifies that the `sink` stops.
    ///
    /// - Parameter sink: raw video sink
    func didStop(sink: RawVideoSink)
}

/// A `Stream` sink that delivers raw video frames.
public protocol RawVideoSink: StreamSink {
}

/// Raw video sink configuration.
public class RawVideoSinkConfig: SinkCoreConfig {

    /// Dispatch queue into which callbacks are dispatched.
    public let dispatchQueue: DispatchQueue

    /// Size of the frame queue; `0` for unlimited queue, otherwise older frames will be automatically dropped when
    /// the queue is full to make room for new frames.
    public let frameQueueSize: UInt

    /// Sink listener.
    public private(set) weak var listener: RawVideoSinkListener?

    /// Constructor with unlimited frame queue
    ///
    /// - Parameters:
    ///    - dispatchQueue: dispatch queue into which callbacks are dispatched
    ///    - listener: sink listener
    public init(dispatchQueue: DispatchQueue, listener: RawVideoSinkListener) {
        self.dispatchQueue = dispatchQueue
        self.frameQueueSize = 0
        self.listener = listener
    }

    /// Constructor
    ///
    /// - Parameters:
    ///    - dispatchQueue: dispatch queue into which callbacks are dispatched
    ///    - frameQueueSize: size of the frame queue; `0` for unlimited queue,
    ///      otherwise older frames will be automatically dropped when the queue is full to make room for new frames
    ///    - listener: sink listener
    public init(dispatchQueue: DispatchQueue, frameQueueSize: UInt, listener: RawVideoSinkListener) {
        self.dispatchQueue = dispatchQueue
        self.frameQueueSize = frameQueueSize
        self.listener = listener
    }
}
