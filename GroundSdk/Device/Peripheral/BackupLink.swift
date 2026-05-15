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

/// Backup link state.
public enum BackupLinkState: Equatable {

    /// Backup link is not established with the remote drone.
    case unsettled

    /// Backup link is enabled, successfully established with the remote drone, and is now ready to
    /// be activated.
    case established

    /// Backup link is currently active (main link inactive).
    /// - rxActivity: whether traffic is being received from drone on backup link
    /// - txActivity: whether traffic is being transmitted to drone on backup link
    case active(rxActivity: Bool, txActivity: Bool)
}

/// Backup link frequency selection mode.
public enum BackupLinkFrequencySelectionMode: Equatable {

    /// A frequency selection mode that allows to select a frequency in a set of discrete
    /// `frequencies` (in kHz).
    case frequencyList(frequencies: Set<Int>)

    /// A frequency selection mode that allows to select a frequency within a band in a set of
    /// discrete `bands`.
    case bandList(bands: Set<ClosedRange<Int>>)
}

/// Radio links configuration.
public enum RadioConfiguration: Equatable, CaseIterable, CustomStringConvertible {
    /// Both main and backup radio are on and may emit data.
    case all
    /// Main radio is disabled. Only backup radio is on and may emit data.
    case backupOnly
    /// Both main and backup radios are disabled. No data is emitted over the air.
    /// In this mode the drone does not send telemetry, only the controller can send commands.
    case silent

    public var description: String {
        switch self {
        case .all: return "all"
        case .backupOnly: return "backupOnly"
        case .silent: return "silent"
        }
    }
}

/// Setting providing access to the backup link frequency setup.
public protocol BackupLinkFrequencySetting: AnyObject {

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Frequencies to which the backup link may be configured.
    ///
    /// There are different configuration modes, depending on the used backup link hardware:
    /// - `frequencyList`: in this mode, the frequency may be chose among a list of discrete
    ///   frequencies
    /// - `bandList`: in this mode, the frequency may be chosen within a band of frequencies, itself
    ///    chosen among a
    /// discrete list of bands.
    var availableFrequencies: BackupLinkFrequencySelectionMode { get }

    /// Current frequency, in kHz.
    var frequency: Int { get }

    /// Changes the current frequency.
    ///
    /// The frequency can only be configured to one within `availableFrequencies`.
    ///
    /// - Note: changing the frequency while the backup link is active is not allowed.
    ///
    /// - Parameter frequency: requested frequency, in kHz
    func select(frequency: Int)

    /// Requests the device to select the most appropriate frequency automatically amongst
    /// `availableFrequencies`.
    ///
    /// The device will run its auto-selection process and eventually may change the frequency.
    func autoSelect()
}

/// Backup link peripheral interface for remote controls.
///
/// This component reports the state and allows to configure the backup link that provides emergency
/// telemetry and control of the drone in case the main link is broken.
///
/// This peripheral can be obtained from a remote control using:
/// ```
/// device.getPeripheral(Peripherals.backupLink)
/// ```
public protocol BackupLink: Peripheral {

    /// Current backup link state.
    var state: BackupLinkState { get }

    /// Radio configuration setting.
    /// This settings controls whether the main and/or backup radio are enabled and allow to transmit
    /// data over the air.
    var radioConfiguration: EnumSetting<RadioConfiguration> { get }

    /// Backup link frequency setting.
    var frequency: BackupLinkFrequencySetting { get }
}

public class BackupLinkDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = BackupLink
    public let uid = PeripheralUid.backupLink.rawValue
    public let parent: ComponentDescriptor? = nil
}
