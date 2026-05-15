// Copyright (C) 2019 Parrot Drones SAS
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

/// Leds backend part.
public protocol LedsBackend: AnyObject {
    /// Sets standard LEDs state
    ///
    /// - Parameter standard: the new standard
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(standard: Bool) -> Bool

    /// Sets infrared LEDs state
    ///
    /// - Parameter infrared: the new infrared
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(infrared: Bool) -> Bool

    /// Sets ToF LEDs state
    ///
    /// - Parameter tof: the new ToF
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(tof: Bool) -> Bool
}

/// Internal light switch peripheral implementation
public class LedsCore: PeripheralCore, Leds {

    /// Standard LEDs state setting
    public var standard: BoolSetting? {
        return _standard
    }

    /// Infrared LEDs state setting
    public var infrared: BoolSetting? {
        return _infrared
    }

    /// ToF LEDs state setting
    public var tof: BoolSetting? {
        return _tof
    }

    /// Internal storage for standard LEDs state setting
    private var _standard: BoolSettingCore?

    /// Internal storage for infrared LEDs state setting
    private var _infrared: BoolSettingCore?

    /// Internal storage for ToF LEDs state setting
    private var _tof: BoolSettingCore?

    /// implementation backend
    private unowned let backend: LedsBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: leds backend
    public init(store: ComponentStoreCore, backend: LedsBackend) {
        self.backend = backend
        super.init(desc: Peripherals.leds, store: store)
    }
}

/// Backend callback methods
extension LedsCore {

    /// Creates the standard setting if it doesn't exist yet.
    public func createStandard() {
        if _standard == nil {
            _standard = BoolSettingCore(didChangeDelegate: self) { [unowned self] newValue in
                return self.backend.set(standard: newValue)
            }
            markChanged()
        }
    }

    /// Creates the infrared setting if it doesn't exist yet.
    public func createInfrared() {
        if _infrared == nil {
            _infrared = BoolSettingCore(didChangeDelegate: self) { [unowned self] newValue in
                return self.backend.set(infrared: newValue)
            }
            markChanged()
        }
    }

    /// Creates the ToF setting if it doesn't exist yet.
    public func createTof() {
        if _tof == nil {
            _tof = BoolSettingCore(didChangeDelegate: self) { [unowned self] newValue in
                return self.backend.set(tof: newValue)
            }
            markChanged()
        }
    }

    /// Set the standard LEDs state
    ///
    /// - Parameter standardLedState: tells the standard leds state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(standardLedState newValue: Bool) -> LedsCore {
        createStandard()
        if _standard!.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Set the infrared LEDs state
    ///
    /// - Parameter infraredLedState: tells the infrared leds state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(infraredLedState newValue: Bool) -> LedsCore {
        createInfrared()
        if _infrared!.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Set the ToF LEDs state
    ///
    /// - Parameter tofLedState: tells the ToF leds state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(tofLedState newValue: Bool) -> LedsCore {
        createTof()
        if _tof!.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - note: changes are not notified until notifyUpdated() is called
    @discardableResult public func cancelSettingsRollback() -> LedsCore {
        _standard?.cancelRollback { markChanged() }
        _infrared?.cancelRollback { markChanged() }
        _tof?.cancelRollback { markChanged() }
        return self
    }
}
