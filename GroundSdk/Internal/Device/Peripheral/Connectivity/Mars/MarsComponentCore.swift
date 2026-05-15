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

/// Mars component backend.
public protocol MarsComponentBackend: AnyObject {

    /// Sets the component activation status.
    ///
    /// - Parameter active: `true` to activate the component, `false` to deactivate it
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(active: Bool) -> Bool

    /// Sets the component environment.
    ///
    /// - Parameter environment: new environment
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(environment: Environment) -> Bool

    /// Sets the component country.
    ///
    /// - Parameter country: new country
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(country: Country) -> Bool

    /// Sets the component channel.
    ///
    /// - Parameter channel: new channel
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func select(channel: MarsChannel) -> Bool

    /// Requests auto-selection of the most appropriate channel.
    ///
    /// - Parameter bands: frequency bands to restrict auto-selection.
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func autoSelectChannel(onBands bands: Set<MarsBand>) -> Bool

    /// Requests auto-selection of the most appropriate RX/TX channels.
    ///
    /// - Parameters:
    ///   - rxChannels: channels to restrict RX channel auto-selection to
    ///   - txChannels: channels to restrict TX channel auto-selection to
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func autoSelectChannel(rxChannels: Set<MarsChannel>, txChannels: Set<MarsChannel>) -> Bool
}

/// Internal implementation of a Mars component.
public class MarsComponentCore: PeripheralCore {

    /// Default timeout for all Mars settings, which may take a long time to update on the device side.
    static let settingTimeout: DispatchTimeInterval = .seconds(10)

    /// Component activation setting.
    public var active: BoolSetting {
        return _active
    }

    /// Component indoor/outdoor environment setting.
    public var environment: EnumSetting<Environment> {
        return _environment
    }

    /// Component country setting.
    public var country: EnumSetting<Country> {
        return _country
    }

    /// Component channel setting.
    public var channel: MarsChannelSetting {
        return _channel
    }

    /// Core implementation of the active setting.
    private var _active: BoolSettingCore!

    /// Core implementation of the environment setting.
    private var _environment: EnumSettingCore<Environment>!

    /// Core implementation of the country setting.
    private var _country: EnumSettingCore<Country>!

    /// Core implementation of the channel setting.
    private var _channel: MarsChannelSettingCore!

    /// Implementation backend.
    unowned let backend: MarsComponentBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///   - desc: peripheral component descriptor
    ///   - store: store where this peripheral will be stored
    ///   - backend: component backend
    init(desc: ComponentDescriptor, store: ComponentStoreCore, backend: MarsComponentBackend) {
        self.backend = backend
        super.init(desc: desc, store: store)

        _active = BoolSettingCore(didChangeDelegate: self,
                                  timeout: MarsComponentCore.settingTimeout) { [unowned self] active in
            return self.backend.set(active: active)
        }
        _environment = EnumSettingCore(defaultValue: .outdoor,
                                       supportedValues: Set(Environment.allCases),
                                       didChangeDelegate: self,
                                       timeout: MarsComponentCore.settingTimeout) { [unowned self] environment in
            return self.backend.set(environment: environment)
        }
        _country = EnumSettingCore(defaultValue: .andorra,
                                   didChangeDelegate: self,
                                   timeout: MarsComponentCore.settingTimeout) { [unowned self] country in
            return self.backend.set(country: country)
        }
        _channel = MarsChannelSettingCore(didChangeDelegate: self) { [unowned self] mode, channel in
            switch mode {
            case .manual:
                if let channel = channel {
                    return self.backend.select(channel: channel)
                }
                return false
            case .autoOnBands(let bands):
                return self.backend.autoSelectChannel(onBands: bands)
            case .autoOnChannels(let rxChannels, let txChannels):
                return self.backend.autoSelectChannel(rxChannels: rxChannels, txChannels: txChannels)
            }
        }
    }

    // MARK: Backend callback methods.

    /// Changes activation status.
    ///
    /// - Parameter newValue: new activation status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(active newValue: Bool) -> MarsComponentCore {
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
    @discardableResult public func update(supportedEnvironments newValue: Set<Environment>) -> MarsComponentCore {
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
    @discardableResult public func update(environment newValue: Environment) -> MarsComponentCore {
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
    @discardableResult public func update(supportedCountries newValue: Set<Country>) -> MarsComponentCore {
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
    @discardableResult public func update(country newValue: Country) -> MarsComponentCore {
        if _country.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes current channel selection mode.
    ///
    /// - Parameter newValue: new channel selection mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(channelSelectionMode newValue: MarsChannelSelectionMode)
    -> MarsComponentCore {
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
    @discardableResult public func update(availableChannels newValue: Set<MarsChannel>) -> MarsComponentCore {
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
    @discardableResult public func update(channel newValue: MarsChannel) -> MarsComponentCore {
        if _channel.update(channel: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes current available bands.
    ///
    /// - Parameter newValue: new available bands
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(availableBands newValue: Set<MarsBand>) -> MarsComponentCore {
        if _channel.update(availableBands: newValue) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> MarsComponentCore {
        _active.cancelRollback { markChanged() }
        _environment.cancelRollback { markChanged() }
        _country.cancelRollback { markChanged() }
        _channel.cancelRollback { markChanged() }
        return self
    }
}
