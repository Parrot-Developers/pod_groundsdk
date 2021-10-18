// Copyright (C) 2019 Parrot Drones SAS
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

/// Antiflicker backend part.
public protocol AntiflickerBackend: AnyObject {
    /// Sets anti-flickering mode
    ///
    /// - Parameter mode: the new anti-flickering mode
    /// - Returns: `true` if the command has been sent, `false` if not connected
    ///   and the value has been changed immediately
    func set(mode: AntiflickerMode) -> Bool
}

class AntiflickerSettingCore: AntiflickerSetting, CustomDebugStringConvertible {
    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    /// Supported modes
    private(set) var supportedModes: Set<AntiflickerMode> = [.off]
    /// Current mode
    var mode: AntiflickerMode {
        get {
            return _mode
        }
        set {
            if _mode != newValue && supportedModes.contains(newValue) {
                if backend(newValue) {
                    let oldValue = _mode
                    // value sent to the backend, update setting value and mark it updating
                    _mode = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(mode: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }

    /// Antiflicker mode
    private var _mode: AntiflickerMode = .off
    /// Closure to call to change the value
    private let backend: ((AntiflickerMode) -> Bool)

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (AntiflickerMode) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, sets supported modes
    func update(supportedModes newSupportedModes: Set<AntiflickerMode>) -> Bool {
        if supportedModes != newSupportedModes {
            supportedModes = newSupportedModes
            return true
        }
        return false
    }

    /// Called by the backend, change the current mode data
    ///
    /// - Parameter mode: new anti-flickering mode
    /// - Returns: true if the setting has been changed, false else
    func update(mode newMode: AntiflickerMode) -> Bool {
        if updating || _mode != newMode {
            _mode = newMode
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

    /// Debug description
    var debugDescription: String {
        return "mode: \(_mode) \(supportedModes) updating: [\(updating)]"
    }
}

/// Internal Antiflicker peripheral implementation
public class AntiflickerCore: PeripheralCore, Antiflicker {

    /// Antiflicker mode setting
    public var setting: AntiflickerSetting {
        return _setting
    }
    private var _setting: AntiflickerSettingCore!

    /// Actual anti-flickering value. Useful when mode is one of the automatic mode.
    public private(set) var value = AntiflickerValue.unknown

    /// implementation backend
    private unowned let backend: AntiflickerBackend

    /// Debug description
    public override var description: String {
        return "Antiflicker: setting = \(setting) value = \(value)]"
    }

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: Antiflicker backend
    public init(store: ComponentStoreCore, backend: AntiflickerBackend) {
        self.backend = backend
        super.init(desc: Peripherals.antiflicker, store: store)
        _setting = AntiflickerSettingCore(didChangeDelegate: self) { [unowned self] mode in
            return self.backend.set(mode: mode)
        }

    }
}

/// Backend callback methods
extension AntiflickerCore {

    /// Set the Supported modes
    ///
    /// - Parameter supportedModes: new supported modes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedModes newSupportedMode: Set<AntiflickerMode>) -> AntiflickerCore {
        if _setting.update(supportedModes: newSupportedMode) {
            markChanged()
        }
        return self
    }

    /// Update current mode
    ///
    /// - Parameter mode: new anti-flickering mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(mode newMode: AntiflickerMode) -> AntiflickerCore {
        if _setting.update(mode: newMode) {
            markChanged()
        }
        return self
    }

    /// Update current value
    ///
    /// - Parameter value: new anti-flickering value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(value newValue: AntiflickerValue) -> AntiflickerCore {
        if newValue != value {
            value = newValue
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> AntiflickerCore {
        _setting.cancelRollback { markChanged() }
        return self
    }
}

/// Objc support
extension AntiflickerSettingCore: GSAntiflickerSetting {
    func isModeSupported(_ mode: AntiflickerMode) -> Bool {
        return supportedModes.contains(mode)
    }
}

extension AntiflickerCore: GSAntiflicker {
    public var gsSetting: GSAntiflickerSetting {
        return _setting
    }
}
