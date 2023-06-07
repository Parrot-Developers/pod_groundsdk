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

/// Wifi access point peripheral interface for drones.
///
/// Allows to configure various parameters of the device's Wifi access point, such as:
/// - Environment (indoor/outdoor) setup
/// - Country
/// - Channel
/// - SSID
/// - Security
///
/// This peripheral can be retrieved by:
/// ```
/// drone.getPeripheral(Peripherals.wifiAccessPoint)
/// ```
public protocol WifiAccessPoint: Peripheral {

    /// Access point activation setting.
    ///
    /// - Note: Activating the access point may deactivate other components, such as the `WifiStation` component.
    var active: BoolSetting { get }

    /// Access point indoor/outdoor environment setting.
    ///
    /// - Note: Altering this setting may change the set of available channels, and even result in a device
    /// disconnection since the channel currently in use might not be allowed with the new environment setup.
    var environment: EnvironmentSetting { get }

    /// Access point country setting.
    ///
    /// - Note: Altering this setting may change the set of available channels, and even result in a device
    /// disconnection since the channel currently in use might not be allowed with the new country setup.
    var country: EnumSetting<Country> { get }

    /// Legacy access point country setting.
    ///
    /// The country can only be configured to one of the `availableCountries`. The country is a two-letter string,
    /// as ISO 3166-1-alpha-2 code.
    /// - Note: Altering this setting may change the set of available channels, and even result in a device
    /// disconnection since the channel currently in use might not be allowed with the new country setup.
    @available(*, deprecated, message: "Use `country` instead")
    var isoCountryCode: StringSetting { get }

    /// `true` if a country has been automatically selected by the drone AND can be modified, `false` otherwise.
    @available(*, deprecated, message: "Do not use; will be retired in next release")
    var defaultCountryUsed: Bool { get }

    /// Set of countries to which the access point may be configured.
    @available(*, deprecated, message: "Use `country` instead")
    var availableCountries: Set<String> { get }

    /// Access point channel setting.
    ///
    /// - Note: Changing the channel (either manually or through auto-selection) may result in a device disconnection.
    var channel: ChannelSetting { get }

    /// Access point Service Set IDentifier (SSID) setting.
    var ssid: StringSetting { get }

    /// Access point SSID broadcast (hidden network) setting.
    var ssidBroadcast: BoolSetting { get }

    /// Access point security setting.
    ///
    /// - Note: The device needs to be rebooted for the access point security to effectively change.
    var security: SecurityModeSetting { get }
}

/// :nodoc:
/// Wifi access point description
public class WifiAccessPointDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = WifiAccessPoint
    public let uid = PeripheralUid.wifiAccessPoint.rawValue
    public let parent: ComponentDescriptor? = nil
}
