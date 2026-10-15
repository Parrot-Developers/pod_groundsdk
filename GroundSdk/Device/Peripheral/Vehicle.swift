// Copyright (C) 2026 Parrot Drones SAS
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

/// Platform type.
public enum VehiclePlatformType: Int, CustomStringConvertible {

    /// On land platform.
    case land

    /// On water platform.
    case water

    /// Debug description.
    public var description: String {
        switch self {
        case .land:  return "land"
        case .water: return "water"
        }
    }
}

/// Requirement.
public enum VehicleRequirement: Int, CustomStringConvertible {

    /// GNSS of the drone.
    case droneGNSS

    /// GNSS of the controller in the vehicle.
    case controllerGNSS

    /// Trusted GNSS.
    case trustedGNSS

    /// Debug description.
    public var description: String {
        switch self {
        case .droneGNSS: return "droneGNSS"
        case .controllerGNSS: return "controllerGNSS"
        case .trustedGNSS: return "trustedGNSS"
        }
    }
}

/// Improvement.
public enum VehicleImprovement: Int, CustomStringConvertible {

    /// GNSS of the drone.
    case droneGNSS

    /// GNSS of the controller in the vehicle.
    case controllerGNSS

    /// Trusted GNSS.
    case trustedGNSS

    /// Low vehicle speed.
    case lowVehicleSpeed

    /// Debug description.
    public var description: String {
        switch self {
        case .droneGNSS: return "droneGNSS"
        case .controllerGNSS: return "controllerGNSS"
        case .trustedGNSS: return "trustedGNSS"
        case .lowVehicleSpeed: return "lowVehicleSpeed"
        }
    }
}

/// Notification.
public enum VehicleNotification: Int, CustomStringConvertible {

    /// Computer vision module has found vehicle.
    case computerVisionUsed

    /// Return to vehicle, computer vision searching.
    case rtvComputerVisionSearching

    /// Landing, computer vision searching.
    case landingComputerVisionSearching

    /// Vehicle was not found while landing.
    case landingVehicleNotFound

    /// Landing zone was not found while landing.
    case landingZoneNotFound

    /// Debug description.
    public var description: String {
        switch self {
        case .computerVisionUsed: return "computerVisionUsed"
        case .rtvComputerVisionSearching: return "rtvComputerVisionSearching"
        case .landingComputerVisionSearching: return "landingComputerVisionSearching"
        case .landingVehicleNotFound: return "landingVehicleNotFound"
        case .landingZoneNotFound: return "landingZoneNotFound"
        }
    }
}

/// Vehicle peripheral interface.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.vehicle)
/// ```
public protocol Vehicle: Peripheral {

    /// Gives access to the activation setting.
    var activation: BoolSetting { get }

    /// Relative guidance setting.
    var relativeGuidance: BoolSetting { get }

    /// Whether relative guidance is modiable or not.
    var isRelativeGuidanceModifiable: Bool { get }

    /// Precise calibration setting.
    var preciseCalibration: BoolSetting { get }

    /// Wipes the files linked to the precise calibration.
    ///
    /// - Returns: `true` if the request was forwarded to the drone, otherwise `false`
    func wipePreciseCalibration() -> Bool

    /// Set of missing requirements for takeoff/relative move.
    var missingRequirements: Set<VehicleRequirement> { get }

    /// Set of possible improvements for takeoff/relative move.
    var improvements: Set<VehicleImprovement> { get }

    /// Maximum horizontal distance authorized from the vehicle, in meters..
    var maxHorizontalDistance: Double { get }

    /// Set of notifications.
    var notifications: Set<VehicleNotification> { get }

    /// Platform type setting.
    var platformType: EnumSetting<VehiclePlatformType> { get }
}

/// :nodoc:
/// Vehicle peripheral description.
public class VehicleDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = Vehicle
    public let uid = PeripheralUid.vehicle.rawValue
    public let parent: ComponentDescriptor? = nil
}
