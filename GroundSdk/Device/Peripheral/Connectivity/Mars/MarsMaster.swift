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

/// Mars radio master peripheral interface for drones.
///
/// Allows to configure various parameters of the device's Mars radio master mode, such as:
/// - Environment (indoor/outdoor) setup,
/// - Country,
/// - Channel,
/// - Security.
///
/// This peripheral can be retrieved by:
/// ```
/// drone.getPeripheral(Peripherals.marsMaster)
/// ```
public protocol MarsMaster: Peripheral {

    /// Mars master activation setting.
    ///
    /// - Note: Activating Mars master may deactivate other components, such as the `MarsSlave` component.
    var active: BoolSetting { get }

    /// Mars master indoor/outdoor environment setting.
    ///
    /// - Note: Altering this setting may change the set of available channels, and even result in a device
    /// disconnection since the channel currently in use might not be allowed with the new environment setup.
    var environment: EnumSetting<Environment> { get }

    /// Mars master country setting.
    ///
    /// - Note: Altering this setting may change the set of available channels, and even result in a device
    /// disconnection since the channel currently in use might not be allowed with the new country setup.
    var country: EnumSetting<Country> { get }

    /// Mars master channel setting.
    ///
    /// - Note: Changing the channel (either manually or through auto-selection) may result in a device disconnection.
    var channel: MarsChannelSetting { get }

    /// Mars master security setting.
    ///
    /// - Note: The device needs to be rebooted for the Mars master security to effectively change.
    var security: MarsMasterSecuritySetting { get }
}

/// :nodoc:
/// Mars master description
public class MarsMasterDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = MarsMaster
    public let uid = PeripheralUid.marsMaster.rawValue
    public let parent: ComponentDescriptor? = nil
}
