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

/// Kill-switch mode.
public enum KillSwitchMode: String, CustomStringConvertible, CaseIterable {
    /// Kill-switch is disabled.
    case disabled
    /// Kill-switch is enabled. When activated, drone will try to land.
    case soft
    /// Kill-switch is enabled. When activated, drone motors will be cut off.
    case hard

    /// Debug description.
    public var description: String { return rawValue }
}

/// Setting providing access to the KillSwitchMode.
public protocol KillSwitchModeSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported kill-switch modes.
    var supportedValues: Set<KillSwitchMode> { get }

    /// Kill-switch mode value.
    var value: KillSwitchMode { get set }
}

/// Identifies how the kill-switch has been activated.
public enum KillSwitchActivationSource: String, CustomStringConvertible, CaseIterable {
    /// Kill-switch has been activated by an unidentified source.
    case unidentified
    /// Kill-switch has been activated using LORA communication channel.
    case lora
    /// Kill-switch has been activated using the SDK APIs (see also `activate()`).
    case sdk
    /// Kill-switch has been activated by sending an SMS to the drone whose content matches `secureMessage`.
    case sms

    /// Debug description.
    public var description: String { return rawValue }
}

/// Kill-switch peripheral interface.
///
/// This component allows to configure and activate the drone's kill-switch feature.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.killSwitch)
/// ```
public protocol KillSwitch: Peripheral {
    /// Kill-switch mode setting.
    var mode: KillSwitchModeSetting { get }

    /// Setting for configuring the secure activation message.
    ///
    /// Configures the message to match to trigger the kill-switch by sending a SMS to the drone.
    var secureMessage: StringSetting { get }

    /// Identifies how kill-switch has been activated; `nil` if kill-switch has not been activated yet.
    var activatedBy: KillSwitchActivationSource? { get }

    /// Activates kill-switch.
    ///
    /// - Returns: `true` if the activation request has been sent to the drone, otherwise `false`
    func activate() -> Bool
}

/// :nodoc:
/// KillSwitch description
public class KillSwitchDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = KillSwitch
    public let uid = PeripheralUid.killSwitch.rawValue
    public let parent: ComponentDescriptor? = nil
}
