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

/// Sleep mode activation status.
public enum SleepModeActivationStatus: String, CustomStringConvertible, CaseIterable {
    /// Sleep mode has been successfully activated; expect imminent disconnection.
    case success
    /// Sleep mode could not be activated.
    case failure

    /// Debug description.
    public var description: String { return rawValue }
}

/// Sleep mode peripheral interface.
///
/// This component allows to configure and activate the drone's sleep mode/wake up feature.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.sleepMode)
/// ```
public protocol SleepMode: Peripheral {
    /// Setting for configuring the secure wake-up message.
    ///
    /// Configures the message to match to trigger wake-up from sleep mode by sending an SMS to the drone.
    var wakeupMessage: StringSetting { get }

    /// Sleep mode activation status.
    ///
    /// This property is **transient**: it will be set once when the activation succeeds or fails, and then
    /// immediately back to `null`.
    var activationStatus: SleepModeActivationStatus? { get }

    /// Activates sleep mode.
    ///
    /// - Returns: `true` if the activation request has been sent to the drone, otherwise `false`
    func activate() -> Bool
}

/// :nodoc:
/// SleepMode description
public class SleepModeDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = SleepMode
    public let uid = PeripheralUid.sleepMode.rawValue
    public let parent: ComponentDescriptor? = nil
}
