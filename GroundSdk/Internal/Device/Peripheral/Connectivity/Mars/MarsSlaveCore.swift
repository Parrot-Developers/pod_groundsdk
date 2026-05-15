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

/// Mars slave backend part.
public protocol MarsSlaveBackend: MarsComponentBackend {

    /// Sets the slave security.
    ///
    /// - Parameters:
    ///   - security: new security mode
    ///   - password: password for secure connection, use `nil` for `.open` security mode
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(security: MarsSecurityMode, password: String?) -> Bool
}

/// Extension adding MarsSlaveSecuritySetting conformance.
extension SlaveSecuritySettingCore<MarsSecurityMode>: MarsSlaveSecuritySetting { }

/// Internal Mars slave peripheral implementation.
public class MarsSlaveCore: MarsComponentCore, MarsSlave {

    public var security: MarsSlaveSecuritySetting {
        return _security
    }

    /// Core implementation of the security setting.
    private var _security: SlaveSecuritySettingCore<MarsSecurityMode>!

    /// Implementation backend.
    private var marsBackend: MarsSlaveBackend {
        return backend as! MarsSlaveBackend
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored
    ///   - backend: mars slave backend
    public init(store: ComponentStoreCore, backend: MarsSlaveBackend) {
        super.init(desc: Peripherals.marsSlave, store: store, backend: backend)

        _security = SlaveSecuritySettingCore<MarsSecurityMode>(
            openValue: .open, didChangeDelegate: self,
            timeout: MarsComponentCore.settingTimeout) { [unowned self] mode, password in
                return self.marsBackend.set(security: mode, password: password)
            }
    }

    // MARK: Backend callback methods.

    /// Updates supported security modes.
    ///
    /// - Parameter newValue: new supported security modes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedSecurityModes newValue: Set<MarsSecurityMode>)
    -> MarsSlaveCore {
        if _security.update(supportedModes: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates current security.
    ///
    /// - Parameter newValue: new security mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(security newValue: MarsSecurityMode) -> MarsSlaveCore {
        if _security.update(mode: newValue) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public override func cancelSettingsRollback() -> MarsSlaveCore {
        super.cancelSettingsRollback()
        _security.cancelRollback { markChanged() }
        return self
    }
}
