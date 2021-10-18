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

/// Tracking state.
public enum TrackingState: Int, CustomStringConvertible {

    /// Target is currently tracked by the drone.
    case tracked

    /// Target has been lost, but the drone is trying to find it again.
    case lost

    /// Debug description.
    public var description: String {
        switch self {
        case .tracked:  return "tracked"
        case .lost: return "lost"
        }
    }
}

/// Tracking engine state.
public enum TrackingEngineState: Int, CustomStringConvertible {

    /// Drone has already activated the tracking engine.
    case droneActivated

    /// Tracking engine is available.
    case available

    /// Tracking engine is activated.
    case activated

    /// Debug description.
    public var description: String {
        switch self {
        case .droneActivated:  return "droneActivated"
        case .available: return "available"
        case .activated: return "activated"
        }
    }
}

/// Request status.
public enum RequestStatus: Int, CustomStringConvertible {
    /// Tracking request was processed.
    case processed

    /// Tracking request was not processed, tracker is at full capacity. The request is dropped.
    case droppedTargetLimitReached

    /// Target was not found. The request is dropped.
    case droppedNotFound

    /// The request is dropped due to an unknown error.
    case droppedUnknownError

    /// Debug description.
    public var description: String {
        switch self {
        case .processed:                 return "processed"
        case .droppedTargetLimitReached: return "droppedTargetLimitReached"
        case .droppedNotFound:           return "droppedNotFound"
        case .droppedUnknownError:       return "droppedUnknownError"
        }
    }
}

/// Tracked target.
public class Target: NSObject {

    /// Id of the target
    public internal(set) var targetId: UInt

    /// Cookie of the target defined previously by user.
    public internal(set) var cookie: UInt

    /// Tracking state.
    public internal(set) var state: TrackingState

    /// Constructor.
    ///
    /// - Parameters:
    ///    - targetId: id of the target.
    ///    - cookie: cookie given by user to the target
    ///    - state: tracking state
    public init(targetId: UInt, cookie: UInt, state: TrackingState) {
        self.targetId = targetId
        self.cookie = cookie
        self.state = state
    }
}

/// Request for target tracking.
public protocol TrackingRequest {
    /// Cookie.
    ///
    /// This cookie will be returned by cookie in Target.
    var cookie: UInt { get set }
}

/// Peripheral managing onboard tracker.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.onboardTracker)
/// ```
public protocol OnboardTracker: Peripheral {

    /// Creates a request to add a target to track from a rectangle in the video.
    ///
    /// - Parameters:
    ///     - timestamp: timestamp of the video frame
    ///     - horizontalPosition: horizontal position of the top left corner's target in the video, in range [0, 1]
    ///     - verticalPosition: vertical position of the top left corner's target in the video, in range [0, 1]
    ///     - width: width of target in the video, in range [0, 1]
    ///     - height: height of target in the video, in range [0, 1]
    /// - Returns: a new tracking request
    func ofRect(timestamp: UInt64, horizontalPosition: Float, verticalPosition: Float, width: Float,
                       height: Float) -> TrackingRequest

    /// Creates a request to add a target to track from a proposal id.
    ///
    /// - Parameters:
    ///     - timestamp: timestamp of the video frame
    ///     - proposalId: id of the proposal given by the drone
    /// - Returns: a new tracking request
    func ofProposal(timestamp: UInt64, proposalId: UInt) -> TrackingRequest

    /// Adds a new target to track.
    ///
    /// - Parameter trackingRequest: the tracking request
    func addNewTarget(trackingRequest: TrackingRequest)

    /// Replaces current targets by a new target.
    ///
    /// - Parameter trackingRequest: the tracking request
    func replaceAllTargetsBy(trackingRequest: TrackingRequest)

    /// Remove all targets.
    func removeAllTargets()

    /// Start tracking engine.
    ///
    ///  - Parameter boxProposals: true to use box proposals, false without
    func startTrackingEngine(boxProposals: Bool)

    /// Stop tracking engine.
    func stopTrackingEngine()

    /// State of activation of tracking engine.
    var trackingEngineState: TrackingEngineState { get }

    /// Remove specific target from tracking.
    ///
    /// - Parameters:
    ///   - targetId: id of the target given by the drone
    func removeTarget(targetId: UInt)

    /// Gets the targets currently managed by the drone.
    ///
    /// This is a dictionary of [id: TrackingObject]
    var targets: [UInt: Target] { get }

    /// Gets the latest request status returned by the drone in response to a tracking request.
    ///
    /// This method shall be used to get the response returned by the drone after calls to addNewTarget,
    /// replaceAllTargetsBy, removeAllTargets, or removeTarget.
    /// The returned status is transient. The returned value will change back to nil immediately after
    /// request, status is notified.
    var requestStatus: RequestStatus? { get }

    /// Tells if tracking feature is available.
    var isAvailable: Bool { get }
}

/// :nodoc:
/// Onboard tracker description.
public class OnboardTrackerDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = OnboardTracker
    public let uid = PeripheralUid.onboardTracker.rawValue
    public let parent: ComponentDescriptor? = nil
}
