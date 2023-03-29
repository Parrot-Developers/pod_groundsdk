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

/// Kill-switch backend part.
public protocol KillSwitchBackend: AnyObject {
    /// Sets the kill-switch mode.
    ///
    /// - Parameter mode: the new kill-switch mode
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(mode: KillSwitchMode) -> Bool

    /// Sets the kill-switch activation secure message.
    ///
    /// - Parameter secureMessage: the new kill-switch secure message
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(secureMessage: String) -> Bool

    /// Activates kill-switch.
    ///
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func activate() -> Bool
}

/// Kill-switch mode setting implementation.
class KillSwitchModeSettingCore: KillSwitchModeSetting, CustomStringConvertible {

    /// Delegate called when the setting value is changed by setting `value` property.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes.
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { return timeout.isScheduled }

    private(set) var supportedValues: Set<KillSwitchMode> = []

    var value: KillSwitchMode {
        get {
            return _value
        }

        set {
            if _value != newValue && supportedValues.contains(newValue) {
                if backend(newValue) {
                    let oldValue = _value
                    // value sent to the backend, update setting value and mark it updating
                    _value = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(value: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }

    /// Current kill-switch mode value.
    private var _value: KillSwitchMode = .disabled

    /// Closure to call to change the value. Returns `true` if the new value has been sent and setting must become
    /// updating.
    private let backend: (KillSwitchMode) -> Bool

    /// Constructor.
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting `value` property
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (KillSwitchMode) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Updates supported modes.
    ///
    /// - Parameter supportedValues: new supported mode values
    /// - Returns: true if supported modes changed, false otherwise
    func update(supportedValues newSupportedValues: Set<KillSwitchMode>) -> Bool {
        if supportedValues != newSupportedValues {
            supportedValues = newSupportedValues
            return true
        }
        return false
    }

    /// Called by the backend, updates the setting data.
    ///
    /// - Parameter value: new mode value
    /// - Returns: `true` if the setting has been changed, `false` otherwise
    func update(value newValue: KillSwitchMode) -> Bool {
        if updating || _value != newValue {
            _value = newValue
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

    // CustomStringConvertible concordance.
    var description: String {
        return "mode: \(_value) \(supportedValues) updating: [\(updating)]"
    }
}

/// Internal kill-switch peripheral implementation.
public class KillSwitchCore: PeripheralCore, KillSwitch {

    public var mode: KillSwitchModeSetting {
        return _mode
    }

    public var secureMessage: StringSetting {
        return _secureMessage
    }

    public var activatedBy: KillSwitchActivationSource?

    /// Core implementation of the mode setting.
    private var _mode: KillSwitchModeSettingCore!

    /// Core implementation of the secure message setting.
    private var _secureMessage: StringSettingCore!

    /// Implementation backend.
    private unowned let backend: KillSwitchBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: kill-switch backend
    public init(store: ComponentStoreCore, backend: KillSwitchBackend) {
        self.backend = backend
        super.init(desc: Peripherals.killSwitch, store: store)
        _mode = KillSwitchModeSettingCore(didChangeDelegate: self) { [unowned self] mode in
            return self.backend.set(mode: mode)
        }
        _secureMessage = StringSettingCore(didChangeDelegate: self) { [unowned self] newValue in
            return self.backend.set(secureMessage: newValue)
        }
    }

    public func activate() -> Bool {
        backend.activate()
    }
}

extension KillSwitchCore {
    /// Updates supported modes.
    ///
    /// - Parameter supportedModes: new supported kill-switch modes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedModes newSupportedValues: Set<KillSwitchMode>) -> KillSwitchCore {
        if _mode.update(supportedValues: newSupportedValues) {
            markChanged()
        }
        return self
    }

    /// Updates current mode.
    ///
    /// - Parameter mode: new kill-switch mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(mode newValue: KillSwitchMode) -> KillSwitchCore {
        if _mode.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates current secure message.
    ///
    /// - Parameter secureMessage: new kill-switch secure message
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(secureMessage newValue: String) -> KillSwitchCore {
        if _secureMessage.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates the activation source.
    ///
    /// - Parameter activationSource: new kill-switch activation source
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(activationSource newValue: KillSwitchActivationSource?) -> KillSwitchCore {
        if activatedBy != newValue {
            activatedBy = newValue
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> KillSwitchCore {
        _mode.cancelRollback { markChanged() }
        _secureMessage.cancelRollback { markChanged() }
        return self
    }
}
