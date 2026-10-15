// Copyright (C) 2026 Parrot Drones SAS
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

/// Vehicle backend part.
public protocol VehicleBackend: AnyObject {
    /// Enables vehicle feature.
    ///
    /// - Parameter value: Whether to enable vehicle or not
    /// - Returns: `true` if the request was forwarded to the drone, otherwise `false`
    func enable(value: Bool) -> Bool

    /// Enables or disables relative guidance.
    ///
    /// - Parameter relativeGuidance: the new relative guidance enable value
    /// - Returns: `true` if the request was forwarded to the drone, otherwise `false`
    func enable(relativeGuidance: Bool) -> Bool

    /// Enables or disables precise calibration.
    ///
    /// - Parameter preciseCalibration: the new precise calibration enable value
    /// - Returns: `true` if the request was forwarded to the drone, otherwise `false`
    func enable(preciseCalibration: Bool) -> Bool

    /// Wipes the files linked to the precise calibration.
    ///
    /// - Returns: `true` if the request was forwarded to the drone, otherwise `false`
    func wipePreciseCalibration() -> Bool

    /// Sets platform type.
    ///
    /// - Parameter platformType: the new platform type
    /// - Returns: `true` if the request was forwarded to the drone, otherwise `false`
    func set(platformType: VehiclePlatformType) -> Bool
}

/// Internal Vehicle peripheral implementation
public class VehicleCore: PeripheralCore, Vehicle {

    public var platformType: EnumSetting<VehiclePlatformType> {
        return _platformType
    }

    /// Core implementation of the platform type setting.
    private var _platformType: EnumSettingCore<VehiclePlatformType>!

    public var relativeGuidance: BoolSetting {
        return _relativeGuidance
    }
    /// Core implementation of the relative guidance setting.
    private var _relativeGuidance: BoolSettingCore!

    public var preciseCalibration: BoolSetting {
        return _preciseCalibration
    }

    /// Core implementation of the precise calibration setting.
    private var _preciseCalibration: BoolSettingCore!

    public var activation: BoolSetting {
        return _activation
    }

    /// Core implementation of the activation setting.
    private var _activation: BoolSettingCore!

    private(set) public var missingRequirements = Set<VehicleRequirement>()

    private(set) public var improvements = Set<VehicleImprovement>()

    private(set) public var maxHorizontalDistance: Double = 0.0

    private(set) public var isRelativeGuidanceModifiable: Bool = false

    private(set) public var notifications = Set<VehicleNotification>()

    public func wipePreciseCalibration() -> Bool {
        return backend.wipePreciseCalibration()
    }

    /// Implementation backend
    private unowned let backend: VehicleBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: Vehicle backend
    public init(store: ComponentStoreCore, backend: VehicleBackend) {
        self.backend = backend
        super.init(desc: Peripherals.vehicle, store: store)
        _platformType = EnumSettingCore(defaultValue: .land, didChangeDelegate: self) { [unowned self] value in
            return self.backend.set(platformType: value)
        }
        _preciseCalibration = BoolSettingCore(didChangeDelegate: self) { [unowned self] value in
            return self.backend.enable(preciseCalibration: value)
        }
        _relativeGuidance = BoolSettingCore(didChangeDelegate: self) { [unowned self] value in
            return self.backend.enable(relativeGuidance: value)
        }
        _activation = BoolSettingCore(didChangeDelegate: self) { [unowned self] value in
            return self.backend.enable(value: value)
        }
    }
}

extension VehicleCore {

    /// Update activation value
    ///
    /// - Parameter activation: new activation value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(activation newValue: Bool) -> VehicleCore {
        if _activation.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Update relative guidance value
    ///
    /// - Parameter relativeGuidance: new relative guidance value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(relativeGuidance newValue: Bool) -> VehicleCore {
        if _relativeGuidance.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Update is relative guidance modifable value
    ///
    /// - Parameter isRelativeGuidanceModifiable: new is relative guidance modifiable value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(isRelativeGuidanceModifiable newValue: Bool) -> VehicleCore {
        if isRelativeGuidanceModifiable != newValue {
            isRelativeGuidanceModifiable = newValue
            markChanged()
        }
        return self
    }

    /// Update precise calibration value
    ///
    /// - Parameter preciseCalibration: new precise calibration value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(preciseCalibration newValue: Bool) -> VehicleCore {
        if _preciseCalibration.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Update set of missing requirements
    ///
    /// - Parameter missingRequirements: new set of missing requirement
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(missingRequirements newValue: Set<VehicleRequirement>)
        -> VehicleCore {
        if missingRequirements != newValue {
            missingRequirements = newValue
            markChanged()
        }
        return self
    }

    /// Update set of improvement
    ///
    /// - Parameter improvements: new set of improvements
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(improvements newValue: Set<VehicleImprovement>)
        -> VehicleCore {
        if improvements != newValue {
            improvements = newValue
            markChanged()
        }
        return self
    }

    /// Update set of notifications
    ///
    /// - Parameter notifications: new set of notifications
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(notifications newValue: Set<VehicleNotification>) -> VehicleCore {
        if notifications != newValue {
            notifications = newValue
            markChanged()
        }
        return self
    }

    /// Update maximum horizontal distance value
    ///
    /// - Parameter maxHorizontalDistance: new maximum horizontal distance authorized
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(maxHorizontalDistance newValue: Double) -> VehicleCore {
        if maxHorizontalDistance != newValue {
            maxHorizontalDistance = newValue
            markChanged()
        }
        return self
    }

    /// Update platform type value
    ///
    /// - Parameter platformType: new platform type value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(platformType newValue: VehiclePlatformType) -> VehicleCore {
        if _platformType.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Update supported platform types value
    ///
    /// - Parameter supportedPlatformTypes: new supported platform types value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedPlatformTypes newValue: Set<VehiclePlatformType>) -> VehicleCore {
        if _platformType.update(supportedValues: newValue) {
            markChanged()
        }
        return self
    }
}
