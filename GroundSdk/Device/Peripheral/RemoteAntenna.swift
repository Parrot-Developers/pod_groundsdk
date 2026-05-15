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

/// Remote antenna state.
public enum RemoteAntennaState: CaseIterable, Equatable {
    public static var allCases: [RemoteAntennaState] = [.disabled, .searching, .connecting(isCloud: false),
                                                        .connecting(isCloud: true), .connected(isCloud: false),
                                                        .connected(isCloud: true)]
    /// Remote antenna feature is disabled.
    case disabled

    /// Remote control is looking for remote antennas.
    case searching

    /// Connection to remote antenna is in progress.
    ///
    /// - parameter isCloud: `true` if connecting to a cloud antenna
    case connecting(isCloud: Bool)

    /// Remote antenna is currently active.
    ///
    /// - parameter isCloud: `true` if connected to a cloud antenna
    case connected(isCloud: Bool)
}

/// Remote antenna product variant
public enum RemoteAntennaProductVariant: Int, CustomStringConvertible {
    /// Remote antenna standard variant (with either MARS or Wifi radio).
    case standard

    /// Remote antenna ranger variant (for remote antenna usage only).
    case ranger

    public var description: String {
        switch self {
        case .standard: return "standard"
        case .ranger:   return "ranger"
        }
    }
}

/// Remote antenna system info.
public struct RemoteAntennaSystemInfo: Equatable {

    /// Remote antenna model
    public var model: DeviceModel

    /// Remote antenna serial number
    public var serialNumber: String

    /// Remote antenna firmware version
    public var firmwareVersion: String

    /// Whether the firmware is blacklisted or not
    public var isFirmwareBlacklisted: Bool

    /// Remote antenna product variant
    public var productVariant: RemoteAntennaProductVariant

    /// Constructor
    ///
    /// - Parameters:
    ///   - model: remote antenna model
    ///   - serialNumber: remote antenna serial number
    ///   - firmwareVersion: remote antenna firmware version
    ///   - isFirmwareBlacklisted: whether  the firmware is blacklisted or not
    ///   - productVariant: remote antenna product variant
    public init(model: DeviceModel, serialNumber: String, firmwareVersion: String,
                isFirmwareBlacklisted: Bool, productVariant: RemoteAntennaProductVariant) {
        self.model = model
        self.serialNumber = serialNumber
        self.firmwareVersion = firmwareVersion
        self.isFirmwareBlacklisted = isFirmwareBlacklisted
        self.productVariant = productVariant
    }
}

/// Motorized support information.
public struct MotorizedSupport: Equatable {

    /// Motorized support serial.
    public var serialNumber: String

    /// Alarms about issues that currently hinders optimal behavior of the motorized support.
    public var alarms: Set<MotorizedSupportAlarm>

    /// Constructor
    ///
    /// - Parameter serialNumber: motorized support serial number
    public init(serialNumber: String, alarms: Set<MotorizedSupportAlarm>) {
        self.serialNumber = serialNumber
        self.alarms = alarms
    }
}

/// Setting providing access to the geographical location setup.
public protocol RemoteAntennaLocationSetting: AnyObject {

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Current remote antenna location.
    var value: CLLocationCoordinate2D? { get set }
}

/// Motorized support alarm.
public enum MotorizedSupportAlarm {

    /// Support cannot rotate anymore due to obstacles or a stall.
    case motorStall

    /// Support is not level enough with the ground.
    case tooMuchAngle

    /// Support is plugged to the wrong USB port.
    case wrongUsbPort

    public static var allCases: [MotorizedSupportAlarm] = [.motorStall, .tooMuchAngle, .wrongUsbPort]
}

/// Remote antenna peripheral interface.
///
/// This peripheral allows configuring a remote control as a remote antenna.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.remoteAntenna)
/// ```
public protocol RemoteAntenna: Peripheral {

    /// Remote antenna activation setting.
    var enabled: BoolSetting { get }

    /// Current state of the remote antenna device.
    /// `nil` if unknown or the remote antenna feature is not `enabled` or `disabled`.
    var state: RemoteAntennaState? { get }

    /// Current battery charge level, as an integer percentage of full charge.
    /// `nil` if unknown or the antenna is not `active`.
    var batteryCharge: Int? { get }

    /// `true` when the battery is charging.
    /// `nil` if unknown or the antenna is not `active`.
    var batteryCharging: Bool? { get }

    /// `true` when the remote antenna charger is plugged.
    /// `nil` if unknown or the antenna is not `active`.
    var chargerPlugged: Bool? { get }

    /// Estimated available bandwidth, corresponding to the ascending speed, in bits per second.
    ///  `nil` if unknown or the antenna is not `active`.
    var availableBandwidth: UInt64? { get }

    /// Remote antenna system info.
    /// `nil` if unavailable.
    var systemInfo: RemoteAntennaSystemInfo? { get }

    /// List of discovered cloud antennas by their serial numbers.
    ///
    /// This list is initially empty and is populated once paired antennas have been registered in user account.
    /// It's progressively refreshed as antennas availability changes.
    /// See `UserAccount.setCloudAntennaList`
    var discoveredAntennas: [String]? { get }

    /// Remote antenna geographical location setting.
    var location: RemoteAntennaLocationSetting { get }

    /// Remote Antenna heading in degrees, in range [0, 360[, relative to the north
    ///  `nil` if unknown.
    var heading: Double? { get }

    /// Whether the remote antenna requires its geographical location to be set.
    /// `nil` if unknown or the antenna is not `active`.
    var isLocationRequired: Bool? { get }

    /// Motorized support of the remote antenna
    /// `nil` if not supported or the antenna is not `active` or if no motorized support is connected.
    var motorizedSupport: MotorizedSupport? { get }

    /// Requests connection to the cloud antenna identified by the given serial number
    ///
    /// Return `true` if connection was successfully requested
    func connect(serialNumber: String) -> Bool

    /// Requests disconnection from the cloud antenna.
    ///
    /// Return `true` if disconnection was successfully requested
    func disconnect() -> Bool
}

public class RemoteAntennaDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = RemoteAntenna
    public let uid = PeripheralUid.remoteAntenna.rawValue
    public let parent: ComponentDescriptor? = nil
}
