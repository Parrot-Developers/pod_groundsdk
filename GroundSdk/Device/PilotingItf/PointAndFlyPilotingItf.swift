// Copyright (C) 2023 Parrot Drones SAS
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

/// Gimbal control mode during a point'n'fly execution.
public enum PointAndFlyGimbalControlMode: String, CustomStringConvertible, CaseIterable {
    /// Gimbal is locked on the target point.
    case locked
    /// Gimbal is locked on the target point until its pitch is manually changed.
    case lockedOnce
    /// Gimbal is freely controllable.
    case free

    /// Debug description.
    public var description: String { return rawValue }
}

/// Reasons why point'n'fly piloting interface may be unavailable.
public enum PointAndFlyIssue: String, CustomStringConvertible, CaseIterable {
    /// Drone is not flying.
    case droneNotFlying
    /// Drone is not calibrated.
    case droneNotCalibrated
    /// Drone gps is not fixed or has a poor accuracy.
    case droneGpsInfoInaccurate
    /// Drone is outside of the geofence.
    case droneOutOfGeofence
    /// Drone is too close to the ground.
    case droneTooCloseToGround
    /// Drone is above max altitude.
    case droneAboveMaxAltitude
    /// Not enough battery.
    case insufficientBattery

    /// Debug description.
    public var description: String { return rawValue }
}

/// Execution status of a *point* or *fly* directive.
public enum PointAndFlyExecutionStatus: String, CustomStringConvertible, CaseIterable {
    /// Directive execution did complete successfully (*fly*).
    case success
    /// Directive failed to execute or to complete successfully.
    case failed
    /// Directive execution was interrupted, either by user (`deactivate`, `execute` request) or by the drone.
    case interrupted

    /// Debug description.
    public var description: String { return rawValue }
}

/// Heading of the drone during a `FlyDirective`.
public enum PointAndFlyHeading: Equatable, CustomStringConvertible {

    /// The drone keeps its current heading.
    case current

    /// The drone rotates towards target before moving to said target.
    case toTargetBefore

    /// The drone rotates to given heading before moving to target.
    /// The parameter is the heading relative to the North in degrees (clockwise).
    case customBefore(Double)

    /// The drone rotates to given heading while moving to target.
    /// The parameter is the heading relative to the North in degrees (clockwise).
    case customDuring(Double)

    /// Equatable.
    static public func == (lhs: PointAndFlyHeading, rhs: PointAndFlyHeading) -> Bool {
        switch (lhs, rhs) {
        case (.current, .current):
            return true
        case (.toTargetBefore, .toTargetBefore):
            return true
        case (let .customBefore(headingL), let .customBefore(headingR)):
            return headingL == headingR
        case (let .customDuring(headingL), let .customDuring(headingR)):
            return headingL == headingR
        default:
            return false
        }
    }

    /// Debug description.
    public var description: String {
        switch self {
        case .current: return "current"
        case .toTargetBefore: return "toTargetBefore"
        case .customBefore(let heading): return "customBefore \(heading)"
        case .customDuring(let heading): return "customDuring \(heading)"
        }
    }
}

/// A point'n'fly directive.
public class PointAndFlyDirective: Equatable, CustomStringConvertible {
    /// Latitude of the target point location (in degrees).
    public let latitude: Double

    /// Longitude of the target point location (in degrees).
    public let longitude: Double

    /// Altitude above sea level of the target point (in meters).
    public let altitude: Double

    /// Gimbal control mode.
    public let gimbalControlMode: PointAndFlyGimbalControlMode

    /// Constructor.
    ///
    /// - Parameters:
    ///   - latitude: target point latitude
    ///   - longitude: target point longitude
    ///   - altitude: target point altitude
    ///   - gimbalControlMode: gimbal control mode
    fileprivate init(latitude: Double, longitude: Double, altitude: Double,
                     gimbalControlMode: PointAndFlyGimbalControlMode) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.gimbalControlMode = gimbalControlMode
    }

    public static func == (lhs: PointAndFlyDirective, rhs: PointAndFlyDirective) -> Bool {
        lhs.isEqual(other: rhs)
    }

    /// Compares with another PointAndFlyDirective instance.
    ///
    /// - Parameter other: PointAndFlyDirective instance to compare with
    /// - Returns: `true` if the two instances are equal, `false` otherwise
    /// - Note: Subclasses should override this function.
    public func isEqual(other: PointAndFlyDirective?) -> Bool {
        latitude == other?.latitude
        && longitude == other?.longitude
        && altitude == other?.altitude
        && gimbalControlMode == other?.gimbalControlMode
    }

    /// Debug description.
    public var description: String {
        return "lat(\(latitude))-lon(\(longitude))-alt(\(altitude))-gim(\(gimbalControlMode))"
    }
}

/// A directive requesting the drone to point at a given location.
///
/// While the *point* directive is executing, the drone constantly points at the target but can be piloted normally.
/// However, yaw value is not settable.
public class PointDirective: PointAndFlyDirective {

    /// Constructor.
    ///
    /// - Parameters:
    ///   - latitude: target point latitude
    ///   - longitude: target point longitude
    ///   - altitude: target point altitude
    ///   - gimbalControlMode: gimbal control mode
    public override init(latitude: Double, longitude: Double, altitude: Double,
                         gimbalControlMode: PointAndFlyGimbalControlMode) {
        super.init(latitude: latitude, longitude: longitude, altitude: altitude, gimbalControlMode: gimbalControlMode)
    }

    public override func isEqual(other: PointAndFlyDirective?) -> Bool {
        guard let other = other as? PointDirective else {
            return false
        }

        return super.isEqual(other: other)
    }
}

/// A directive requesting the drone to move to a given location.
///
/// - Note: The provided speed values are considered maximum values: the drone will try its best to respect the
///         specified speeds, but the actual speeds may be lower depending on the situation.
///         Specifying incoherent values with regard to the specified location target will result in a failed move.
public class FlyDirective: PointAndFlyDirective {

    /// Horizontal speed, in meters per second.
    public let horizontalSpeed: Double

    /// Vertical speed, in meters per second.
    public let verticalSpeed: Double

    /// Yaw rotation speed, in degrees per second.
    public let yawRotationSpeed: Double

    /// Drone heading.
    public let heading: PointAndFlyHeading

    /// Constructor.
    ///
    /// - Parameters:
    ///   - latitude: target point latitude
    ///   - longitude: target point longitude
    ///   - altitude: target point altitude
    ///   - gimbalControlMode: gimbal control mode
    ///   - horizontalSpeed: maximum horizontal speed
    ///   - verticalSpeed: maximum vertical speed
    ///   - yawRotationSpeed: maximum yaw rotation speed
    ///   - heading: drone heading
    public init(latitude: Double, longitude: Double, altitude: Double, gimbalControlMode: PointAndFlyGimbalControlMode,
                horizontalSpeed: Double, verticalSpeed: Double, yawRotationSpeed: Double, heading: PointAndFlyHeading) {
        self.horizontalSpeed = horizontalSpeed
        self.verticalSpeed = verticalSpeed
        self.yawRotationSpeed = yawRotationSpeed
        self.heading = heading
        super.init(latitude: latitude, longitude: longitude, altitude: altitude, gimbalControlMode: gimbalControlMode)
    }

    public override func isEqual(other: PointAndFlyDirective?) -> Bool {
        guard let other = other as? FlyDirective else {
            return false
        }

        return super.isEqual(other: other)
        && horizontalSpeed == other.horizontalSpeed
        && verticalSpeed == other.verticalSpeed
        && yawRotationSpeed == other.yawRotationSpeed
        && heading == other.heading
    }

    public override var description: String {
        return super.description
        + "-hSpeed(\(horizontalSpeed))-vSpeed(\(verticalSpeed))-rSpeed(\(yawRotationSpeed))-heading(\(heading))"
    }
}

/// Point'n'fly piloting interface.
///
/// This interface used is to request the drone to point at or to move to a given location.
///
/// This piloting interface can be retrieved by:
/// ```
/// drone.getPilotingItf(PilotingItfs.pointAndFly)
/// ```
public protocol PointAndFlyPilotingItf: PilotingItf, ActivablePilotingItf {
    /// Set of reasons why this piloting interface is unavailable.
    ///
    /// Empty when state is `.idle` or `.active`.
    var unavailabilityReasons: Set<PointAndFlyIssue> { get }

    /// Current point'n'fly directive if any one is executing, `nil` otherwise.
    ///
    /// It can be either a `PointDirective` or a `FlyDirective`.
    var currentDirective: PointAndFlyDirective? { get }

    /// *Point* or *fly* execution status.
    ///
    /// This property is *transient*: it will change back to `nil` immediately after the status is notified.
    var executionStatus: PointAndFlyExecutionStatus? { get }

    /// Executes the given *point* or *fly* directive.
    ///
    /// This interface will change to `active` when the execution starts, and then to `idle` when the drone reaches its
    /// destination (*fly* directive).
    ///
    /// If this method is called while the previous execution is active, it will be stopped immediately and the new
    /// directive is executed.
    ///
    /// In case of drone disconnection, the execution is interrupted.
    ///
    /// - Parameter directive: point'n'fly directive
    func execute(directive: PointAndFlyDirective)

    /// Sets the current pitch value.
    ///
    /// - Note: This method is supposed to be used during a *point* execution. If a *fly* is executing, calling this
    ///         method will abort it immediately.
    /// - Seealso: `ManualCopterPilotingItf.set(pitch:)`
    ///
    /// - Parameter pitch: the new pitch value to set
    func set(pitch: Int)

    /// Sets the current roll value.
    ///
    /// - Note: This method is supposed to be used during a *point* execution. If a *fly* is executing, calling this
    ///         method will abort it immediately.
    /// - Seealso: `ManualCopterPilotingItf.set(roll:)`
    ///
    /// - Parameter roll: the new roll value to set
    func set(roll: Int)

    /// Sets the current vertical speed value during a *point* execution.
    ///
    /// - Note: This method is supposed to be used during a *point* execution. If a *fly* is executing, calling this
    ///         method will abort it immediately.
    /// - Seealso: `ManualCopterPilotingItf.set(verticalSpeed:)`
    ///
    /// - Parameter verticalSpeed: the new vertical speed value to set
    func set(verticalSpeed: Int)
}

/// :nodoc:
/// Point'n'fly piloting interface description
public class PointAndFlyPilotingItfs: NSObject, PilotingItfClassDesc {
    public typealias ApiProtocol = PointAndFlyPilotingItf
    public let uid = PilotingItfUid.pointAndFly.rawValue
    public let parent: ComponentDescriptor? = nil
}
