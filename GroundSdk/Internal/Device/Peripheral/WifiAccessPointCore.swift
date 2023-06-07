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

/// Wifi access point backend
public protocol WifiAccessPointBackend: AnyObject {

    /// Sets the access point activation status
    ///
    /// - Parameter active: `true` to activate the access point, `false` to deactivate it
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(active: Bool) -> Bool

    /// Sets the access point environment
    ///
    /// - Parameter environment: new environment
    /// - Returns: true if the value could successfully be set or sent to the device, false otherwise
    func set(environment: Environment) -> Bool

    /// Sets the access point country
    ///
    /// - Parameter country: new country
    /// - Returns: true if the value could successfully be set or sent to the device, false otherwise
    func set(country: Country) -> Bool

    /// Sets the access point SSID
    ///
    /// - Parameter ssid: new SSID
    /// - Returns: true if the value could successfully be set or sent to the device, false otherwise
    func set(ssid: String) -> Bool

    /// Sets the access point SSID broadcast value
    ///
    /// - Parameter ssidBroadcast: `true` to enable SSID broadcast, `false` to disable it
    /// - Returns: true if the value could successfully be set or sent to the device, false otherwise
    func set(ssidBroadcast: Bool) -> Bool

    /// Sets the access point security
    ///
    /// - Parameters:
    ///   - security: new security modes
    ///   - password: password used to secure the access point, nil for `.open` security mode
    /// - Returns: true if the value could successfully be set or sent to the device, false otherwise
    func set(security: Set<SecurityMode>, password: String?) -> Bool

    /// Sets the access point channel
    ///
    /// - Parameter channel: new channel
    /// - Returns: true if the value could successfully be set or sent to the device, false otherwise
    func select(channel: WifiChannel) -> Bool

    /// Requests auto-selection of the most appropriate access point channel
    ///
    /// - Parameter band: frequency band to restrict auto-selection to, nil to allow any band
    /// - Returns: true if the value could successfully be set or sent to the device, false otherwise
    func autoSelectChannel(onBand band: Band?) -> Bool
}

/// Internal implementation of the Wifi access point
public class WifiAccessPointCore: PeripheralCore, WifiAccessPoint {

    public var active: BoolSetting {
        return activeSetting
    }

    public var environment: EnvironmentSetting {
        return environmentSetting
    }

    public var country: EnumSetting<Country> {
        return countrySetting
    }

    public var isoCountryCode: StringSetting {
        return isoCountryCodeSetting
    }

    public private(set) var defaultCountryUsed = false

    public var availableCountries: Set<String> {
        // add the current country
        var availableCountries = Set(countrySetting.supportedValues.map { $0.rawValue })
        if isoCountryCode.value != "" {
            availableCountries.insert(isoCountryCode.value)
        }
        return availableCountries
    }

    public var ssid: StringSetting {
        return ssidSetting
    }

    public var ssidBroadcast: BoolSetting {
        return ssidBroadcastSetting
    }

    public var security: SecurityModeSetting {
        return securitySetting
    }

    public var channel: ChannelSetting {
        return channelSetting
    }

    /// Core implementation of the active setting
    private var activeSetting: BoolSettingCore!

    /// Core implementation of the environment setting
    private var environmentSetting: EnvironmentSettingCore!

    /// Core implementation of the country setting.
    private var countrySetting: EnumSettingCore<Country>!

    /// Core implementation of the country code setting
    private var isoCountryCodeSetting: StringSettingCore!

    /// Core implementation of the ssid setting
    private var ssidSetting: StringSettingCore!

    /// Core implementation of the ssid broadcast setting
    private var ssidBroadcastSetting: BoolSettingCore!

    /// Core implementation of the channel setting
    private var channelSetting: ChannelSettingCore!

    /// Core implementation of the security setting
    private var securitySetting: SecurityModeSettingCore!

    /// Implementation backend
    private unowned let backend: WifiAccessPointBackend

    /// Constructor
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored
    ///   - backend: wifi access point backend
    public init(store: ComponentStoreCore, backend: WifiAccessPointBackend) {
        self.backend = backend
        super.init(desc: Peripherals.wifiAccessPoint, store: store)
        activeSetting = BoolSettingCore(didChangeDelegate: self) { [unowned self] active in
            return self.backend.set(active: active)
        }
        environmentSetting = EnvironmentSettingCore(defaultValue: .outdoor, supportedValues: Set(Environment.allCases),
                                                    didChangeDelegate: self) { [unowned self] environment in
            return self.backend.set(environment: environment)
        }
        countrySetting = EnumSettingCore(defaultValue: .andorra, didChangeDelegate: self) { [unowned self] country in
            return self.backend.set(country: country)
        }
        isoCountryCodeSetting = StringSettingCore(didChangeDelegate: self) { [unowned self] countryCode in
            guard let country = Country(rawValue: countryCode),
                  self.country.supportedValues.contains(country) else {
                return false
            }

            return self.backend.set(country: country)
        }
        ssidSetting = StringSettingCore(didChangeDelegate: self) { [unowned self] ssid in
            return self.backend.set(ssid: ssid)
        }
        ssidBroadcastSetting = BoolSettingCore(didChangeDelegate: self) { [unowned self] ssidBroadcast in
            return self.backend.set(ssidBroadcast: ssidBroadcast)
        }
        channelSetting = ChannelSettingCore(didChangeDelegate: self) { [unowned self] settingValue in
            switch settingValue {
            case .select(let channel):
                return self.backend.select(channel: channel)
            case .autoSelectChannel(let band):
                return self.backend.autoSelectChannel(onBand: band)
            }
        }
        securitySetting = SecurityModeSettingCore(didChangeDelegate: self) { [unowned self] modes, password in
            return self.backend.set(security: modes, password: password)
        }
    }
}

/// Backend callback methods
extension WifiAccessPointCore {

    /// Changes activation status.
    ///
    /// - Parameter newValue: new activation status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(active newValue: Bool) -> WifiAccessPointCore {
        if activeSetting.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes supported countries.
    ///
    /// - Parameter newValue: new set of supported countries
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedCountries newValue: Set<Country>) -> WifiAccessPointCore {
        if countrySetting.update(supportedValues: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes current country.
    ///
    /// - Parameter newValue: new country
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(country newValue: Country) -> WifiAccessPointCore {
        var updated = countrySetting.update(value: newValue)
        if isoCountryCodeSetting.update(value: newValue.rawValue) || updated {
            markChanged()
        }
        return self
    }

    /// Changes defaultCountryUsed.
    ///
    /// - Parameter newValue: new defaultCountryUsed value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(defaultCountryUsed newValue: Bool) -> WifiAccessPointCore {
        if defaultCountryUsed != newValue {
            defaultCountryUsed = newValue
            markChanged()
        }
        return self
    }

    /// Changes current SSID.
    ///
    /// - Parameter newValue: new SSID
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(ssid newValue: String) -> WifiAccessPointCore {
        if ssidSetting.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes SSID broadcast value.
    ///
    /// - Parameter newValue: new SSID broadcast value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(ssidBroadcast newValue: Bool) -> WifiAccessPointCore {
        if ssidBroadcastSetting.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes current environment.
    ///
    /// - Parameter newValue: new environment
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(environment newValue: Environment) -> WifiAccessPointCore {
        if environmentSetting.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes supported environments.
    ///
    /// - Parameter newValue: new set of supported environments
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedEnvironments newValue: Set<Environment>) -> WifiAccessPointCore {
        if environmentSetting.update(supportedValues: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes current available channels.
    ///
    /// - Parameter newValue: new available channels
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(availableChannels newValue: Set<WifiChannel>) -> WifiAccessPointCore {
        if channelSetting.update(availableChannels: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes current channel.
    ///
    /// - Parameter newValue: new channel
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(channel newValue: WifiChannel) -> WifiAccessPointCore {
        if channelSetting.update(channel: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes whether channel auto selection is supported.
    ///
    /// - Parameter newValue: new value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(autoSelectSupported newValue: Bool) -> WifiAccessPointCore {
        if channelSetting.update(autoSelectSupported: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes current selection mode.
    ///
    /// - Parameter newValue: new selection mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(selectionMode newValue: ChannelSelectionMode) -> WifiAccessPointCore {
        if channelSetting.update(selectionMode: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes current security.
    ///
    /// - Parameter newValue: new security modes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(security newValue: Set<SecurityMode>) -> WifiAccessPointCore {
        if securitySetting.update(modes: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes supported security modes
    ///
    /// - Parameter newValue: new supported security modes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedSecurityModes newValue: Set<SecurityMode>)
    -> WifiAccessPointCore {
        if securitySetting.update(supportedModes: newValue) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> WifiAccessPointCore {
        activeSetting.cancelRollback { markChanged() }
        environmentSetting.cancelRollback { markChanged() }
        countrySetting.cancelRollback { markChanged() }
        isoCountryCodeSetting.cancelRollback { markChanged() }
        ssidSetting.cancelRollback { markChanged() }
        ssidBroadcastSetting.cancelRollback { markChanged() }
        channelSetting.cancelRollback { markChanged() }
        securitySetting.cancelRollback { markChanged() }
        return self
    }
}
