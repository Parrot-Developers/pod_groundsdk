// Copyright (C) 2022 Parrot Drones SAS
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

/// Debug shell backend part.
public protocol DebugShellBackend: AnyObject {
    /// Sets debug shell state
    ///
    /// - Parameter state: the new debug shell state
    /// - Returns: `true` if the command has been sent, `false` if not connected.
    func set(state: DebugShellState) -> Bool
}

/// Debug shell parameter
class DebugShellStateSettingCore: DebugShellStateSetting, CustomStringConvertible {
    /// Delegate called when the setting value is changed by setting `value` property
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { timeout.isScheduled }

    var value: DebugShellState {
        get { _value }
        set {
            if _value != newValue {
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

    /// Current debug shell state value
    private var _value: DebugShellState = .disabled

    /// Closure to call to change the value. Return true if the new value has been sent and setting
    /// must become updating
    private let backend: (DebugShellState) -> Bool

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting `value`
    ///     property
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate,
         backend: @escaping (DebugShellState) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, change the setting data
    ///
    /// - Parameter value: new state
    /// - Returns: `true` if the setting has been changed, `false` otherwise
    func update(value newValue: DebugShellState) -> Bool {
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
        if timeout.cancel() {
            completionClosure()
        }
    }

    var description: String {
        "DebugShellStateSetting: \(_value)  updating: [\(updating)]"
    }

}

/// Internal Debug Shell peripheral implementation
public class DebugShellCore: PeripheralCore, DebugShell {

    public var state: DebugShellStateSetting { _state }

    /// State setting internal implementation
    private var _state: DebugShellStateSettingCore!

    /// Implementation backend
    private unowned let backend: DebugShellBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: DebugShell backend
    public init(store: ComponentStoreCore, backend: DebugShellBackend) {
        self.backend = backend
        super.init(desc: Peripherals.debugShell, store: store)
        _state = DebugShellStateSettingCore(didChangeDelegate: self) { [unowned self] state in
            self.backend.set(state: state)
        }
    }

    public override var description: String {
        "DebugShell: state = \(state)"
    }
}

/// Backend callback methods
extension DebugShellCore {
    /// Changes current state.
    ///
    /// - Parameter enabled: new value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(state newState: DebugShellState) -> Self {
        if _state.update(value: newState) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func cancelSettingsRollback() -> Self {
        _state.cancelRollback { markChanged() }
        return self
    }
}
