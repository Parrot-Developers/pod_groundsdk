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

/// Camera photo capture state.
public enum Camera2PhotoCaptureState: Equatable, CustomStringConvertible {
    /// Photo capture is stopped and ready to be operated.
    /// - latestSavedMediaId: identifier of latest saved media, or `nil` if no media was saved since connection
    case stopped(latestSavedMediaId: String?)

    /// Photo capture is starting.
    /// This state is entered from `stopped` after a call to `Camera2PhotoCapture.start()`.
    case starting

    /// Photo capture is started.
    /// - startTimeOnSystemClock: time when the capture did start, in seconds in the local device's default clock
    ///   reference; may be negative if the capture started before local device boot
    /// - duration: closure allowing to retrieve capture duration so far
    /// - photoCount: number of photo taken in the session
    /// - mediaStorage: destination storage for produced media, `nil` if unknown
    case started(startTimeOnSystemClock: Double, duration: () -> TimeInterval, photoCount: Int,
                 mediaStorage: StorageType?)

    /// Photo capture is stopping.
    /// - reason: reason why the photo capture is stopping
    /// - savedMediaId: identifier of saved media if any, otherwise `nil`
    case stopping(reason: StopReason, savedMediaId: String?)

    /// Photo capture stop reason.
    public enum StopReason: String, CustomStringConvertible {
        /// Photo capture has stopped automatically.
        case captureDone

        /// Photo captue has stopped on user request.
        case userRequest

        /// Photo capture has stopped because of a camera configuration change.
        case configurationChange

        /// Photo capture has stopped due to insufficient storage space on the drone.
        case errorInsufficientStorageSpace

        /// Photo capture has stopped due to an internal error.
        case errorInternal

        /// Debug description.
        public var description: String { rawValue }
    }

    /// Equatable.
    static public func == (lhs: Camera2PhotoCaptureState, rhs: Camera2PhotoCaptureState) -> Bool {
        switch (lhs, rhs) {
        case (let .stopped(latestSavedMediaIdL), let .stopped(latestSavedMediaIdR)):
            return latestSavedMediaIdL == latestSavedMediaIdR

        case (.starting, .starting):
            return true

        case (let started(startTimeOnSystemClockL, _, photoCountL, mediaStorageL),
              let started(startTimeOnSystemClockR, _, photoCountR, mediaStorageR)):
            return startTimeOnSystemClockL == startTimeOnSystemClockR
                && photoCountL == photoCountR && mediaStorageL == mediaStorageR

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
            return "stopped \(latestSavedMediaId ?? "")"
        case .starting:               return "starting"
        case let .started(startTimeOnSystemClock, duration, photoCount, mediaStorage):
            return "started \(startTimeOnSystemClock), \(duration()), \(photoCount), "
                + String(describing: mediaStorage)
        case let .stopping(reason, savedMediaId):
            return "stopping \(reason), \(savedMediaId ?? "none")"
        }
    }

    /// Whether photo capture can be started.
    public var canStart: Bool {
        switch self {
        case .stopped:
            return true
        default:
            return false
        }
    }

    /// Whether photo capture can be stopped.
    public var canStop: Bool {
        switch self {
        case .starting, .started:
            return true
        default:
            return false
        }
    }
}

/// Camera photo capture component.
public protocol Camera2PhotoCapture: Component {

    /// Photo capture state.
    var state: Camera2PhotoCaptureState { get }

    /// Starts photo capture.
    func start()

    /// Stops photo capture.
    func stop()
}

/// :nodoc:
/// Camera2PhotoCapture description
public class Camera2PhotoCaptureDesc: NSObject, Camera2ComponentClassDesc {
    public typealias ApiProtocol = Camera2PhotoCapture
    public let uid = Camera2ComponentUid.photoCapture.rawValue
    public let parent: ComponentDescriptor? = nil
}
