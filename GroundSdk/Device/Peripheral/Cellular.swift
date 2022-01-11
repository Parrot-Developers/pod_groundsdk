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

/// Cellular mode : the different modes for peripheral
public enum CellularMode: String, CustomStringConvertible, CaseIterable {
    /// Cellular feature is disabled, Airplane mode.
    case disabled
    /// Cellular feature is enabled, data are disabled.
    case nodata
    /// Cellular feature is enabled, data are enabled.
    case data

    /// Debug description.
    public var description: String { return rawValue }
}

/// SIM card status.
public enum CellularSimStatus: String, CustomStringConvertible, CaseIterable {
    /// SIM card status is unknown.
    case unknown

    /// No SIM card is available.
    case absent

    /// SIM card is initializing.
    case initializing

    /// SIM card is locked and requires a PIN code to unlock.
    case locked

    /// SIM card is ready.
    case ready

    /// Debug description.
    public var description: String { return rawValue }
}

/// Registration status.
public enum CellularRegistrationStatus: String, CustomStringConvertible, CaseIterable {
    /// Not registered.
    case notRegistered

    /// Searching.
    case searching

    /// Registered with home operator.
    case registeredHome

    /// Registered with roaming operator.
    case registeredRoaming

    /// Registration denied.
    case denied

    /// Debug description.
    public var description: String { return rawValue }
}

/// Network status.
public enum CellularNetworkStatus: String, CustomStringConvertible, CaseIterable {
    /// Network is deactivated.
    case deactivated

    /// Network is activated.
    case activated

    /// Network activation was denied.
    case denied

    /// Internal error.
    case error

    /// Debug description.
    public var description: String { return rawValue }
}

/// Modem status.
public enum CellularModemStatus: String, CustomStringConvertible, CaseIterable {
    /// Modem is off.
    case off

    /// Modem is offline.
    case offline

    /// Modem is online.
    case online

    /// Modem initialization error.
    case error

    /// Modem firmware is currently being updated.
    case updating

    /// Debug description.
    public var description: String { return rawValue }
}

/// Technology.
public enum CellularTechnology: String, CustomStringConvertible, CaseIterable {
    /// Global System for Mobile Communications.
    case gsm

    /// General Packet Radio Service.
    case gprs

    /// Enhanced Data Rates for GSM Evolution.
    case edge

    /// 3G.
    case threeG

    /// High Speed Downlink Packet Access.
    case hsdpa

    /// High Speed Uplink Packet Access.
    case hsupa

    /// High Speed Packet Access.
    case hspa

    /// 4G.
    case fourG

    /// 4G+ Band aggregation.
    case fourGPlus

    /// 5G.
    case fiveG

    /// Debug description.
    public var description: String { return rawValue }
}

/// Network mode.
public enum CellularNetworkMode: String, CustomStringConvertible, CaseIterable {
    /// Mode auto.
    case auto

    /// 3G.
    case mode3g

    /// 4G.
    case mode4g

    /// 5G.
    case mode5g

    /// Debug description.
    public var description: String { return rawValue }
}

/// Settings reset state.
public enum CellularResetState: String, CustomStringConvertible, CaseIterable {
    /// No ongoing reset.
    case none
    /// Settings reset in progress.
    case ongoing
    /// Reset was successful, drone is rebooting.
    ///
    /// This result is transient, reset state will change back to `.none` immediately after success is notified.
    case success
    /// Reset has failed.
    ///
    /// This result is transient, reset state will change back to `.none` immediately after failure is notified.
    case failure

    /// Debug description.
    public var description: String { return rawValue }
}

/// Setting providing access to the CellularMode.
public protocol CellularModeSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { get }

    /// Cellular mode value.
    var value: CellularMode { get set }
}

/// Setting providing access to the APN configuration.
public protocol ApnConfigurationSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { get }

    /// `true` if APN is manual, `false` otherwise.
    var isManual: Bool { get }

    /// Access Point url.
    var url: String { get }

    /// Access Point username.
    var username: String { get }

    /// Access Point password.
    var password: String { get }

    /// Sets the apn configuration to automatic.
    ///
    /// - Returns: `true` if the setToAuto has been sent, `false` otherwise
    func setToAuto() -> Bool

    /// Sets the apn configuration to manual.
    ///
    /// - Parameters:
    ///     - url: APN url
    ///     - username: APN username
    ///     - password: APN password
    /// - Returns: `true` if the apn configration has been sent, `false` otherwise
    func setToManual(url: String, username: String, password: String) -> Bool
}

/// Setting to change the network mode.
public protocol CellularNetworkModeSetting: AnyObject {
    /// Whether the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Current network mode setting.
    var value: CellularNetworkMode { get set }
}

/// Cellular peripheral interface.
///
/// This peripheral allows using cellular feature.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.cellular)
/// ```
public protocol Cellular: Peripheral {
    /// Cellular mode setting.
    var mode: CellularModeSetting { get }

    /// SIM status.
    var simStatus: CellularSimStatus { get }

    /// SIM serial number.
    var simIccid: String { get }

    /// SIM International Mobile Subscriber Identity (imsi).
    var simImsi: String { get }

    /// Registration status
    var registrationStatus: CellularRegistrationStatus { get }

    /// Operator name.
    var `operator`: String { get }

    /// Technology
    var technology: CellularTechnology { get }

    /// Indicates if roaming is allowed or not
    var isRoamingAllowed: BoolSetting { get }

    /// Network mode
    var networkMode: CellularNetworkModeSetting { get }

    /// Modem status
    var modemStatus: CellularModemStatus { get }

    /// International mobile equipment identity (IMEI).
    var imei: String { get }

    /// Network status
    var networkStatus: CellularNetworkStatus { get }

    /// APN Configuration setting
    var apnConfigurationSetting: ApnConfigurationSetting { get }

    /// Whether PIN code is requested.
    /// `true` if PIN is requested, `false` otherwise.
    var isPinCodeRequested: Bool { get }

    /// Whether PIN code is invalid.
    /// `false` if no PIN code has been provided yet or if no PIN code is requested,
    /// `true` if an invalid PIN code has been rejected by the SIM.
    var isPinCodeInvalid: Bool { get }

    /// Remaining PIN code tries.
    var pinRemainingTries: Int { get }

    /// Enters the PIN code.
    ///
    /// - Parameter pincode: PIN to use to unlock SIM card
    /// - Returns: `true` if the pincode has been sent, `false` otherwise
    func enterPinCode(pincode: String) -> Bool

    /// Resets the cellular configuration.
    /// All settings will be reset to their default values, PIN code will be cleared, and the product will reboot if it
    /// is not flying.
    ///
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func resetSettings() -> Bool

    /// Cellular reset state.
    var resetState: CellularResetState { get }
}

/// :nodoc:
/// Cellular description
public class CellularDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = Cellular
    public let uid = PeripheralUid.cellular.rawValue
    public let parent: ComponentDescriptor? = nil
}
