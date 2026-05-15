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

/// Backup link backend part.
public protocol BackupLinkBackend: AnyObject {

    /// Sets the radio configuration.
    ///
    /// - Parameter radioConfiguration: the newn radio configuration value
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(radioConfiguration: RadioConfiguration) -> Bool

    /// Sets the backup link frequency.
    ///
    /// - Parameter frequency: the new frequency
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func select(frequency: Int) -> Bool

    /// Requests auto-selection of the most appropriate frequency.
    ///
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func autoSelectFrequency() -> Bool
}

/// Frequency setting implementation.
class BackupLinkFrequencySettingCore: BackupLinkFrequencySetting {

    var updating: Bool { return timeout.isScheduled }

    private(set) var availableFrequencies: BackupLinkFrequencySelectionMode = .frequencyList(frequencies: [])

    private(set) var frequency: Int = 0

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes.
    let timeout = SettingTimeout()

    /// Delegate called when the setting value is changed by setting `mode` property.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Closure to call to change the value.
    private let backend: (Int?) -> Bool

    /// Constructor.
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (Int?) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    func select(frequency newFrequency: Int) {
        guard newFrequency != frequency && availableFrequencies.allows(newFrequency) else { return }

        if backend(newFrequency) {
            let oldFrequency = frequency
            frequency = newFrequency
            timeout.schedule { [weak self] in
                if let `self` = self, self.update(frequency: oldFrequency) {
                    self.didChangeDelegate.userDidChangeSetting()
                }
            }
            didChangeDelegate.userDidChangeSetting()
        }
    }

    func autoSelect() {
        if backend(nil) {
            // schedule a 'dummy' rollback to get the updating flag armed while we wait for the frequency change
            timeout.schedule { [weak self] in
                self?.didChangeDelegate.userDidChangeSetting()
            }
            didChangeDelegate.userDidChangeSetting()
        }
    }

    /// Updates available frequencies.
    ///
    /// - Parameter newValue: new available frequencies
    /// - Returns: `true` if available frequencies have changed, `false` otherwise
    func update(availableFrequencies newValue: BackupLinkFrequencySelectionMode) -> Bool {
        if availableFrequencies != newValue || updating {
            availableFrequencies = newValue
            return true
        }
        return false
    }

    /// Updates current frequency.
    ///
    /// - Parameter newValue: the new frequency
    /// - Returns: `true` if the frequency has been changed, `false` otherwise
    func update(frequency newValue: Int) -> Bool {
        if frequency != newValue || updating {
            frequency = newValue
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

/// Extension that adds availability check.
extension BackupLinkFrequencySelectionMode {

    /// Tells whether this selection mode allows to select the given frequency.
    ///
    /// - Parameter frequency: frequency to check
    /// - Returns: `true` if the frequency is allowed
    func allows(_ frequency: Int) -> Bool {
        switch self {
        case .frequencyList(let frequencies):
            return frequencies.contains(frequency)
        case .bandList(let bands):
            return bands.contains { $0.contains(frequency) }
        }
    }
}

/// Internal BackupLink peripheral implementation.
public class BackupLinkCore: PeripheralCore, BackupLink {

    /// Current backup link state.
    public var state: BackupLinkState = .unsettled

    public var radioConfiguration: EnumSetting<RadioConfiguration> {
        return _radioConfiguration
    }

    public var frequency: BackupLinkFrequencySetting {
        return _frequency
    }

    /// Core implementation of the silent setting.
    private var _radioConfiguration: EnumSettingCore<RadioConfiguration>!

    /// Core implementation of the frequency setting.
    private var _frequency: BackupLinkFrequencySettingCore!

    /// Implementation backend.
    private unowned let backend: BackupLinkBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: kill-switch backend
    public init(store: ComponentStoreCore, backend: BackupLinkBackend) {
        self.backend = backend
        super.init(desc: Peripherals.backupLink, store: store)
        _radioConfiguration = EnumSettingCore<RadioConfiguration>(defaultValue: .all,
                                                                  supportedValues: Set(RadioConfiguration.allCases),
                                                                  didChangeDelegate: self,
                                                                  backend: { [unowned self] radioConfiguration in
            return self.backend.set(radioConfiguration: radioConfiguration)
        })
        _frequency = BackupLinkFrequencySettingCore(didChangeDelegate: self) { [unowned self] frequency in
            if let frequency = frequency {
                return self.backend.select(frequency: frequency)
            } else {
                return self.backend.autoSelectFrequency()
            }
        }
    }

    /// Updates current state.
    ///
    /// - Parameter newValue: new backup link state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(state newValue: BackupLinkState) -> BackupLinkCore {
        if state != newValue {
            state = newValue
            markChanged()
        }
        return self
    }

    /// Updates radio configuration.
    ///
    /// - Parameter newValue: new radio configuration links
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(radioConfiguration newValue: RadioConfiguration) -> BackupLinkCore {
        if _radioConfiguration.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates current available frequencies.
    ///
    /// - Parameter newValue: new available frequencies
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(availableFrequencies newValue: BackupLinkFrequencySelectionMode)
    -> BackupLinkCore {
        if _frequency.update(availableFrequencies: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates frequency.
    ///
    /// - Parameter newValue: new frequency
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(frequency newValue: Int) -> BackupLinkCore {
        if _frequency.update(frequency: newValue) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> BackupLinkCore {
        _radioConfiguration.cancelRollback { markChanged() }
        _frequency.cancelRollback { markChanged() }
        return self
    }
}
