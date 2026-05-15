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

/// Core implementation of the master (access point) security setting.
class MasterSecuritySettingCore<ModeType: Hashable> {

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { return timeout.isScheduled }

    /// Supported security modes.
    private(set) var supportedModes: Set<ModeType> = []

    /// Currently active security modes.
    private(set) var modes: Set<ModeType>

    /// Open security mode value.
    private let openValue: ModeType

    /// Password validation closure.
    private let passwordValidation: (String) -> Bool

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes.
    let timeout = SettingTimeout()

    /// Timeout for update rollback.
    let timeoutDuration: DispatchTimeInterval

    /// Delegate called when the setting value is changed by setting `modes` property.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Closure to call to change the value.
    private let backend: (Set<ModeType>, String?) -> Bool

    /// Constructor.
    ///
    /// - Parameters:
    ///   - openValue: open security mode value
    ///   - passwordValidation: password validation closure
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting `value` property
    ///   - timeout: timeout for update rollback
    ///   - backend: closure to call to change the setting value
    init(openValue: ModeType, passwordValidation: @escaping (String) -> Bool,
         didChangeDelegate: SettingChangeDelegate, timeout: DispatchTimeInterval = SettingTimeout.defaultTimeout,
         backend: @escaping (Set<ModeType>, String?) -> Bool) {
        self.openValue = openValue
        self.modes = [openValue]
        self.passwordValidation = passwordValidation
        self.didChangeDelegate = didChangeDelegate
        self.timeoutDuration = timeout
        self.backend = backend
    }

    func open() {
        guard supportedModes.contains(openValue) else {
            return
        }
        if modes != [openValue] {
            if backend([openValue], nil) {
                let oldModes = modes
                modes = [openValue]
                timeout.schedule(timeout: timeoutDuration) { [weak self] in
                    if let `self` = self, self.update(modes: oldModes) {
                        self.didChangeDelegate.userDidChangeSetting()
                    }
                }
                didChangeDelegate.userDidChangeSetting()
            }
        }
    }

    func secure(with modes: Set<ModeType>, password: String) -> Bool {
        let effectiveModes = modes.filter { $0 != openValue && supportedModes.contains($0) }
        guard !effectiveModes.isEmpty,
              passwordValidation(password) else {
            return false
        }

        if backend(effectiveModes, password) {
            let oldModes = self.modes
            self.modes = effectiveModes
            timeout.schedule(timeout: timeoutDuration) { [weak self] in
                if let `self` = self, self.update(modes: oldModes) {
                    self.didChangeDelegate.userDidChangeSetting()
                }
            }
            didChangeDelegate.userDidChangeSetting()
            return true
        }
        return false
    }

    /// Updates supported modes.
    ///
    /// - Parameter newValue: new supported modes
    /// - Returns: `true` if supported modes have changed, `false` otherwise
    func update(supportedModes newValue: Set<ModeType>) -> Bool {
        if supportedModes != newValue {
            supportedModes = newValue
            return true
        }
        return false
    }

    /// Updates active modes.
    ///
    /// - Parameter newValue: new active modes
    /// - Returns: `true` if the setting has been changed, `false` otherwise
    func update(modes newValue: Set<ModeType>) -> Bool {
        if updating || modes != newValue {
            modes = newValue
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
