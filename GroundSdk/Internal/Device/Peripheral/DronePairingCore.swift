// Copyright (C) 2026 Parrot Drones SAS
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

/// Internal drone pairing peripheral implementation
public class DronePairingCore: PeripheralCore, DronePairing {

    /// Pairing setting
    public var authorization: EnumSetting<PairingAuthorization>? {
        return _authorization
    }

    private var _authorization: EnumSettingCore<PairingAuthorization>?

    /// Implementation backend
    private unowned let backend: PairingBackend

    /// Constructor
    /// 
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: pairing backend
    public init(store: ComponentStoreCore, backend: PairingBackend) {
        self.backend = backend
        super.init(desc: Peripherals.dronePairing, store: store)
    }

    /// Updates supported authorizations
    ///
    /// - Parameter supportedAuthorizations: the new supported authorizations
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedAuthorizations
                                          newSupportedAuthorizations: Set<PairingAuthorization>) -> DronePairingCore {
        if let _authorization {
            if _authorization.update(supportedValues: newSupportedAuthorizations) {
                markChanged()
            }
        } else {
            _authorization = EnumSettingCore(
                defaultValue: .never,
                supportedValues: newSupportedAuthorizations,
                didChangeDelegate: self
            ) { [unowned self] authorization in
                self.backend.setAuthorization(authorization)
            }
            markChanged()
        }
        return self
    }

    /// Updates new authorization
    ///
    /// - Parameter authorization: the new authorization
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(authorization newAuthorization: PairingAuthorization) -> DronePairingCore {
        if _authorization?.update(value: newAuthorization) == true {
            markChanged()
        }
        return self
    }
}
