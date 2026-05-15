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

/// Location source
public enum Source: CaseIterable {
    /// Location source's gps
    case gps
    /// Location source's glonass
    case glonass
    /// Location source's galileo
    case galileo
    /// Location source's beidou
    case beidou
    /// Location source's rtk
    case rtk
    /// Location source's visionMap
    case visionMap
    /// Location source's odometry
    case odometry
    /// Location source's barometer
    case barometer
    /// Location source's magnetometer
    case magnetometer
}

/// GNSS source
public enum GnssSource: String, CustomStringConvertible, CaseIterable {
    /// GNSS is from internal source
    case `internal`
    /// GNSS is from external source
    case external

    public var description: String { rawValue }
}

/// Reliability of a location
public enum Reliability: CaseIterable {
    /// The location is considered as unreliable
    case unreliable
    /// The location is considered as reliable
    case reliable
}

/// Provides information about drone GNSS.
public struct GnssInfo: Equatable {

    /// Total count of satellites currently used to obtain the location,
    /// `nil` if this information is unavailable
    public var satelliteCount: Int?

    public init(satelliteCount: Int?) {
        self.satelliteCount = satelliteCount
    }
}

/// Navigation peripheral interface for drone.
///
/// Allows to:
/// - retrieve the current drone position,
/// - activate/deactivate its location sources,
/// - set the drone position in GPS coordinates corresponding to the origin of its global coordinate system.
///
/// this peripheral replaces the [GPS] instrument.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.navigationControl)
/// ```
public protocol NavigationControl: Peripheral {
    /// Information about drone GNSS.
    /// `nil` if no GNSS fix is acquired, or if no GNSS constellation are used as a location source.
    var gnssInfo: GnssInfo? { get }

    /// Current location reported by the drone.
    /// This information may not be up-to-date as long as the drone does not report it.
    /// `nil` if the drone could not determine its location at the moment.
    var currentLocation: CLLocation? { get }

    /// Last Known location.
    /// `nil` if this information is unavailable; equal to currentLocation if the latter is not `nil`.
    /// Invalid altitude if verticalAccuracy < 0
    var lastKnownLocation: CLLocation? { get }

    ///  Current location reliability. `nil` if this information is unavailable.
    var reliability: Reliability? { get }

    /// Tells whether location is currently computed from the magnetometer.
    /// `nil` if this information is unavailable.
    var usesMagnetometer: Bool? { get }

    /// List of sources supported by the device
    /// Component source setting.
    var sources: EnumSetSetting<Source> { get }

    /// GNSS source
    /// `nil` if this information is unavailable.
    var gnssSource: GnssSource? { get }

    /// Sets the drone position in GPS coordinates corresponding to the 2D origin of its global
    /// coordinate system and its heading.
    ///
    /// The drone will set the given coordinate as its origin for any operation performed in global
    /// coordinate system.
    ///
    /// - Parameters:
    ///   - latitude: origin latitude in decimal degrees
    ///   - longitude: origin longitude in decimal degrees
    ///   - heading: origin heading in radians
    /// - Returns: `true` if the request has been sent to the drone, otherwise `false`
    func sendGlobalPose(latitude: Double, longitude: Double, heading: Float) -> Bool
}

/// :nodoc:
/// Navigation peripheral description.
public class NavigationControlDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = NavigationControl
    public let uid = PeripheralUid.navigationControl.rawValue
    public let parent: ComponentDescriptor? = nil
}
