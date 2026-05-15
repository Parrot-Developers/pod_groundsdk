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

/// Wifi access point backend.
public protocol WifiAccessPointBackend: WifiComponentBackend {

    /// Sets the access point channel.
    ///
    /// - Parameter channel: new channel
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func select(channel: WifiChannel) -> Bool

    /// Requests auto-selection of the most appropriate access point channel.
    ///
    /// - Parameter band: frequency band to restrict auto-selection to, use `nil` to allow any band
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func autoSelectChannel(onBand band: Band?) -> Bool

    /// Sets the access point security.
    ///
    /// - Parameters:
    ///   - security: new security modes
    ///   - password: password used to secure the access point, use `nil` for `.open` security mode
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(security: Set<SecurityMode>, password: String?) -> Bool
}

/// Implementation of the access point security setting for Wifi.
private class SecurityModeSettingCore: MasterSecuritySettingCore<SecurityMode>, SecurityModeSetting {

    var mode: SecurityMode {
        if let mode = modes.first {
            return mode
        }
        return .open
    }

    func secureWithWpa2(password: String) -> Bool {
        return secure(with: [.wpa2Secured], password: password)
    }
}

/// Internal implementation of the Wifi access point.
public class WifiAccessPointCore: WifiComponentCore, WifiAccessPoint {

    public var isoCountryCode: StringSetting {
        return _isoCountryCode
    }

    public private(set) var defaultCountryUsed = false

    public var availableCountries: Set<String> {
        // add the current country
        var availableCountries = Set(country.supportedValues.map { $0.rawValue })
        if isoCountryCode.value != "" {
            availableCountries.insert(isoCountryCode.value)
        }
        return availableCountries
    }

    public var channel: ChannelSetting {
        return _channel
    }

    public var security: SecurityModeSetting {
        return _security
    }

    /// Core implementation of the country code setting.
    private var _isoCountryCode: StringSettingCore!

    /// Core implementation of the channel setting.
    private var _channel: ChannelSettingCore!

    /// Core implementation of the security setting.
    private var _security: SecurityModeSettingCore!

    /// Implementation backend.
    private var wifiBackend: WifiAccessPointBackend {
        return backend as! WifiAccessPointBackend
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored
    ///   - backend: wifi access point backend
    public init(store: ComponentStoreCore, backend: WifiAccessPointBackend) {
        super.init(desc: Peripherals.wifiAccessPoint, store: store, backend: backend)

        _isoCountryCode = StringSettingCore(didChangeDelegate: self) { [unowned self] countryCode in
            guard let country = Country(rawValue: countryCode),
                  self.country.supportedValues.contains(country) else {
                return false
            }

            return self.backend.set(country: country)
        }
        _channel = ChannelSettingCore(didChangeDelegate: self) { [unowned self] settingValue in
            switch settingValue {
            case .select(let channel):
                return self.wifiBackend.select(channel: channel)
            case .autoSelectChannel(let band):
                return self.wifiBackend.autoSelectChannel(onBand: band)
            }
        }
        _security = SecurityModeSettingCore(openValue: .open, passwordValidation: WifiPasswordUtil.isValid,
                                            didChangeDelegate: self) { [unowned self] modes, password in
            return self.wifiBackend.set(security: modes, password: password)
        }
    }

    // MARK: Backend callback methods.

    /// Changes current country.
    ///
    /// - Parameter newValue: new country
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public override func update(country newValue: Country) -> WifiAccessPointCore {
        super.update(country: newValue)
        if _isoCountryCode.update(value: newValue.rawValue) {
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

    /// Changes current channel selection mode.
    ///
    /// - Parameter newValue: new channel selection mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(channelSelectionMode newValue: ChannelSelectionMode) -> WifiAccessPointCore {
        if _channel.update(selectionMode: newValue) {
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
        if _channel.update(availableChannels: newValue) {
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
        if _channel.update(channel: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes supported security modes
    ///
    /// - Parameter newValue: new supported security modes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedSecurityModes newValue: Set<SecurityMode>) -> WifiAccessPointCore {
        if _security.update(supportedModes: newValue) {
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
        if _security.update(modes: newValue) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public override func cancelSettingsRollback() -> WifiAccessPointCore {
        super.cancelSettingsRollback()
        _isoCountryCode.cancelRollback { markChanged() }
        _channel.cancelRollback { markChanged() }
        _security.cancelRollback { markChanged() }
        return self
    }
}
