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

/// Wifi component backend.
public protocol WifiComponentBackend: AnyObject {

    /// Sets the component activation status
    ///
    /// - Parameter active: `true` to activate the component, `false` to deactivate it
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(active: Bool) -> Bool

    /// Sets the component environment
    ///
    /// - Parameter environment: new environment
    /// - Returns: true if the value could successfully be set or sent to the device, false otherwise
    func set(environment: Environment) -> Bool

    /// Sets the component country
    ///
    /// - Parameter country: new country
    /// - Returns: true if the value could successfully be set or sent to the device, false otherwise
    func set(country: Country) -> Bool

    /// Sets the component SSID
    ///
    /// - Parameter ssid: new SSID
    /// - Returns: true if the value could successfully be set or sent to the device, false otherwise
    func set(ssid: String) -> Bool

    /// Sets the component SSID broadcast value
    ///
    /// - Parameter ssidBroadcast: `true` to enable SSID broadcast, `false` to disable it
    /// - Returns: true if the value could successfully be set or sent to the device, false otherwise
    func set(ssidBroadcast: Bool) -> Bool
}

/// Internal implementation of a Wifi component.
public class WifiComponentCore: PeripheralCore {

    /// Component activation setting.
    public var active: BoolSetting {
        return _active
    }

    /// Component indoor/outdoor environment setting.
    public var environment: EnvironmentSetting {
        return _environment
    }

    /// Component country setting.
    public var country: EnumSetting<Country> {
        return _country
    }

    /// Component Service Set IDentifier (SSID) setting.
    public var ssid: StringSetting? {
        return _ssid
    }

    /// Component SSID broadcast (hidden network) setting.
    public var ssidBroadcast: BoolSetting {
        return _ssidBroadcast
    }

    /// Core implementation of the active setting.
    private var _active: BoolSettingCore!

    /// Core implementation of the environment setting.
    private var _environment: EnvironmentSettingCore!

    /// Core implementation of the country setting.
    private var _country: EnumSettingCore<Country>!

    /// Core implementation of the ssid setting.
    private var _ssid: StringSettingCore?

    /// Core implementation of the ssid broadcast setting.
    private var _ssidBroadcast: BoolSettingCore!

    /// Implementation backend.
    unowned let backend: WifiComponentBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///   - desc: peripheral component descriptor
    ///   - store: store where this peripheral will be stored
    ///   - backend: component backend
    init(desc: ComponentDescriptor, store: ComponentStoreCore, backend: WifiComponentBackend) {
        self.backend = backend
        super.init(desc: desc, store: store)

        _active = BoolSettingCore(didChangeDelegate: self, timeout: .seconds(10)) { [unowned self] active in
            return self.backend.set(active: active)
        }
        _environment = EnvironmentSettingCore(defaultValue: .outdoor, supportedValues: Set(Environment.allCases),
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
    }

    // MARK: Backend callback methods.

    /// Changes activation status.
    ///
    /// - Parameter newValue: new activation status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(active newValue: Bool) -> WifiComponentCore {
        if _active.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes supported environments.
    ///
    /// - Parameter newValue: new set of supported environments
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedEnvironments newValue: Set<Environment>) -> WifiComponentCore {
        if _environment.update(supportedValues: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes current environment.
    ///
    /// - Parameter newValue: new environment
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(environment newValue: Environment) -> WifiComponentCore {
        if _environment.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes supported countries.
    ///
    /// - Parameter newValue: new set of supported countries
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedCountries newValue: Set<Country>) -> WifiComponentCore {
        if _country.update(supportedValues: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes current country.
    ///
    /// - Parameter newValue: new country
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(country newValue: Country) -> WifiComponentCore {
        if _country.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes current SSID.
    ///
    /// - Parameter newValue: new SSID
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(ssid newValue: String) -> WifiComponentCore {
        if _ssid?.update(value: newValue) == true {
            markChanged()
        }
        return self
    }

    /// Changes SSID broadcast value.
    ///
    /// - Parameter newValue: new SSID broadcast value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(ssidBroadcast newValue: Bool) -> WifiComponentCore {
        if _ssidBroadcast.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Reset ssid setting
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func resetSsid() -> WifiComponentCore {
        if _ssid != nil {
            _ssid = nil
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> WifiComponentCore {
        _active.cancelRollback { markChanged() }
        _environment.cancelRollback { markChanged() }
        _country.cancelRollback { markChanged() }
        _ssid?.cancelRollback { markChanged() }
        _ssidBroadcast.cancelRollback { markChanged() }
        return self
    }
}
