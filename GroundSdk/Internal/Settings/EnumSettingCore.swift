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

/// Enum setting implementation.
class EnumSettingCore<EnumType: Hashable>: EnumSetting<EnumType>, CustomStringConvertible {

    /// Delegate called when the setting value is changed by setting `value` property.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes.
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    override var updating: Bool { return timeout.isScheduled }

    override var supportedValues: Set<EnumType> {
        _supportedValues
    }

    /// Internal supported values.
    private var _supportedValues: Set<EnumType> = []

    override var value: EnumType {
        get {
            return _value
        }

        set {
            guard _value != newValue, _supportedValues.contains(newValue) else {
                return
            }

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

    /// Current value.
    private var _value: EnumType

    /// Closure to call to change the value. Returns `true` if the new value has been sent and setting must become
    /// updating.
    private let backend: (EnumType) -> Bool

    /// Constructor.
    ///
    /// - Parameters:
    ///   - defaultValue: default setting value
    ///   - supportedValues: default supported values
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting `value` property
    ///   - backend: closure to call to change the setting value
    init(defaultValue: EnumType, supportedValues: Set<EnumType> = [], didChangeDelegate: SettingChangeDelegate,
         backend: @escaping (EnumType) -> Bool) {
        self._value = defaultValue
        self._supportedValues = supportedValues
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Updates supported values.
    ///
    /// - Parameter supportedValues: new supported values
    /// - Returns: true if supported values changed, false otherwise
    func update(supportedValues newSupportedValues: Set<EnumType>) -> Bool {
        if _supportedValues != newSupportedValues {
            _supportedValues = newSupportedValues
            return true
        }
        return false
    }

    /// Called by the backend, updates the setting data.
    ///
    /// - Parameter value: new value
    /// - Returns: `true` if the setting has been changed, `false` otherwise
    func update(value newValue: EnumType) -> Bool {
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
        return "\(_value) \(_supportedValues) [\(updating)]"
    }
}
