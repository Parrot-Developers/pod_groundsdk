// Copyright (C) 2025 Parrot Drones SAS
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

/// Privacy backend part.
public protocol PrivacyBackend: AnyObject {

    /// Sets the encryption value
    ///
    /// - Parameter encryption: the new encryption value
    func set(encryption: Bool) -> Bool
}

/// Internal privacy peripheral implementation
public class PrivacyCore: PeripheralCore, Privacy {

    /// Encryption state setting
    public var logEncryption: BoolSetting? {
        return _logEncryption
    }

    /// Internal encryption sate state setting
    private var _logEncryption: BoolSettingCore?

    /// implementation backend
    private unowned let backend: PrivacyBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: leds backend
    public init(store: ComponentStoreCore, backend: PrivacyBackend) {
        self.backend = backend
        super.init(desc: Peripherals.privacy, store: store)
    }

    /// Creates the encryption state setting if it doesn't exist yet.
    public func createEncryptionState() {
        if _logEncryption == nil {
            _logEncryption = BoolSettingCore(didChangeDelegate: self) { [unowned self] newState in
                return self.backend.set(encryption: newState)
            }
            markChanged()
        }
    }

    /// Updates the flight logs encryption state
    ///
    /// - Parameter newState: the new flight logs encryption state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(encryptionState newState: Bool) -> PrivacyCore {
        createEncryptionState()
        if _logEncryption!.update(value: newState) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - note: changes are not notified until notifyUpdated() is called
    @discardableResult public func cancelSettingsRollback() -> PrivacyCore {
        _logEncryption?.cancelRollback { markChanged() }
        return self
    }
}
