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

/// Internal camera exposure lock core implementation.
public class Camera2ExposureLockCore: ComponentCore, Camera2ExposureLock {

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Whether the mode has been changed and is waiting for change confirmation.
    public var updating: Bool { timeout.isScheduled }

    /// Supported modes.
    private(set) public var supportedModes: Set<Camera2ExposureLockMode> = []

    /// Closure to call to change the mode.
    private let backend: (_ mode: Camera2ExposureLockMode, _ centerX: Double?, _ centerY: Double?) -> Bool

    public var mode = Camera2ExposureLockMode.none

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: store where this component will be stored
    ///   - backend: closure to call to change the exposure lock mode
    init(store: ComponentStoreCore,
         backend: @escaping (_ mode: Camera2ExposureLockMode, _ centerX: Double?, _ centerY: Double?) -> Bool) {
        self.backend = backend
        super.init(desc: Camera2Components.exposureLock, store: store)
    }

    public func lockOnCurrentValues() {
        set(mode: .currentValues)
    }

    public func lockOnRegion(centerX: Double, centerY: Double) {
        set(mode: .region, centerX: centerX, centerY: centerY)
    }

    public func unlock() {
        set(mode: .none)
    }

    /// Change the mode from the api.
    ///
    /// - Parameters:
    ///   - newMode: the new mode to set
    ///   - centerX: horizontal position of lock exposure region when `newMode` is `region`
    ///   - centerY: vertical position of lock exposure region when `newMode` is `region`
    private func set(mode newMode: Camera2ExposureLockMode, centerX: Double? = nil, centerY: Double? = nil) {
        if (mode != newMode) || (newMode == .region),
            supportedModes.contains(newMode) {
            if backend(newMode, centerX, centerY) {
                let oldMode = mode
                // value sent to the backend, update setting value and mark it updating
                mode = newMode
                timeout.schedule { [weak self] in
                    if let `self` = self, self._update(mode: oldMode) {
                        self.userDidChangeSetting()
                    }
                }
                userDidChangeSetting()
            }
        }
    }

    /// Changes the current mode.
    ///
    /// - Parameter mode: new mode
    /// - Returns: true if the mode has been changed, false otherwise
    private func _update(mode newMode: Camera2ExposureLockMode) -> Bool {
        if updating || mode != newMode {
            mode = newMode
            timeout.cancel()
            return true
        }
        return false
    }
}

/// Backend callback methods.
extension Camera2ExposureLockCore {
    /// Sets supported modes.
    ///
    /// - Parameter supportedModes: new supported modes
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func update(supportedModes newSupportedModes: Set<Camera2ExposureLockMode>) -> Camera2ExposureLockCore {
        if supportedModes != newSupportedModes {
            supportedModes = newSupportedModes
            markChanged()
        }
        return self
    }

    /// Changes the current mode.
    ///
    /// - Parameter newMode: new mode
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func update(mode newMode: Camera2ExposureLockMode) -> Camera2ExposureLockCore {
        if _update(mode: newMode) {
            markChanged()
        }
        return self
    }

    /// Cancels any pending rollback.
    ///
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func cancelRollback() -> Camera2ExposureLockCore {
        if timeout.isScheduled {
            timeout.cancel()
            markChanged()
        }
        return self
    }
}
