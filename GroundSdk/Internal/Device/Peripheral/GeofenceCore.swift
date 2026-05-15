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
import CoreLocation

/// Geofence backend part.
public protocol GeofenceBackend: AnyObject {
    /// Sets geofence mode
    ///
    /// - Parameter mode: the new geofence mode
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(mode: GeofenceMode) -> Bool

    /// change the maximum altitude
    func set(maxAltitude value: Double) -> Bool

    /// change the maximum distance
    func set(maxDistance value: Double) -> Bool
}

/// Internal Geofence peripheral implementation
public class GeofenceCore: PeripheralCore, Geofence {

    public var maxAltitude: DoubleSetting {
        return _maxAltitude
    }
    /// maxAltitude setting internal implementation
    private var _maxAltitude: DoubleSettingCore!

    public var maxDistance: DoubleSetting {
        return _maxDistance
    }
    /// maxDistance setting internal implementation
    private var _maxDistance: DoubleSettingCore!

    public var mode: EnumSetting<GeofenceMode> {
        return _mode
    }

    /// Mode setting internal implementation
    private var _mode: EnumSettingCore<GeofenceMode>!

    public private(set) var center: CLLocation?

    public private(set) var isAvailable: Bool?

    /// Implementation backend
    private unowned let backend: GeofenceBackend

    /// Debug description
    public override var description: String {
        return "Geofence: mode = \(mode) maxAltitude = \(maxAltitude) maxDistance = \(maxDistance)]"
    }

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: Geofence backend
    public init(store: ComponentStoreCore, backend: GeofenceBackend) {
        self.backend = backend
        super.init(desc: Peripherals.geofence, store: store)
        _mode = EnumSettingCore(defaultValue: .altitude, supportedValues: Set(GeofenceMode.allCases),
                                didChangeDelegate: self) { [unowned self] mode in
            return self.backend.set(mode: mode)
        }
        _maxAltitude = DoubleSettingCore(didChangeDelegate: self) { [unowned self] newValue in
            return self.backend.set(maxAltitude: newValue)
        }
        _maxDistance = DoubleSettingCore(didChangeDelegate: self) { [unowned self] newValue in
            return self.backend.set(maxDistance: newValue)
        }
    }
}

/// Backend callback methods
extension GeofenceCore {

    /// Update current mode
    ///
    /// - Parameter mode: new geofence mode.
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(mode newValue: GeofenceMode) -> GeofenceCore {
        if _mode.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes maximum altitude settings
    ///
    /// - Parameter maxAltitude: tuple containing new values. Only not nil values are updated
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(maxAltitude newSetting: (min: Double?, value: Double?, max: Double?))
        -> GeofenceCore {
            if _maxAltitude!.update(min: newSetting.min, value: newSetting.value, max: newSetting.max) {
                markChanged()
            }
            return self
    }

    /// Changes maximum distance settings
    ///
    /// - Parameter maxDistance: tuple containing new values. Only not nil values are updated
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(maxDistance newSetting: (min: Double?, value: Double?, max: Double?))
        -> GeofenceCore {
            if _maxDistance!.update(min: newSetting.min, value: newSetting.value, max: newSetting.max) {
                markChanged()
            }
            return self
    }

    /// Update center location
    ///
    /// - Parameter value: new geofence value.
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(center newValue: CLLocation?) -> GeofenceCore {
        if newValue != center {
            center = newValue
            markChanged()
        }
        return self
    }

    /// Update geofence availability
    ///
    /// - Parameter value: new availability value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(isAvailable newValue: Bool?) -> GeofenceCore {
        if newValue != isAvailable {
            isAvailable = newValue
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> GeofenceCore {
        _mode.cancelRollback { markChanged() }
        _maxAltitude.cancelRollback { markChanged() }
        _maxDistance.cancelRollback { markChanged() }
        return self
    }
}
