// Copyright (C) 2020 Parrot Drones SAS
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

/// Camera recording state.
public enum Camera2RecordingState: Equatable, CustomStringConvertible {
    /// Recording is stopped and ready to be started.
    /// - latestSavedMediaId: identifier of latest saved media, or `nil` if no media was saved since connection
    case stopped(latestSavedMediaId: String?)

    /// Recording is starting.
    /// This state is entered from `stopped` after a call to `Camera2Recording.start()`.
    case starting

    /// Recording is started.
    /// - startTimeOnSystemClock: time when the capture did start, in seconds in the local device's default clock
    ///   reference; may be negative if the capture started before local device boot
    /// - duration: closure allowing to retrieve capture duration so far
    /// - videoBitrate: video recording bitrate, in bits per second
    /// - mediaStorage: destination storage for produced media, `nil` if unknown
    case started(startTimeOnSystemClock: Double, duration: () -> TimeInterval,
                 videoBitrate: UInt, mediaStorage: StorageType?)

    /// Recording is stopping.
    /// - reason: reason why the recording is stopping
    /// - savedMediaId: identifier of saved media if any, otherwise `nil`
    case stopping(reason: StopReason, savedMediaId: String?)

    /// Recording stop reason.
    public enum StopReason: String, CustomStringConvertible {
        /// Recording has stopped on user request.
        case userRequest

        /// Recording has stopped because of a camera configuration change.
        case configurationChange

        /// Recording has stopped due to insufficient storage space on the drone.
        case errorInsufficientStorageSpace

        /// Recording has stopped because storage is too slow.
        case errorInsufficientStorageSpeed

        /// Recording has stopped due to an internal error.
        case errorInternal

        /// Debug description.
        public var description: String { rawValue }
    }

    /// Equatable.
    static public func == (lhs: Camera2RecordingState, rhs: Camera2RecordingState) -> Bool {
        switch (lhs, rhs) {
        case (let .stopped(latestSavedMediaIdL), let .stopped(latestSavedMediaIdR)):
            return latestSavedMediaIdL == latestSavedMediaIdR

        case (.starting, .starting):
            return true

        case (let started(startTimeOnSystemClockL, _, videoBitrateL, mediaStorageL),
              let started(startTimeOnSystemClockR, _, videoBitrateR, mediaStorageR)):
            return startTimeOnSystemClockL == startTimeOnSystemClockR
                && mediaStorageL == mediaStorageR && videoBitrateL == videoBitrateR

        case (let stopping(reasonL, savedMediaIdL), let stopping(reasonR, savedMediaIdR)):
            return reasonL == reasonR && savedMediaIdL == savedMediaIdR

        default:
            return false
        }
    }

    /// Debug description.
    public var description: String {
        switch self {
        case let .stopped(latestSavedMediaId):
            return "stopped \(latestSavedMediaId ?? "none")"
        case .starting:
            return "starting"
        case let .started(startTimeOnSystemClock, duration, videoBitrate, mediaStorage):
            return "started \(startTimeOnSystemClock), \(duration()), \(videoBitrate) "
                + String(describing: mediaStorage)
        case let .stopping(reason, savedMediaId):
            return "stopping \(reason), \(savedMediaId ?? "none")"
        }
    }

    /// Whether recording can be started.
    public var canStart: Bool {
        switch self {
        case .stopped:
            return true
        default:
            return false
        }
    }

    /// Whether recording can be stopped.
    public var canStop: Bool {
        switch self {
        case .starting, .started:
            return true
        default:
            return false
        }
    }
}

/// Camera recording component.
public protocol Camera2Recording: Component {

    /// Current recording state.
    var state: Camera2RecordingState { get }

    /// Starts recording.
    func start()

    /// Stops recording.
    func stop()
}

/// :nodoc:
/// Camera2Recording description.
public class Camera2RecordingDesc: NSObject, Camera2ComponentClassDesc {
    public typealias ApiProtocol = Camera2Recording
    public let uid = Camera2ComponentUid.recording.rawValue
    public let parent: ComponentDescriptor? = nil
}
