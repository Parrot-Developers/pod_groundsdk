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

/// Reasons why an animation may be unavailable.
@objc(GSAnimationIssue)
public enum AnimationIssue: Int, CustomStringConvertible {

    /// Drone is not flying.
    case droneNotFlying
    /// Drone is not calibrated.
    case droneNotCalibrated
    /// Drone gps is not fixed or has a poor accuracy.
    case droneGpsInfoInaccurate
    /// Drone is too close to the target.
    case droneTooCloseToTarget
    /// Drone is too close to the ground.
    case droneTooCloseToGround
    /// Target gps is not fixed or has a poor accuracy.
    case targetGpsInfoInaccurate
    /// Target barometer data are missing.
    case targetBarometerInfoInaccurate
    /// External target detection information is missing.
    case targetDetectionInfoMissing
    /// Drone is above max altitude.
    case droneAboveMaxAltitude
    /// Drone is outside of the geofence.
    case droneOutOfGeofence
    /// Drone is too far from target.
    case droneTooFarFromTarget
    /// Target horizontal speed is too high.
    case targetHorizontalSpeedKO
    /// Target vertical speed is too high.
    case targetVerticalSpeedKO
    /// Target altitude has a bad accuracy.
    case targetAltitudeAccuracyKO

    /// Debug description.
    public var description: String {
        switch self {
        case .droneNotFlying:                   return "droneNotFlying"
        case .droneNotCalibrated:               return "droneNotCalibrated"
        case .droneGpsInfoInaccurate:           return "droneGpsInfoInaccurate"
        case .droneTooCloseToTarget:            return "droneTooCloseToTarget"
        case .droneTooCloseToGround:            return "droneTooCloseToGround"
        case .targetGpsInfoInaccurate:          return "targetGpsInfoInaccurate"
        case .targetBarometerInfoInaccurate:    return "targetBarometerInfoInaccurate"
        case .targetDetectionInfoMissing:       return "targetDetectionInfoMissing"
        case .droneAboveMaxAltitude:            return "droneAboveMaxAltitude"
        case .droneOutOfGeofence:               return "droneOutOfGeofence"
        case .droneTooFarFromTarget:            return "droneTooFarFromTarget"
        case .targetHorizontalSpeedKO:          return "targetHorizontalSpeedKO"
        case .targetVerticalSpeedKO:            return "targetVerticalSpeedKO"
        case .targetAltitudeAccuracyKO:         return "targetAltitudeAccuracyKO"
        }
    }
}

/// Piloting mode in which an animation may be available.
@objc(GSPilotingMode)
public enum PilotingMode: Int, CustomStringConvertible {

    /// Manual
    case manual
    /// Follow me.
    case followMe
    /// Look at
    case lookAt
    /// Flight Plan
    case flightPlan
    /// Point of interest
    case poi

    /// Debug description.
    public var description: String {
        switch self {
        case .manual:                   return "manual"
        case .followMe:                 return "followMe"
        case .lookAt:                   return "lookAt"
        case .flightPlan:               return "flightPlan"
        case .poi:                      return "poi"

        }
    }
}

/// Animation piloting interface.
///
/// This piloting interface cannot be activated or deactivated. It is present as soon as a drone supporting animations
/// is connected. It is removed as soon as the drone is disconnected.
///
/// According to different parameters, the list of available animations can change.
/// These parameters can be (not exhaustive):
/// - Current activated piloting interface
/// - Information about the controller (such as location)
/// - Internal state of the drone (such as battery level, gps fix...)
///
/// This piloting interface can be retrieved by:
/// ```
/// drone.getPilotingItf(animation)
/// ```
public protocol AnimationPilotingItf: PilotingItf {

    /// Set of currently available animations.
    var availableAnimations: Set<AnimationType> { get }

    /// Currently executing animation.
    /// `nil` if no animation is playing.
    var animation: Animation? { get }

    /// Availability issues for each animation.
    ///
    /// - Note: If there is no issue for an animation, it doesn't mean it is available.
    /// It needs to be in the right mode (See supportedAnimations).
    /// - Note: not supported by all drone models, it will always return an empty set in that case.
    var availabilityIssues: [AnimationType: Set<AnimationIssue>]? { get }

    /// Animations supported for each piloting mode.
    ///
    /// - Note: not supported by all drone models, it will always return an empty set in that case.
    var supportedAnimations: [PilotingMode: Set<AnimationType>]? { get }

    /// Starts an animation.
    ///
    /// - Parameter config: configuration of the animation to execute
    /// - Returns: `true` if an animation request was sent to the drone, `false` otherwise
    func startAnimation(config: AnimationConfig) -> Bool

    /// Aborts any currently executing animation.
    ///
    /// - Returns: `true` if an animation cancellation request was sent to the drone, `false` otherwise
    func abortCurrentAnimation() -> Bool
}

/// Animation piloting interface.
///
/// This piloting interface cannot be activated or deactivated. It is present as soon as a drone supporting animations
/// is connected. It is removed as soon as the drone is disconnected.
///
/// According to different parameters, the list of available animation can change.
/// These parameters can be (not exhaustive):
/// - Current activated piloting interface
/// - Information about the controller (such as location)
/// - Internal state of the drone (such as battery level, gps fix...)
///
/// This peripheral can be retrieved by:
/// ```
/// (id<AnimationPilotingItf>) [drone getPilotingItf:GSPilotingItfs.animation]
/// ```
///
/// - Note: this protocol is for Objective-C only. Swift must use the protocol `AnimationPilotingItf`.
@objc
public protocol GSAnimationPilotingItf: PilotingItf {

    /// Currently executing animation.
    /// `nil` if no animation is playing
    var animation: Animation? { get }

    /// Tells whether the given animation type is currently available on the drone.
    ///
    /// - Parameter animation: the animation type to query
    /// - Returns: `true` if this type of animation is currently available
    func isAnimationAvailable(_ animation: AnimationType) -> Bool

    /// Tells whether the animation has the corresponding issue.
    ///
    /// - Parameters:
    ///     - animation: the animation type to query
    ///     - requierement: requierement to fix
    /// - Note: If there is no issue for an animation, it doesn't mean it is available.
    /// It needs to be in the right mode.
    func isIssuePresent(_ animation: AnimationType, requierement: AnimationIssue) -> Bool

    /// Tells whether the animation is supported for a piloting mode.
    ///
    /// - Parameters:
    ///     - animation: the animation type to query
    ///     - mode: piloting mode
    func isAnimationSupported(animation: AnimationType, mode: PilotingMode) -> Bool

    /// Starts an animation.
    ///
    /// - Parameter config: configuration of the animation to execute
    /// - Returns: `true` if an animation request was sent to the drone, `false` otherwise
    func startAnimation(config: AnimationConfig) -> Bool

    /// Aborts any currently executing animation.
    ///
    /// - Returns: `true` if an animation cancellation request was sent to the drone, `false` otherwise
    func abortCurrentAnimation() -> Bool
}

/// :nodoc:
/// Animation piloting interface description
@objc(GSAnimationPilotingItfs)
public class AnimationPilotingItfs: NSObject, PilotingItfClassDesc {
    public typealias ApiProtocol = AnimationPilotingItf
    public let uid = PilotingItfUid.animation.rawValue
    public let parent: ComponentDescriptor? = nil
}
