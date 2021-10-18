// Copyright (C) 2020 Parrot Drones SAS
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

/// Camera white balance lock core implementation.
public class Camera2WhiteBalanceLockCore: ComponentCore, Camera2WhiteBalanceLock {

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Whether the mode has been changed and is waiting for change confirmation.
    public var updating: Bool { timeout.isScheduled }

    /// Supported modes.
    private(set) public var supportedModes: Set<Camera2WhiteBalanceLockMode> = []

    /// Current white balance lock mode.
    public var mode: Camera2WhiteBalanceLockMode {
        get {
            _mode
        }
        set {
            if _mode != newValue && supportedModes.contains(newValue) {
                if backend(newValue) {
                    let oldValue = _mode
                    // value sent to the backend, update setting value and mark it updating
                    _mode = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(mode: oldValue) {
                            self.userDidChangeSetting()
                        }
                    }
                    userDidChangeSetting()
                }
            }
        }
    }

    /// White balance lock mode.
    private var _mode: Camera2WhiteBalanceLockMode = .unlocked

    /// Closure to call to change the mode.
    private let backend: ((Camera2WhiteBalanceLockMode) -> Bool)

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: store where this component will be stored
    ///   - backend: closure to call to change the setting value
    init(store: ComponentStoreCore, backend: @escaping (Camera2WhiteBalanceLockMode) -> Bool) {
        self.backend = backend
        super.init(desc: Camera2Components.whiteBalanceLock, store: store)
    }

    /// Changes the current mode.
    ///
    /// - Parameter mode: new white balance lock mode
    /// - Returns: true if the setting has been changed, false otherwise
    func update(mode newMode: Camera2WhiteBalanceLockMode) -> Bool {
        if updating || _mode != newMode {
            _mode = newMode
            timeout.cancel()
            return true
        }
        return false
    }
}

/// Backend callback methods.
extension Camera2WhiteBalanceLockCore {
    /// Sets supported modes.
    ///
    /// - Parameter supportedModes: new supported modes
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func update(supportedModes newSupportedModes: Set<Camera2WhiteBalanceLockMode>)
        -> Camera2WhiteBalanceLockCore {
        if supportedModes != newSupportedModes {
            supportedModes = newSupportedModes
            markChanged()
        }
        return self
    }

    /// Changes the current mode.
    ///
    /// - Parameter mode: new white balance lock mode
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func update(mode newMode: Camera2WhiteBalanceLockMode) -> Camera2WhiteBalanceLockCore {
        if update(mode: newMode) {
            markChanged()
        }
        return self
    }

    /// Cancels any pending rollback.
    ///
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func cancelRollback() -> Camera2WhiteBalanceLockCore {
        if timeout.isScheduled {
            timeout.cancel()
            markChanged()
        }
        return self
    }
}
