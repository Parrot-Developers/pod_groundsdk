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
import CoreLocation

/// Reasons why a return home may be unavailable.
@objc(GSReturnHomeIssue)
public enum ReturnHomeIssue: Int, CustomStringConvertible {

    /// Drone is not flying.
    case droneNotFlying
    /// Drone is not calibrated.
    case droneNotCalibrated
    /// Drone gps is not fixed or has a poor accuracy.
    case droneGpsInfoInaccurate

    /// Debug description.
    public var description: String {
        switch self {
        case .droneNotFlying:                   return "droneNotFlying"
        case .droneNotCalibrated:               return "droneNotCalibrated"
        case .droneGpsInfoInaccurate:           return "droneGpsInfoInaccurate"
        }
    }
}

/// Home reachability.
///
/// Describes whether the return point can be reached by the drone or not.
@objc(GSHomeReachability)
public enum HomeReachability: Int, CustomStringConvertible {
    /// Home reachability is unknown.
    case unknown
    /// Home is reachable.
    case reachable
    /// The drone has planned an automatic safety return. Return Home will start after `autoTriggerDelay`. This delay
    /// of the RTH is calculated so that the return trip can be made before the battery is emptied.
    case warning
    /// Home is still reachable but won't be if return home is not triggered now. If return home is running, cancelling
    /// it will probably make the home not reachable.
    case critical
    /// Home is not reachable.
    case notReachable

    /// Debug description.
    public var description: String {
        switch self {
        case .unknown:      return "unknown"
        case .reachable:    return "reachable"
        case .warning:      return "warning"
        case .critical:     return "critical"
        case .notReachable: return "notReachable"
        }
    }
}

/// Return home destination target.
@objc(GSReturnHomeTarget)
public enum ReturnHomeTarget: Int, CustomStringConvertible {
    /// No home type. This might be because the drone does not have a gps fix
    case none
    /// Return to take-off position.
    case takeOffPosition
    /// Return to the entered custom position.
    case customPosition
    /// Return to current controller position.
    case controllerPosition
    /// Return to latest tracked target position during/after FollowMe piloting interface is/has been activated.
    /// See `TargetTracker` peripheral and `FollowMePilotingItf`
    case trackedTargetPosition

    /// Debug description.
    public var description: String {
        switch self {
        case .none:                  return "none"
        case .takeOffPosition:       return "takeOffPosition"
        case .customPosition:        return "customPosition"
        case .controllerPosition:    return "controllerPosition"
        case .trackedTargetPosition: return "trackedTargetPosition"
        }
    }

    /// Set containing all possible values of return home target.
    public static let allCases: Set<ReturnHomeTarget> = [.none, .takeOffPosition, .customPosition, .controllerPosition,
                                                  .trackedTargetPosition]
}

/// Return Home ending behavior
@objc(GSReturnHomeEndingBehavior)
public enum ReturnHomeEndingBehavior: Int, CustomStringConvertible, CaseIterable {
    /// Ending behavior for return home is landing.
    case landing
    /// Ending behavior for return home is hovering. In this behavior, you must use endingHoveringAltitude
    case hovering

    /// Debug description.
    public var description: String {
        switch self {
        case .landing:          return "endingBehaviorLanding"
        case .hovering:         return "endingBehaviorHovering"
        }
    }
}

/// Reason why return home has been started or stopped.
@objc(GSReturnHomeReason)
public enum ReturnHomeReason: Int, CustomStringConvertible, CaseIterable {
    /// Return home is not active.
    case none
    /// Return home requested by user.
    case userRequested
    /// Returning home because the connection was lost.
    case connectionLost
    /// Returning home because the power level is low.
    case powerLow
    /// Return home is finished and is not active anymore.
    case finished
    /// Return to home could not find a path to home.
    case blocked

    /// Debug description.
    public var description: String {
        switch self {
        case .none:             return "none"
        case .userRequested:    return "userRequested"
        case .connectionLost:   return "connectionLost"
        case .powerLow:         return "powerLow"
        case .finished:         return "finished"
        case .blocked:          return "blocked"
        }
    }
}

/// Preferred return home target. Drone will select this target if all conditions for it are met.
@objc(GSReturnHomePreferredTarget)
public protocol ReturnHomePreferredTarget {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Preferred return home target. Drone will choose the selected target if all condition to use it are met.
    var target: ReturnHomeTarget { get set }
}

/// Return home ending behavior. Drone will end its Return Home by this behavior.
@objc(GSReturnHomeEnding)
public protocol ReturnHomeEnding {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Return home ending behavior. Drone will end its Return Home using this behavior.
    var behavior: ReturnHomeEndingBehavior { get set }
}

/// Piloting interface used to make the drone return to home.
///
/// This piloting interface can be retrieved by:
/// ```
/// drone.getPilotingItf(PilotingItfs.returnHome)
/// ```
public protocol ReturnHomePilotingItf: PilotingItf, ActivablePilotingItf {

    /// Set of reasons why this piloting interface is unavailable.
    ///
    /// Empty when state is `.idle` or `.active`.
    var unavailabilityReasons: Set<ReturnHomeIssue>? { get }

    /// Return Home mode for auto trigger.
    /// This setting permit to enable or diable auto triggered return home
    var autoTriggerMode: BoolSetting? { get }

    /// Reason why the return home is active or not.
    var reason: ReturnHomeReason { get }

    /// Current home location, `nil` if unknown.
    var homeLocation: CLLocation? { get }

    /// Current return home target. May be different from the one selected by preferredTarget if the requirement
    /// of the selected target are not met.
    var currentTarget: ReturnHomeTarget { get }

    /// If current target is `TakeOffPosition`, indicates if the first GPS fix was made before or after takeoff.
    /// If the first fix was made after take off, the drone will return at this first fix position that
    /// may be different from the takeoff position
    var gpsWasFixedOnTakeOff: Bool { get }

    /// Return home target settings, to select if the drone should return to its take-off position or to the
    /// current pilot position.
    var preferredTarget: ReturnHomePreferredTarget { get }

    /// Return home ending behavior settings, to select if the drone will end its return home by
    /// landing or hovering.
    var endingBehavior: ReturnHomeEnding { get }

    /// Minimum return home altitude in meters, relative to the take off point. If the drone is below this altitude
    /// when starting its return home, it will first reach the minimum altitude. If it is higher than this minimum
    /// altitude, it will operate its return home at its actual.
    /// `nil` if not supported by the drone.
    var minAltitude: DoubleSetting? { get }

    /// Return home ending hovering altitude in meters, relative to the take off point.
    /// `nil` if not supported by the drone.
    var endingHoveringAltitude: DoubleSetting? { get }

    /// Delay before starting return home when the controller connection is lost, in seconds.
    var autoStartOnDisconnectDelay: IntSetting { get }

    /// Estimation of the possibility for the drone to reach its return point.
    var homeReachability: HomeReachability { get }

    /// Delay in seconds before the drone starts an automatic return home when `homeReachability` is `.warning`,
    /// meaningless otherwise.
    /// This delay is computed by the drone to allow it to reach its home position before the battery is empty.
    var autoTriggerDelay: TimeInterval { get }

    /// Activates this piloting interface.
    ///
    /// If successful, it deactivates the current piloting interface and activate this one.
    ///
    /// - Returns: `true` on success, `false` if the piloting interface can't be activated
    func activate() -> Bool

    /// Cancels any current auto trigger.
    /// If `homeReachability` is `.warning`, this cancels the planned return home.
    func cancelAutoTrigger()

    /// Set a custom location to the drone.
    /// This location will be used by the drone for the rth
    ///
    /// If this method is called while the preferredTarget is not set to `customPosition`,
    /// it will do nothing
    ///
    /// - Parameters:
    ///   - latitude: latitude of the location (in degrees) to reach
    ///   - longitude: longitude of the location (in degrees) to reach
    ///   - altitude: altitude above ground level (in meters) to reach
    func setCustomLocation(latitude: Double, longitude: Double, altitude: Double)
}

@objc
public protocol GSReturnHomePilotingItf: PilotingItf, ActivablePilotingItf {
    /// Tells whether a given reason is partly responsible of the unavailable state of this piloting interface.
    ///
    /// - Parameter reason: the reason to query
    /// - Returns: `true` if the piloting interface is partly unavailable because of the given reason.
    func hasUnavailabilityReason(_ reason: ReturnHomeIssue) -> Bool

    /// Return Home mode for auto trigger.
    /// This setting permit to enable or diable auto triggered return home
    var autoTriggerMode: BoolSetting? { get }

    /// Reason why the return home is active or not.
    var reason: ReturnHomeReason { get }

    /// Current home location, `nil` if unknown.
    var homeLocation: CLLocation? { get }

    /// Current return home target. May be different from the one selected by preferredTarget if the requirement
    /// of the selected target are not met.
    var currentTarget: ReturnHomeTarget { get }

    /// If current target is `TakeOffPosition`, indicates if the first GPS fix was made before or after takeoff.
    /// If the first fix was made after take off, the drone will return at this first fix position that
    /// may be different from the takeoff position
    var gpsWasFixedOnTakeOff: Bool { get }

    /// Return home target settings, to select if the drone should return to its take-off position or to the
    /// current pilot position.
    var preferredTarget: ReturnHomePreferredTarget { get }

    /// Return home ending behavior settings, to select if the drone will end its return home by
    /// landing or hovering.
    var endingBehavior: ReturnHomeEnding { get }

    /// Minimum return home altitude in meters, relative to the take off point. If the drone is below this altitude
    /// when starting its return home, it will first reach the minimum altitude. If it is higher than this minimum
    /// altitude, it will operate its return home at its actual.
    /// `nil` if not supported by the drone.
    var minAltitude: DoubleSetting? { get }

    /// Return home ending hovering altitude in meters, relative to the take off point.
    /// `nil` if not supported by the drone.
    var endingHoveringAltitude: DoubleSetting? { get }

    /// Delay before starting return home when the controller connection is lost, in seconds.
    var autoStartOnDisconnectDelay: IntSetting { get }

    /// Estimation of the possibility for the drone to reach its return point.
    var homeReachability: HomeReachability { get }

    /// Delay in seconds before the drone starts an automatic return home when `homeReachability` is `.warning`,
    /// meaningless otherwise.
    /// This delay is computed by the drone to allow it to reach its home position before the battery is empty.
    var autoTriggerDelay: TimeInterval { get }

    /// Activates this piloting interface.
    ///
    /// If successful, it deactivates the current piloting interface and activate this one.
    ///
    /// - Returns: `true` on success, `false` if the piloting interface can't be activated
    func activate() -> Bool

    /// Cancels any current auto trigger.
    /// If `homeReachability` is `.warning`, this cancels the planned return home.
    func cancelAutoTrigger()

    /// Set a custom location to the drone.
    /// This location will be used by the drone for the rth
    ///
    /// If this method is called while the preferredTarget is not set to `customPosition`,
    /// it will do nothing
    ///
    /// - Parameters:
    ///   - latitude: latitude of the location (in degrees) to reach
    ///   - longitude: longitude of the location (in degrees) to reach
    ///   - altitude: altitude above ground level (in meters) to reach
    func setCustomLocation(latitude: Double, longitude: Double, altitude: Double)
}

/// :nodoc:
/// Return home piloting interface description
@objc(GSReturnHomePilotingItfs)
public class ReturnHomePilotingItfs: NSObject, PilotingItfClassDesc {
    public typealias ApiProtocol = ReturnHomePilotingItf
    public let uid = PilotingItfUid.returnHome.rawValue
    public let parent: ComponentDescriptor? = nil
}
