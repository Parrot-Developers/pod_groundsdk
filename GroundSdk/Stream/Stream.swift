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

/// Stream state.
@objc(GSStreamState)
public enum StreamState: Int, CustomStringConvertible {
    /// Stream is stopped.
    ///
    /// In this state, specific stream child interfaces do not provide any meaningful playback state information.
    case stopped

    /// Stream is suspended.
    ///
    /// In this state, specific stream child interfaces inform about the playback state that the stream will try
    /// to recover once it can start again.
    ///
    /// Note that only `CameraLive` stream supports suspension.
    case suspended

    /// Stream is starting.
    ///
    /// In this state, specific stream child interfaces inform about the playback state that the stream will try
    /// to apply once it is fully started.
    case starting

    /// Stream is started.
    ///
    /// In this state, specific stream child interfaces inform about the stream's current playback state.
    case started

    /// Debug description.
    public var description: String {
        switch self {
        case .stopped:
            return "stopped"
        case .suspended:
            return "suspended"
        case .starting:
            return "starting"
        case .started:
            return "started"
        }
    }
}

/// Stream sink interface.
@objc(GSStreamSinkConfig)
public protocol StreamSinkConfig {
}

/// Stream sink interface.
@objc(GSStreamSink)
public protocol StreamSink {
}

/// Base stream interface.
@objc(GSStream)
public protocol Stream: AnyObject {

    /// Current state.
    var state: StreamState { get }

    /// Opens a sink on the stream.
    ///
    /// - Parameter config: sink configuration
    /// - Returns: the opened sink
    func openSink(config: StreamSinkConfig) -> StreamSink

}
