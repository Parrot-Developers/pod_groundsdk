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

/// Mars channel setting implementation.
class MarsChannelSettingCore: MarsChannelSetting {

    var updating: Bool { return timeout.isScheduled }

    private(set) var selectionMode: MarsChannelSelectionMode = .manual

    private(set) var availableChannels: Set<MarsChannel> = []

    private(set) var availableBands: Set<MarsBand> = []

    private(set) var channel: MarsChannel = MarsChannel(band: .band_1_6_Ghz, id: 1)

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes.
    let timeout = SettingTimeout()

    /// Delegate called when the setting value is changed by setting `mode` property.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Closure to call to change the value.
    private let backend: (MarsChannelSelectionMode, MarsChannel?) -> Bool

    /// Constructor.
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (MarsChannelSelectionMode, MarsChannel?)
         -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    func select(channel newChannel: MarsChannel) {
        guard (selectionMode != .manual || channel != newChannel)
                && availableChannels.contains(newChannel) else {
            return
        }

        if backend(.manual, newChannel) {
            let oldSelectionMode = selectionMode
            let oldChannel = channel
            selectionMode = .manual
            channel = newChannel
            timeout.schedule(timeout: MarsComponentCore.settingTimeout) { [weak self] in
                if let `self` = self {
                    let selectionModeUpdated = self.update(selectionMode: oldSelectionMode)
                    let channelUpdated = self.update(channel: oldChannel)
                    if selectionModeUpdated || channelUpdated {
                        self.didChangeDelegate.userDidChangeSetting()
                    }
                }
            }
            didChangeDelegate.userDidChangeSetting()
        }
    }

    func autoSelect(onBands bands: Set<MarsBand>) {
        let allowedBands = bands.filter { availableBands.contains($0) }
        guard !allowedBands.isEmpty else { return }

        if backend(.autoOnBands(bands: allowedBands), nil) {
            let oldSelectionMode = selectionMode
            selectionMode = .autoOnBands(bands: allowedBands)
            timeout.schedule(timeout: MarsComponentCore.settingTimeout) { [weak self] in
                if let `self` = self, self.update(selectionMode: oldSelectionMode) {
                    self.didChangeDelegate.userDidChangeSetting()
                }
            }
            didChangeDelegate.userDidChangeSetting()
        }
    }

    func autoSelect(rxChannels: Set<MarsChannel>, txChannels: Set<MarsChannel>) {
        let newMode = MarsChannelSelectionMode.autoOnChannels(rxChannels: rxChannels, txChannels: txChannels)
        guard selectionMode != newMode && !rxChannels.isEmpty && !txChannels.isEmpty else { return }

        if backend(newMode, nil) {
            let oldSelectionMode = selectionMode
            selectionMode = newMode
            timeout.schedule(timeout: MarsComponentCore.settingTimeout) { [weak self] in
                if let `self` = self, self.update(selectionMode: oldSelectionMode) {
                    self.didChangeDelegate.userDidChangeSetting()
                }
            }
            didChangeDelegate.userDidChangeSetting()
        }
    }

    /// Updates selection mode.
    ///
    /// - Parameter newValue: the new selection mode
    /// - Returns: `true` if the selection mode has been changed, `false` otherwise
    func update(selectionMode newValue: MarsChannelSelectionMode) -> Bool {
        if selectionMode != newValue || updating {
            selectionMode = newValue
            timeout.cancel()
            return true
        }
        return false
    }

    /// Updates available channels.
    ///
    /// - Parameter newValue: new available channels
    /// - Returns: `true` if available channels have changed, `false` otherwise
    func update(availableChannels newValue: Set<MarsChannel>) -> Bool {
        if availableChannels != newValue || updating {
            availableChannels = newValue
            return true
        }
        return false
    }

    /// Updates available bands.
    ///
    /// - Parameter newValue: new available bands
    /// - Returns: `true` if available bands have changed, `false` otherwise
    func update(availableBands newValue: Set<MarsBand>) -> Bool {
        if availableBands != newValue || updating {
            availableBands = newValue
            return true
        }
        return false
    }

    /// Updates current channel.
    ///
    /// - Parameter newValue: the new channel
    /// - Returns: `true` if the channel has been changed, `false` otherwise
    func update(channel newValue: MarsChannel) -> Bool {
        if channel != newValue || channel.frequency != newValue.frequency || updating {
            channel = newValue
            timeout.cancel()
            return true
        }
        return false
    }

    /// Cancels any pending rollback.
    ///
    /// - Parameter completionClosure: block that will be called if a rollback was pending
    func cancelRollback(completionClosure: () -> Void) {
        if timeout.isScheduled {
            timeout.cancel()
            completionClosure()
        }
    }
}
