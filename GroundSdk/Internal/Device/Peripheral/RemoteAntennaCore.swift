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

/// Remote antenna backend part.
public protocol RemoteAntennaBackend: AnyObject {

    /// Enables/disables remote antenna feature.
    ///
    /// - Parameter enabled: `true` to enable remote antenna feature, `false` to disable it
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(enabled: Bool) -> Bool

    /// Sets the geographical location of a remote antenna.
    ///
    /// - Parameter location: the location of the remote antenna
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func set(location: CLLocationCoordinate2D) -> Bool

    /// Requests connection to the cloud antenna identified by the given serial number.
    ///
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func connect(serialNumber: String) -> Bool

    /// Requests disconnection from the cloud antenna.
    ///
    /// - Returns: `true` if the command has been sent, `false` otherwise
    func disconnect() -> Bool
}

/// Remote antenna locationl setting implementation.
class RemoteAntennaLocationSettingCore: RemoteAntennaLocationSetting {

    var updating: Bool { return timeout.isScheduled }

    var value: CLLocationCoordinate2D? {
        get {
            return _value
        }
        set {
            /// always send new value, even if it hasn’t changed.
            if let newValue = newValue {
                if backend(newValue) {
                    let oldLocation = _value
                    _value = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(location: oldLocation) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }

    private var _value: CLLocationCoordinate2D?

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes.
    let timeout = SettingTimeout()

    /// Delegate called when the setting value is changed by setting `mode` property.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Closure to call to change the value.
    private let backend: (CLLocationCoordinate2D) -> Bool

    /// Constructor.
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (CLLocationCoordinate2D)
         -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Updates current location.
    ///
    /// - Parameter newValue: the new location
    /// - Returns: `true` if the location has been changed, `false` otherwise
    func update(location newValue: CLLocationCoordinate2D?) -> Bool {
        if _value != newValue || updating {
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
}

/// Internal remote antenna peripheral implementation.
public class RemoteAntennaCore: PeripheralCore, RemoteAntenna {

    public var enabled: BoolSetting {
        return _enabled
    }

    public var state: RemoteAntennaState?

    public var batteryCharge: Int?

    public private(set) var batteryCharging: Bool?

    public private(set) var chargerPlugged: Bool?

    public private(set) var availableBandwidth: UInt64?

    public private(set) var systemInfo: RemoteAntennaSystemInfo?

    public private(set) var discoveredAntennas: [String]?

    public private(set) var heading: Double?

    public private(set) var motorizedSupport: MotorizedSupport?

    public private(set) var motorizedSupportAlarms: Set<MotorizedSupportAlarm> = []

    public var location: RemoteAntennaLocationSetting {
        return _location
    }

    public private(set) var isLocationRequired: Bool?

    /// Core implementation of the enabled setting.
    private var _enabled: BoolSettingCore!

    /// Core implementation of the location setting.
    private var _location: RemoteAntennaLocationSettingCore!

    /// Implementation backend.
    private unowned let backend: RemoteAntennaBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: remote antenna backend
    public init(store: ComponentStoreCore, backend: RemoteAntennaBackend) {
        self.backend = backend
        super.init(desc: Peripherals.remoteAntenna, store: store)
        _enabled = BoolSettingCore(didChangeDelegate: self) { [unowned self] value in
            return self.backend.set(enabled: value)
        }
        _location = RemoteAntennaLocationSettingCore(didChangeDelegate: self) { [unowned self] value in
            return self.backend.set(location: value)
        }
    }

    public func connect(serialNumber: String) -> Bool {
        return backend.connect(serialNumber: serialNumber)
    }

    public func disconnect() -> Bool {
        return backend.disconnect()
    }
}

extension RemoteAntennaCore {

    /// Updates enabled value.
    ///
    /// - Parameter newValue: new enabled value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(enabled newValue: Bool) -> RemoteAntennaCore {
        if _enabled.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates current state.
    ///
    /// - Parameter newValue: new remote antenna state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(state newValue: RemoteAntennaState?) -> RemoteAntennaCore {
        if state != newValue {
            state = newValue
            markChanged()
        }
        return self
    }

    /// Updates current battery charge.
    ///
    /// - Parameter newValue: new battery charge
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(batteryCharge newValue: Int?) -> RemoteAntennaCore {
        if batteryCharge != newValue {
            batteryCharge = newValue
            markChanged()
        }
        return self
    }

    /// Updates current battery charging.
    ///
    /// - Parameter newValue: new battery charging
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(batteryCharging newValue: Bool?) -> RemoteAntennaCore {
        if batteryCharging != newValue {
            batteryCharging = newValue
            markChanged()
        }
        return self
    }

    /// Updates current charger plugged.
    ///
    /// - Parameter newValue: new charger plugged
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(chargerPlugged newValue: Bool?) -> RemoteAntennaCore {
        if chargerPlugged != newValue {
            chargerPlugged = newValue
            markChanged()
        }
        return self
    }

    /// Updates current available bandwidth.
    ///
    /// - Parameter newValue: new available bandwidth
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(availableBandwidth newValue: UInt64?) -> RemoteAntennaCore {
        if availableBandwidth != newValue {
            availableBandwidth = newValue
            markChanged()
        }
        return self
    }

    /// Updates current system info.
    ///
    /// - Parameter newValue: new system info
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(systemInfo newValue: RemoteAntennaSystemInfo?) -> RemoteAntennaCore {
        if systemInfo != newValue {
            systemInfo = newValue
            markChanged()
        }
        return self
    }

    /// Updates discovered antennas.
    ///
    /// - Parameter newValue: new discovered antennas
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(discoveredAntennas newValue: [String]?) -> RemoteAntennaCore {
        if discoveredAntennas != newValue {
            discoveredAntennas = newValue
            markChanged()
        }
        return self
    }

    /// Updates the location of the remote antenna.
    ///
    /// - Parameter newValue: new remote antenna location
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(location newValue: CLLocationCoordinate2D?) -> RemoteAntennaCore {
        if _location.update(location: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates isLocationRequired value.
    ///
    /// - Parameter newValue: new isLocationRequired
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(isLocationRequired newValue: Bool?) -> RemoteAntennaCore {
        if isLocationRequired != newValue {
            isLocationRequired = newValue
            markChanged()
        }
        return self
    }

    /// Updates heading value.
    ///
    /// - Parameter newValue: new heading
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(heading newValue: Double?) -> RemoteAntennaCore {
        if heading != newValue {
            heading = newValue
            markChanged()
        }
        return self
    }

    /// Updates motorized support of remote antenna
    ///
    /// - Parameter newValue: new motorized support
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(motorizedSupport
                                          newValue: MotorizedSupport?) -> RemoteAntennaCore {
        if motorizedSupport != newValue {
            motorizedSupport = newValue
            markChanged()
        }
        return self
    }

    /// Updates motorized support alarms value.
    ///
    /// - Parameter newValue: new motorized support alarms value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(motorizedSupportAlarms
                                          newValue: Set<MotorizedSupportAlarm>) -> RemoteAntennaCore {
        if motorizedSupportAlarms != newValue {
            motorizedSupportAlarms = newValue
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> RemoteAntennaCore {
        _enabled.cancelRollback { markChanged() }
        _location.cancelRollback { markChanged() }
        return self
    }
}
