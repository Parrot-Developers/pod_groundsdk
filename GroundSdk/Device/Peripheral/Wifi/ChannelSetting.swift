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

/// Wifi access point channel selection mode.
public enum ChannelSelectionMode: Int, CustomStringConvertible {
    /// Channel has been selected manually.
    case manual
    /// Channel has been selected manually.
    case auto2_4GhzBand
    /// Channel has been selected automatically on the 5 GHz band.
    case auto5GhzBand
    /// Channel has been selected automatically on either the 2.4 or the 5 Ghz band.
    case autoAnyBand

    /// Debug description.
    public var description: String {
        switch self {
        case .manual:           return "manual"
        case .auto2_4GhzBand:   return "auto2.4GhzBand"
        case .auto5GhzBand:     return "auto5GhzBand"
        case .autoAnyBand:      return "autoAnyBand"
        }
    }
}

/// Setting providing access to the Wifi access point channel setup.
public protocol ChannelSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Current selection mode of the access point channel.
    var selectionMode: ChannelSelectionMode { get }

    /// Set of channels to which the access point may be configured.
    var availableChannels: Set<WifiChannel> { get }

    /// Access point's current channel.
    var channel: WifiChannel { get }

    /// Changes the access point current channel.
    ///
    /// - Parameter channel: new channel to use
    func select(channel: WifiChannel)

    /// Tells whether automatic channel selection on any frequency band is available.
    ///
    /// Some devices, for instance remote controls, don't support auto-selection.
    ///
    /// - Returns: `true` if `autoSelect()` can be called
    func canAutoSelect() -> Bool

    /// Requests the device to select the most appropriate channel for the access point automatically.
    ///
    /// The device will run its auto-selection process and eventually may change the current channel.
    /// The device will also remain in this auto-selection mode, that is, it will run auto-selection to setup
    /// the channel on subsequent boots, until the application selects a channel manually (with `select(channel:)`)
    func autoSelect()

    /// Tells whether automatic channel selection on a given frequency band is available.
    ///
    /// Depending on the country and environment setup, and the currently allowed channels, some auto-selection
    /// modes may not be available to the application.
    /// Also, some devices, for instance remote controls, don't support auto-selection.
    ///
    /// - Parameter band: the frequency band
    /// - Returns: `true` if `autoSelect()` can be called
    func canAutoSelect(onBand band: Band) -> Bool

    /// Requests the device to select the most appropriate channel for the access point automatically.
    ///
    /// The device will run its auto-selection process and eventually may change the current channel.
    /// The device will also remain in this auto-selection mode, that is, it will run auto-selection to setup
    /// the channel on subsequent boots, until the application selects a channel manually (with `select(channel:)`)
    ///
    /// - Parameter band: the frequency band on which the automatic selection should be done
    func autoSelect(onBand band: Band)
}
