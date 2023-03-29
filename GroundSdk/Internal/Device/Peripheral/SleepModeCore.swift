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

/// Sleep mode backend part.
public protocol SleepModeBackend: AnyObject {
    /// Sets the secure wake-up message.
    ///
    /// - Parameter wakeupMessage: the new wake-up message
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(wakeupMessage: String) -> Bool

    /// Activates sleep mode.
    ///
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func activate() -> Bool
}

/// Internal sleep mode peripheral implementation.
public class SleepModeCore: PeripheralCore, SleepMode {
    public var wakeupMessage: StringSetting {
        return _wakeupMessage
    }

    public var activationStatus: SleepModeActivationStatus?

    /// Core implementation of the wake-up message setting.
    private var _wakeupMessage: StringSettingCore!

    /// Implementation backend.
    private unowned let backend: SleepModeBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: sleep mode backend
    public init(store: ComponentStoreCore, backend: SleepModeBackend) {
        self.backend = backend
        super.init(desc: Peripherals.sleepMode, store: store)
        _wakeupMessage = StringSettingCore(didChangeDelegate: self) { [unowned self] newValue in
            return self.backend.set(wakeupMessage: newValue)
        }
    }

    public func activate() -> Bool {
        backend.activate()
    }
}

extension SleepModeCore {
    /// Updates current wake-up message.
    ///
    /// - Parameter wakeupMessage: new wake-up message
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(wakeupMessage newValue: String) -> SleepModeCore {
        if _wakeupMessage.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates the sleep mode activation status.
    ///
    /// - Parameter activationStatus: new activation status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(activationStatus newValue: SleepModeActivationStatus?) -> SleepModeCore {
        if activationStatus != newValue {
            activationStatus = newValue
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> SleepModeCore {
        _wakeupMessage.cancelRollback { markChanged() }
        return self
    }
}
