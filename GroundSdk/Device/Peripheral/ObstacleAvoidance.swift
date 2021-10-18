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

/// Obstacle avoidance mode.
public enum ObstacleAvoidanceMode: String, CustomStringConvertible, CaseIterable {
    /// Obstacle avoidance is disabled.
    case disabled
    /// Obstacle avoidance is enabled, in standard mode.
    case standard

    /// Debug description.
    public var description: String { rawValue }
}

/// Obstacle avoidance state.
public enum ObstacleAvoidanceState: String, CustomStringConvertible, CaseIterable {
    /// Obstacle avoidance is not currently active.
    case inactive
    /// Obstacle avoidance is currently active and fully operational.
    case active
    /// Obstacle avoidance is currently active but in degraded mode.
    case degraded

    /// Debug description.
    public var description: String { rawValue }
}

/// Obstacle avoidance setting.
public protocol ObstacleAvoidanceSetting: AnyObject {
    /// Tells if setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported obstacle avoidance modes.
    var supportedValues: Set<ObstacleAvoidanceMode> { get }

    /// Obstacle avoidance preferred value for mode.
    var preferredValue: ObstacleAvoidanceMode { get set }
}

/// Obstacle avoidance peripheral interface.
///
/// Obstacle avoidance allows the drone to detect obstacles and autonomously change its trajectory to prevent
/// collisions.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.obstacleAvoidance)
/// ```
public protocol ObstacleAvoidance: Peripheral {
    /// Obstacle avoidance mode setting.
    var mode: ObstacleAvoidanceSetting { get }

    /// Current state of obstacle avoidance.
    var state: ObstacleAvoidanceState { get }
}

/// :nodoc:
/// Obstacle avoidance description.
@objc(GSObstacleAvoidanceDesc)
public class ObstacleAvoidanceDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = ObstacleAvoidance
    public let uid = PeripheralUid.obstacleAvoidance.rawValue
    public let parent: ComponentDescriptor? = nil
}
