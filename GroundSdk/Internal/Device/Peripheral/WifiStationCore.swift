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

/// Wifi station backend part.
public protocol WifiStationBackend: AnyObject {

    /// Sets the station activation status.
    ///
    /// - Parameter active: new active value
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(active: Bool) -> Bool

    /// Sets the station environment.
    ///
    /// - Parameter environment: new environment
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(environment: Environment) -> Bool

    /// Sets the station country.
    ///
    /// - Parameter country: new country
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(country: Country) -> Bool

    /// Sets the station SSID.
    ///
    /// - Parameter ssid: new SSID
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(ssid: String) -> Bool

    /// Sets the station SSID broadcast value.
    ///
    /// - Parameter ssidBroadcast: `true` to enable SSID broadcast, `false` to disable it
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(ssidBroadcast: Bool) -> Bool

    /// Sets the station security.
    ///
    /// - Parameters:
    ///   - security: new security mode
    ///   - password: password for secure connection, use `nil` for `.open` security mode
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(security: SecurityMode, password: String?) -> Bool
}

/// Internal wifi station peripheral implementation.
public class WifiStationCore: PeripheralCore, WifiStation {

    public var active: BoolSetting {
        return _active
    }

    public var environment: EnumSetting<Environment> {
        return _environment
    }

    public var country: EnumSetting<Country> {
        return _country
    }

    public var ssid: StringSetting {
        return _ssid
    }

    public var ssidBroadcast: BoolSetting {
        return _ssidBroadcast
    }

    public var security: WifiStationSecuritySetting {
        return _security
    }

    /// Core implementation of the active setting.
    private var _active: BoolSettingCore!

    /// Core implementation of the environment setting.
    private var _environment: EnumSettingCore<Environment>!

    /// Core implementation of the country setting.
    private var _country: EnumSettingCore<Country>!

    /// Core implementation of the SSID setting.
    private var _ssid: StringSettingCore!

    /// Core implementation of the ssid broadcast setting
    private var _ssidBroadcast: BoolSettingCore!

    /// Core implementation of the security setting.
    private var _security: WifiStationSecuritySettingCore!

    /// Implementation backend.
    private unowned let backend: WifiStationBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored
    ///   - backend: wifi station backend
    public init(store: ComponentStoreCore, backend: WifiStationBackend) {
        self.backend = backend
        super.init(desc: Peripherals.wifiStation, store: store)
        _active = BoolSettingCore(didChangeDelegate: self) { [unowned self] active in
            return self.backend.set(active: active)
        }
        _environment = EnumSettingCore(defaultValue: .outdoor, supportedValues: Set(Environment.allCases),
                                       didChangeDelegate: self) { [unowned self] environment in
            return self.backend.set(environment: environment)
        }
        _country = EnumSettingCore(defaultValue: .andorra, didChangeDelegate: self) { [unowned self] country in
            return self.backend.set(country: country)
        }
        _ssid = StringSettingCore(didChangeDelegate: self) { [unowned self] ssid in
            return self.backend.set(ssid: ssid)
        }
        _ssidBroadcast = BoolSettingCore(didChangeDelegate: self) { [unowned self] ssidBroadcast in
            return self.backend.set(ssidBroadcast: ssidBroadcast)
        }
        _security = WifiStationSecuritySettingCore(didChangeDelegate: self) { [unowned self] mode, password in
            return self.backend.set(security: mode, password: password)
       }
    }
}

/// Backend callback methods.
extension WifiStationCore {

    /// Updates activation status.
    ///
    /// - Parameter newValue: new activation status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(active newValue: Bool) -> WifiStationCore {
        if _active.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates current environment.
    ///
    /// - Parameter newValue: new environment
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(environment newValue: Environment) -> WifiStationCore {
        if _environment.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates supported countries.
    ///
    /// - Parameter newValue: new set of supported countries
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedCountries newValue: Set<Country>) -> WifiStationCore {
        if _country.update(supportedValues: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates current country.
    ///
    /// - Parameter newValue: new country
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(country newValue: Country) -> WifiStationCore {
        if _country.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates current SSID.
    ///
    /// - Parameter newValue: new SSID
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(ssid newValue: String) -> WifiStationCore {
        if _ssid.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates SSID broadcast.
    ///
    /// - Parameter newValue: new SSID broadcast value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(ssidBroadcast newValue: Bool) -> WifiStationCore {
        if _ssidBroadcast.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates supported security modes.
    ///
    /// - Parameter newValue: new supported security modes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedSecurityModes newValue: Set<SecurityMode>)
    -> WifiStationCore {
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
    @discardableResult public func update(security newValue: SecurityMode) -> WifiStationCore {
        if _security.update(mode: newValue) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> WifiStationCore {
        _active.cancelRollback { markChanged() }
        _environment.cancelRollback { markChanged() }
        _country.cancelRollback { markChanged() }
        _ssid.cancelRollback { markChanged() }
        _ssidBroadcast.cancelRollback { markChanged() }
        _security.cancelRollback { markChanged() }
        return self
    }
}
