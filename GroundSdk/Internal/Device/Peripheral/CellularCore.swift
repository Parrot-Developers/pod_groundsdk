// Copyright (C) 2020 Parrot Drones SAS
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

/// Cellular backend part.
public protocol CellularBackend: AnyObject {
    /// Sets cellular mode
    ///
    /// - Parameter mode: the new cellular mode
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(mode: CellularMode) -> Bool

    /// Sets roaming allowed
    ///
    /// - Parameter isRoamingAllowed: the new roaming allowed value
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(isRoamingAllowed: Bool) -> Bool

    /// Changes the APN configuration parameters
    ///
    /// - Parameters :
    ///  - isManual: APN mode
    ///  - url: APN url
    ///  - username: APN username
    ///  - password: APN password
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(apnConfiguration: (isManual: Bool, url: String, username: String, password: String)) -> Bool

    /// Sets network mode
    ///
    /// - Parameter networkMode: the new network mode
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(networkMode: CellularNetworkMode) -> Bool

    /// Enters PIN to unlock SIM card
    ///
    /// - Parameter pincode: the pincode to submit
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func enterPinCode(pincode: String) -> Bool

    /// Resets cellular settings and reboots the product if it is not flying.
    ///
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func resetSettings() -> Bool
}

/// Network mode setting implementation
class CellularNetworkModeSettingCore: CellularNetworkModeSetting, CustomDebugStringConvertible {
    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    /// Current mode
    var value: CellularNetworkMode {
        get {
            return _value
        }
        set {
            if _value != newValue {
                if backend(newValue) {
                    let oldValue = _value
                    // value sent to the backend, update setting value and mark it updating
                    _value = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(networkMode: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }

    /// Network mode
    private var _value: CellularNetworkMode = .auto
    /// Closure to call to change the value
    private let backend: ((CellularNetworkMode) -> Bool)

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (CellularNetworkMode) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, updates the current mode data.
    ///
    /// - Parameter mode: new network mode
    /// - Returns: true if the setting has been changed, false else
    func update(networkMode newNetworkMode: CellularNetworkMode) -> Bool {
        if updating || _value != newNetworkMode {
            _value = newNetworkMode
            timeout.cancel()
            return true
        }
        return false
    }

    /// Cancels any pending rollback.
    ///
    /// - Parameter completionClosure: block that will be called if a rollback was pending
    func cancelRollback(completionClosure: () -> Void) {
        if timeout.isScheduled {
            timeout.cancel()
            completionClosure()
        }
    }

    /// Debug description
    var debugDescription: String {
        return "networkMode: \(_value) updating: [\(updating)]"
    }
}

/// Cellular Mode parameter
class CellularModeSettingCore: CellularModeSetting, CustomStringConvertible {

    /// Delegate called when the setting value is changed by setting `value` property.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { return timeout.isScheduled }

    var value: CellularMode {
        get {
            return _value
        }

        set {
            if _value != newValue {
                if backend(newValue) {
                    let oldValue = _value
                    // value sent to the backend, update setting value and mark it updating
                    _value = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(value: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }

    /// Current cellular mode value.
    private var _value: CellularMode = .disabled
    /// Closure to call to change the value. Return true if the new value has been sent and setting must become updating
    private let backend: (CellularMode) -> Bool

    /// Constructor.
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting `value` property
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (CellularMode) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, updates the setting data.
    ///
    /// - Parameter value: new mode value
    /// - Returns: true if the setting has been changed, false otherwise
    func update(value newValue: CellularMode) -> Bool {
        if updating || _value != newValue {
            _value = newValue
            timeout.cancel()
            return true
        }
        return false
    }

    /// Cancels any pending rollback.
    ///
    /// - Parameter completionClosure: block that will be called if a rollback was pending
    func cancelRollback(completionClosure: () -> Void) {
        if timeout.isScheduled {
            timeout.cancel()
            completionClosure()
        }
    }

    // CustomStringConvertible concordance
    var description: String {
        return "CellularModeSetting: \(_value)  updating: [\(updating)]"
    }
}

/// APN configuration setting implementation.
class ApnConfigurationSettingCore: ApnConfigurationSetting, CustomStringConvertible {

    /// Delegate called when the setting is changed by setting properties.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { return timeout.isScheduled }

    /// Closure to call to change the value.
    private let backend: (_ isManual: Bool, _ url: String, _ username: String, _ password: String) -> Bool

    private(set) var isManual = false

    private(set) var url = ""

    private(set) var username = ""

    private(set) var password = ""

    /// Constructor.
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate,
         changeConfigBackend: @escaping (_ isManual: Bool, _ url: String,
                                         _ username: String, _ password: String) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = changeConfigBackend
    }

    func setToAuto() -> Bool {
        return set(isManual: false, url: "", username: "", password: "")
    }

    func setToManual(url: String, username: String, password: String) -> Bool {
        return set(isManual: true, url: url, username: username, password: password)
    }

    /// Sets the APN configuration.
    ///
    /// - Parameters:
    ///     - isManual: `true` if APN is manual, `false` otherwise
    ///     - url: APN url
    ///     - username: APN username
    ///     - password: APN password
    /// - Returns: `true` if the apn configration has been sent, `false` otherwise
    private func set(isManual newIsManual: Bool, url newUrl: String, username newUsername: String,
                     password newPassword: String) -> Bool {

        if isManual != newIsManual || url != newUrl || username != newUsername || password != newPassword {
            if backend(newIsManual, newUrl, newUsername, newPassword) {
                let oldIsManual = isManual
                let oldUrl = url
                let oldUsername = username
                let oldPassword = password
                // value sent to the backend, update setting value and mark it updating
                isManual = newIsManual
                url = newUrl
                username = newUsername
                password = newPassword
                timeout.schedule { [weak self] in
                    if let `self` = self {
                        let isManualUpdated = self.update(isManual: oldIsManual)
                        let urlUpdated = self.update(url: oldUrl)
                        let usernameUpdated = self.update(username: oldUsername)
                        let passwordUpdated = self.update(password: oldPassword)
                        if isManualUpdated || urlUpdated || usernameUpdated || passwordUpdated {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                }
                didChangeDelegate.userDidChangeSetting()
                return true
            }
        }
        return false
    }

    /// Called by the backend, updates manual flag.
    ///
    /// - Parameter isManual: new isManual value
    /// - Returns: true if the setting has been changed, false else
    func update(isManual newIsManual: Bool) -> Bool {
        if updating || isManual != newIsManual {
            isManual = newIsManual
            timeout.cancel()
            return true
        }
        return false
    }

    /// Called by the backend, updates url.
    ///
    /// - Parameter url: new url value
    /// - Returns: true if the setting has been changed, false else
    func update(url newUrl: String) -> Bool {
        if updating || url != newUrl {
            url = newUrl
            timeout.cancel()
            return true
        }
        return false
    }

    /// Called by the backend, updates username.
    ///
    /// - Parameter username: new username value
    /// - Returns: true if the setting has been changed, false else
    func update(username newUsername: String) -> Bool {
        if updating || username != newUsername {
            username = newUsername
            timeout.cancel()
            return true
        }
        return false
    }

    /// Called by the backend, updates password.
    ///
    /// - Parameter password: new password value
    /// - Returns: true if the setting has been changed, false else
    func update(password newPassword: String) -> Bool {
        if updating || password != newPassword {
            password = newPassword
            timeout.cancel()
            return true
        }
        return false
    }

    /// Cancels any pending rollback.
    ///
    /// - Parameter completionClosure: block that will be called if a rollback was pending
    func cancelRollback(completionClosure: () -> Void) {
        if timeout.isScheduled {
            timeout.cancel()
            completionClosure()
        }
    }

    // CustomStringConvertible concordance
    var description: String {
        "ApnConfigurationSetting: \(isManual), \(url), \(username) updating: [\(updating)]"
    }
}

/// Internal cellular peripheral implementation.
public class CellularCore: PeripheralCore, Cellular {

    public var apnConfigurationSetting: ApnConfigurationSetting {
        return _apnConfigurationSetting
    }

    /// APN Configuration internal implementation.
    private var _apnConfigurationSetting: ApnConfigurationSettingCore!

    /// Cellular mode setting
    public var mode: CellularModeSetting {
        return _mode
    }

    /// Mode setting internal implementation
    private var _mode: CellularModeSettingCore!

    /// Current network status.
    public var networkStatus: CellularNetworkStatus {
        return _networkStatus
    }

    /// Backend network status value.
    private var _networkStatus: CellularNetworkStatus = .deactivated

    /// SIM status.
    public private(set) var simStatus = CellularSimStatus.unknown

    /// SIM serial number.
    public private(set) var simIccid = ""

    /// SIM International Mobile Subscriber Identity (imsi).
    private(set) public var simImsi = ""

    /// Registration status.
    public private(set) var registrationStatus: CellularRegistrationStatus = .notRegistered

    /// Operator.
    public private(set) var `operator`: String = ""

    /// Technology.
    public private(set) var technology: CellularTechnology = .edge

    /// Is roaming allowed.
    public var isRoamingAllowed: BoolSetting {
        return _isRoamingAllowed
    }

    /// Internal storage for is roaming allowed setting.
    private var _isRoamingAllowed: BoolSettingCore!

    /// Network mode setting.
    public var networkMode: CellularNetworkModeSetting {
        return _networkMode
    }

    /// Backend network mode.
    private var _networkMode: CellularNetworkModeSettingCore!

    /// Modem status.
    public private(set) var modemStatus = CellularModemStatus.off

    /// International mobile equipment identity (IMEI).
    private(set) public var imei = ""

    /// Is PIN code requested.
    public private(set)  var isPinCodeRequested = false

    /// Is PIN code invalid.
    public private(set)  var isPinCodeInvalid = false

    /// Remaining PIN code tries.
    private (set) public var pinRemainingTries = 0

    /// Reset state
    public private (set) var resetState = CellularResetState.none

    /// Implementation backend.
    private unowned let backend: CellularBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: Cellular backend
    public init(store: ComponentStoreCore, backend: CellularBackend) {
        self.backend = backend
        super.init(desc: Peripherals.cellular, store: store)
        _mode = CellularModeSettingCore(didChangeDelegate: self) { [unowned self] mode in
            return self.backend.set(mode: mode)
        }
        _apnConfigurationSetting = ApnConfigurationSettingCore(
            didChangeDelegate: self,
            changeConfigBackend: { [unowned self] isManual, url, username, password in
                return self.backend.set(apnConfiguration: (isManual, url, username, password))
        })
        _isRoamingAllowed = BoolSettingCore(didChangeDelegate: self) { [unowned self] newValue in
            return self.backend.set(isRoamingAllowed: newValue)
        }
        _networkMode = CellularNetworkModeSettingCore(didChangeDelegate: self, backend: { [unowned self] networkMode in
            return self.backend.set(networkMode: networkMode)
        })
    }

    public func enterPinCode(pincode: String) -> Bool {
        return self.backend.enterPinCode(pincode: pincode)
    }

    public func resetSettings() -> Bool {
        if resetState == .none && backend.resetSettings() {
            resetState = .ongoing
            markChanged()
            notifyUpdated()
            return true
        }
        return false
    }
}

extension CellularCore {
    /// Updates current mode.
    ///
    /// - Parameter mode: new cellular mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(mode newValue: CellularMode) -> CellularCore {
        if _mode.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates the SIM status.
    ///
    /// - Parameter newStatus: new SIM status value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(simStatus newStatus: CellularSimStatus) -> CellularCore {
        if simStatus != newStatus {
            simStatus = newStatus
            markChanged()
        }
        return self
    }

    /// Updates the SIM serial number.
    ///
    /// - Parameter simIccid: new SIM serial number
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(simIccid newValue: String) -> CellularCore {
        if newValue != simIccid {
            simIccid = newValue
            markChanged()
        }
        return self
    }

    /// Updates the SIM IMSI.
    ///
    /// - Parameter simImsi: new SIM IMSI
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(simImsi newValue: String) -> CellularCore {
        if newValue != simImsi {
            simImsi = newValue
            markChanged()
        }
        return self
    }

    /// Updates the registration status.
    ///
    /// - Parameter registrationStatus: new registration status
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(registrationStatus newRegistrationStatus: CellularRegistrationStatus)
        -> CellularCore {
            if registrationStatus != newRegistrationStatus {
                registrationStatus = newRegistrationStatus
                markChanged()
            }
            return self
    }

    /// Updates the operator.
    ///
    /// - Parameter `operator`: new operator
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(`operator` newValue: String) -> CellularCore {
        if newValue != `operator` {
            `operator` = newValue
            markChanged()
        }
        return self
    }

    /// Updates the network mode.
    ///
    /// - Parameter networkMode: new network mode
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(networkMode newNetworkMode: CellularNetworkMode)
        -> CellularCore {
            if _networkMode.update(networkMode: newNetworkMode) {
                markChanged()
            }
            return self
    }

    /// Updates the network status.
    ///
    /// - Parameter networkStatus: new network status
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(networkStatus newNetworkStatus: CellularNetworkStatus)
        -> CellularCore {
            if _networkStatus != newNetworkStatus {
                _networkStatus = newNetworkStatus
                markChanged()
            }
            return self
    }

    /// Updates the is APN manual flag.
    ///
    /// - Parameter isApnManual:new value of is APN manual
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(isApnManual newValue: Bool) -> CellularCore {
        if _apnConfigurationSetting.update(isManual: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates current APN url.
    ///
    /// - Parameter apnUrl: new APN url
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(apnUrl newValue: String) -> CellularCore {
        if _apnConfigurationSetting.update(url: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates current APN username.
    ///
    /// - Parameter apnUsername: new APN username
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(apnUsername newValue: String) -> CellularCore {
        if _apnConfigurationSetting.update(username: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates current APN password.
    ///
    /// - Parameter apnPassword: new APN password
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(apnPassword newValue: String) -> CellularCore {
        if _apnConfigurationSetting.update(password: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates the is roaming allowed flag.
    ///
    /// - Parameter isRoamingAllowed: new value of is roaming allowed
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(isRoamingAllowed newValue: Bool) -> CellularCore {
        if _isRoamingAllowed.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates the modem status.
    ///
    /// - Parameter modemStatus: new modem status
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(modemStatus newModemStatus: CellularModemStatus)
        -> CellularCore {
            if modemStatus != newModemStatus {
                modemStatus = newModemStatus
                markChanged()
            }
            return self
    }

    /// Updates the IMEI.
    ///
    /// - Parameter imei: new IMEI
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(imei newValue: String) -> CellularCore {
        if newValue != imei {
            imei = newValue
            markChanged()
        }
        return self
    }

    /// Updates the technology.
    ///
    /// - Parameter technology: new technology
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(technology newTechnology: CellularTechnology)
        -> CellularCore {
            if technology != newTechnology {
                technology = newTechnology
                markChanged()
            }
            return self
    }

    /// Updates whether the PIN code is requested or not.
    ///
    /// - Parameter isPinCodeRequested: new is PIN code requested value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(isPinCodeRequested newValue: Bool) -> CellularCore {
        if isPinCodeRequested != newValue {
            isPinCodeRequested = newValue
            markChanged()
        }
        return self
    }

    /// Updates whether the entered PIN code is invalid.
    ///
    /// - Parameter isPinCodeInvalid: new is PIN code invalid value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(isPinCodeInvalid newValue: Bool) -> CellularCore {
        if isPinCodeInvalid != newValue {
            isPinCodeInvalid = newValue
            markChanged()
        }
        return self
    }

    /// Updates the PIN remaining tries value.
    ///
    /// - Parameter pinRemainingTries: new PIN remaining tries
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(pinRemainingTries newValue: Int) -> CellularCore {
        if pinRemainingTries != newValue {
            pinRemainingTries = newValue
            markChanged()
        }
        return self
    }

    /// Updates the reset state.
    ///
    /// - Parameter resetState: new reset state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(resetState newValue: CellularResetState) -> CellularCore {
        if resetState != newValue {
            resetState = newValue
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - note: changes are not notified until notifyUpdated() is called
    @discardableResult public func cancelSettingsRollback() -> CellularCore {
        _apnConfigurationSetting.cancelRollback { markChanged() }
        _mode.cancelRollback { markChanged() }
        _isRoamingAllowed.cancelRollback { markChanged() }
        _networkMode.cancelRollback { markChanged() }
        return self
    }
}
