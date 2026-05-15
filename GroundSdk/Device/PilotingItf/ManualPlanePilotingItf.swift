// Copyright (C) 2025 Parrot Drones SAS
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

/// Takeoff state
public enum TakeoffState: Int, CustomStringConvertible, CaseIterable {

    /// On the ground, waiting to take off.
    case idle

    /// Arming motors.
    case arming

    /// Ready to be launched (hand, catapult...).
    case ready

    /// Detecting the throw to increase the throttle and validate the takeoff.
    case rescue

    /// Debug description.
    public var description: String {
        switch self {
        case .idle:   return "idle"
        case .arming: return "arming"
        case .ready:  return "ready"
        case .rescue: return "rescue"
        }
    }
}

/// Assistance mode.
public enum AssistanceMode: Int, CustomStringConvertible, CaseIterable {

    /// Plane will hold the roll and pitch specified.
    case assistedAttitude

    /// Plane will hold the roll, pitch specified, as well as the altitude.
    case assistedAltitude

    /// Debug description.
    public var description: String {
        switch self {
        case .assistedAttitude: return "assistedAttitude"
        case .assistedAltitude: return "assistedAltitude"
        }
    }
}

/// Loiter shape
public enum LoiterShape: Int, CustomStringConvertible, CaseIterable {
    /// Plane will loiter in circle shape.
    case circle

    /// Plane will loiter in eight shape.
    case eight

    /// Debug description.
    public var description: String {
        switch self {
        case .circle: return "circle"
        case .eight:  return "eight"
        }
    }
}

/// Loiter direction
public enum LoiterDirection: Int, CustomStringConvertible, CaseIterable {
    /// Clockwise.
    case clockwise

    /// Counter-clockwise.
    case counterClockwise

    /// Debug description.
    public var description: String {
        switch self {
        case .clockwise:        return "clockwise"
        case .counterClockwise: return "counterClockwise"
        }
    }
}

/// Manual plane piloting interface.
/// Used to pilot manually a plane.
///
/// This piloting interface is the default one (for a plane). This means that if you explicitly deactivate another
/// piloting interface, this one will be automatically activated. It also means that you can't explicitly deactivate
/// this piloting interface. To deactivate it, you have to activate another piloting interface.
///
/// This piloting interface can be retrieved by:
/// ```
/// drone.getPilotingItf(PilotingItfs.manualPlane)
/// ```
public protocol ManualPlanePilotingItf: PilotingItf, ActivablePilotingItf {

    /// Assistance mode for manual piloting.
    var assistanceMode: EnumSetting<AssistanceMode> { get }

    /// Takeoff state.
    var takeoffState: TakeoffState? { get }

    /// Loiter shape setting.
    var loiterShape: EnumSetting<LoiterShape> { get }

    /// Loiter direction setting.
    var loiterDirection: EnumSetting<LoiterDirection> { get }

    /// Loiter radius setting (in meters).
    var loiterRadius: DoubleSetting { get }

    /// Takeoff hovering altitude above ground in meters.
    /// `nil` if not supported by the drone.
    var takeoffHoveringAltitude: DoubleSetting? { get }

    /// Maximum yaw angular speed in degrees/second.
    ///
    /// This value define the range used by set:yawRotationSpeed, 100 correspond to a yaw angular speed of
    /// maxYawRotationSpeed value.
    var maxYawRotationSpeed: DoubleSetting { get }

    /// Vehicle type
    ///
    /// `nil` if not supported by the drone.
    var vehicleType: VehicleType? { get }

    /// Starts manual plane mode, activating or deactivating loitering.
    ///
    /// The interface should be `.idle` or `.activated` for this method to have effect.
    ///
    /// - Parameter loitering: whether to start loitering or not.
    /// - Returns: `true` if the command has been sent
    func start(loitering: Bool) -> Bool

    /// Sets the current pitch value.
    ///
    /// Expressed as a signed percentage of the max pitch, in range [-100, 100].
    /// * -100 corresponds to a pitch angle of max pitch towards ground (plane will fly down)
    /// * 100 corresponds to a pitch angle of max pitch towards sky (plane will fly up)
    ///
    /// - Note: This value may be clamped if necessary, in order to respect the maximum supported physical tilt of
    /// the plane.
    ///
    /// - Parameter pitch: the new pitch value to set
    func set(pitch: Int)

    /// Sets the current roll value.
    ///
    /// Expressed as a signed percentage of the max roll, in range [-100, 100].
    /// * -100 corresponds to a roll angle of max roll to the left (plane will turn towards left)
    /// * 100 corresponds to a roll angle of max roll to the right (plane will turn towards right)
    ///
    /// - Note: This value may be clamped if necessary, in order to respect the maximum supported physical tilt of
    /// the plane.
    ///
    /// - Parameter roll: the new roll value to set
    func set(roll: Int)

    /// Sets the current throttle value.
    ///
    /// Expressed as a signed percentage, in range [-100, 100].
    /// * -100 corresponds to min throttle value
    /// * 100 corresponds to max throttle value
    ///
    /// - Parameter throttle: the new throttle value to set
    func set(throttle: Int)

    /// Sets the yaw rotation speed value.
    ///
    /// Expressed as a signed percentage of the max yaw rotation speed setting (`maxYawRotationSpeed`), in range
    /// [-100, 100].
    /// * -100 corresponds to a counter-clockwise rotation of max yaw rotation speed
    /// * 100 corresponds to a clockwise rotation of max yaw rotation speed
    ///
    /// - Parameter yawRotationSpeed: the new yaw rotation speed value to set
    func set(yawRotationSpeed: Int)

    /// Emergency motor cut out.
    ///
    /// - Note: Watch out, this will cut the motor immediately. If the drone was flying it will fall off.
    func emergencyCutOut()

    /// Requests the plane to prepare (arm) for take off.
    func arm()

    /// Requests the plane to cancel motor arming.
    func cancelArming()

    /// Requests the drone to land.
    func land()
}

/// :nodoc:
/// Manual plane piloting interface description
public class ManualPlanePilotingItfs: NSObject, PilotingItfClassDesc {
    public typealias ApiProtocol = ManualPlanePilotingItf
    public let uid = PilotingItfUid.manualPlane.rawValue
    public let parent: ComponentDescriptor? = nil
}
