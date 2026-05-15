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

/// Core implementation of the slave (station) security setting.
class SlaveSecuritySettingCore<ModeType: Hashable> {

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { return timeout.isScheduled }

    /// Supported security modes.
    private(set) var supportedModes: Set<ModeType> = []

    /// Current security mode.
    private(set) var mode: ModeType

    /// Open security mode value.
    private let openValue: ModeType

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes.
    let timeout = SettingTimeout()

    /// Timeout for update rollback.
    let timeoutDuration: DispatchTimeInterval

    /// Delegate called when the setting value is changed by setting `mode` property.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Closure to call to change the value.
    private let backend: (ModeType, String?) -> Bool

    /// Constructor.
    ///
    /// - Parameters:
    ///   - openValue: open security mode value
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting `value` property
    ///   - timeout: timeout for update rollback
    ///   - backend: closure to call to change the setting value
    init(openValue: ModeType, didChangeDelegate: SettingChangeDelegate,
         timeout: DispatchTimeInterval = SettingTimeout.defaultTimeout,
         backend: @escaping (ModeType, String?) -> Bool) {
        self.openValue = openValue
        self.mode = openValue
        self.didChangeDelegate = didChangeDelegate
        self.timeoutDuration = timeout
        self.backend = backend
    }

    func open() {
        guard supportedModes.contains(openValue) else {
            return
        }
        if mode != openValue {
            if backend(openValue, nil) {
                let oldMode = mode
                mode = openValue
                timeout.schedule(timeout: timeoutDuration) { [weak self] in
                    if let `self` = self, self.update(mode: oldMode) {
                        self.didChangeDelegate.userDidChangeSetting()
                    }
                }
                didChangeDelegate.userDidChangeSetting()
            }
        }
    }

    func secure(with mode: ModeType, password: String) {
        guard mode != openValue,
              supportedModes.contains(mode) else {
            return
        }

        if backend(mode, password) {
            let oldMode = self.mode
            self.mode = mode
            timeout.schedule(timeout: timeoutDuration) { [weak self] in
                if let `self` = self, self.update(mode: oldMode) {
                    self.didChangeDelegate.userDidChangeSetting()
                }
            }
            didChangeDelegate.userDidChangeSetting()
        }
    }

    /// Updates supported modes.
    ///
    /// - Parameter supportedModes: new supported modes
    /// - Returns: `true` if supported modes have changed, `false` otherwise
    func update(supportedModes newSupportedModes: Set<ModeType>) -> Bool {
        if supportedModes != newSupportedModes {
            supportedModes = newSupportedModes
            return true
        }
        return false
    }

    /// Updates current mode.
    ///
    /// - Parameter mode: the new security mode
    /// - Returns: `true` if the setting has been changed, `false` otherwise
    func update(mode newValue: ModeType) -> Bool {
        if updating || mode != newValue {
            mode = newValue
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
