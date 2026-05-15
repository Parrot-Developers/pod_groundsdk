// Copyright (C) 2025 Parrot Drones SAS
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

/// ManualPlanePilotingItf backend protocol
public protocol ManualPlanePilotingItfBackend: ActivablePilotingItfBackend {
    /// Starts manual plane mode, activating or deactivating loitering.
    ///
    /// - Parameter loitering: whether to start loitering or not.
    /// - Returns: `true` if the command has been sent
    func start(loitering: Bool) -> Bool

    /// Sets the piloting command roll value
    func set(roll: Int)

    /// Sets the piloting command pitch value
    func set(pitch: Int)

    /// Sets the piloting command throttle value
    func set(throttle: Int)

    /// Sets the piloting command yaw rotation speed value
    func set(yawRotationSpeed: Int)

    /// Sends emergency request
    func emergencyCutOut()

    /// Sends arm request
    func arm()

    /// Sends cancel arming request
    func cancelArming()

    /// Sends land request
    func land()

    /// Sets the assistance mode.
    ///
    /// - Parameter assistanceMode: the new assistance mode
    func set(assistanceMode: AssistanceMode) -> Bool

    /// Sets loiter shape
    ///
    /// - Parameter loiterShape: requested loiter shape
    /// - Returns: `true` if loiter shape has been set, false otherwise.
    func set(loiterShape: LoiterShape) -> Bool

    /// Sets loiter direction
    ///
    /// - Parameter loiterDirection: requested loiter direction
    /// - Returns: `true` if loiter direction has been set, false otherwise.
    func set(loiterDirection: LoiterDirection) -> Bool

    /// Sets loiter radius
    ///
    /// - Parameter loiterRadius: requested loiter radius
    /// - Returns: `true` if loiter radius has been set, false otherwise.
    func set(loiterRadius: Double) -> Bool

    /// Sets the take off hovering altitude
    ///
    /// - Parameter takeoffHoveringAltitude: requested takeoff hovering altitude
    /// - Returns: `true` if take off hovering altitude has been set, false otherwise.
    func set(takeoffHoveringAltitude value: Double) -> Bool

    /// Sets the max yaw rotation speed
    ///
    /// - Parameter maxYawRotationSpeed: requested max yaw rotation speed
    /// - Returns: `true` if max yaw rotation speed has been set, false otherwise.
    func set(maxYawRotationSpeed value: Double) -> Bool
}

/// Internal manual plane piloting interface implementation
public class ManualPlanePilotingItfCore: ActivablePilotingItfCore, ManualPlanePilotingItf {

    private(set) public var takeoffState: TakeoffState?

    public var assistanceMode: EnumSetting<AssistanceMode> {
        return _assistanceMode
    }

    private var _assistanceMode: EnumSettingCore<AssistanceMode>!

    public var loiterShape: EnumSetting<LoiterShape> {
        return _loiterShape
    }

    private var _loiterShape: EnumSettingCore<LoiterShape>!

    public var loiterDirection: EnumSetting<LoiterDirection> {
        return _loiterDirection
    }

    private var _loiterDirection: EnumSettingCore<LoiterDirection>!

    public var loiterRadius: DoubleSetting {
        return _loiterRadius
    }

    private var _loiterRadius: DoubleSettingCore!

    public var takeoffHoveringAltitude: DoubleSetting? {
        return _takeoffHoveringAltitude
    }

    private var _takeoffHoveringAltitude: DoubleSettingCore?

    public var maxYawRotationSpeed: DoubleSetting {
        return _maxYawRotationSpeed
    }

    private var _maxYawRotationSpeed: DoubleSettingCore!

    /// Vehicle type
    public private(set) var vehicleType: VehicleType?

    public func set(pitch: Int) {
        manualPlaneBackend.set(pitch: signedPercentInterval.clamp(pitch))
    }

    public func set(roll: Int) {
        manualPlaneBackend.set(roll: signedPercentInterval.clamp(roll))
    }

    public func set(throttle: Int) {
        manualPlaneBackend.set(throttle: signedPercentInterval.clamp(throttle))
    }

    public func set(yawRotationSpeed: Int) {
        manualPlaneBackend.set(yawRotationSpeed: signedPercentInterval.clamp(yawRotationSpeed))
    }

    public func emergencyCutOut() {
        manualPlaneBackend.emergencyCutOut()
    }

    public func arm() {
        manualPlaneBackend.arm()
    }

    public func cancelArming() {
        manualPlaneBackend.cancelArming()
    }

    public func land() {
        manualPlaneBackend.land()
    }

    public func start(loitering: Bool) -> Bool {
        if state != .unavailable {
            return manualPlaneBackend.start(loitering: loitering)
        }
        return false
    }

    /// Super class backend as ManualPlanePilotingItfBackend
    private var manualPlaneBackend: ManualPlanePilotingItfBackend {
        return backend as! ManualPlanePilotingItfBackend
    }

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this interface will be stored
    ///    - backend: ManualPlanePilotingItf backend
    public init(store: ComponentStoreCore, backend: ManualPlanePilotingItfBackend) {

        super.init(desc: PilotingItfs.manualPlane, store: store, backend: backend)
        _assistanceMode = EnumSettingCore(defaultValue: .assistedAttitude,
                                          supportedValues: Set(AssistanceMode.allCases),
                                          didChangeDelegate: self) { [unowned self] assistanceMode in
            return self.manualPlaneBackend.set(assistanceMode: assistanceMode)
        }
        _loiterShape = EnumSettingCore(defaultValue: .circle,
                                       supportedValues: Set(LoiterShape.allCases),
                                          didChangeDelegate: self) { [unowned self] shape in
            return self.manualPlaneBackend.set(loiterShape: shape)
        }
        _loiterDirection = EnumSettingCore(defaultValue: .clockwise,
                                           supportedValues: Set(LoiterDirection.allCases),
                                          didChangeDelegate: self) { [unowned self] direction in
            return self.manualPlaneBackend.set(loiterDirection: direction)
        }
        _loiterRadius = DoubleSettingCore(didChangeDelegate: self) { radius in
            return self.manualPlaneBackend.set(loiterRadius: radius)
        }

        _maxYawRotationSpeed = DoubleSettingCore(didChangeDelegate: self) { [unowned self] newValue in
            return self.manualPlaneBackend.set(maxYawRotationSpeed: newValue)
        }
    }
}

/// Backend callback methods
extension ManualPlanePilotingItfCore {

    /// Changes supported assistance modes
    ///
    /// - Parameter supportedAssistanceModes: new supported assistance modes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(supportedAssistanceModes newSupportedAssistanceModes: Set<AssistanceMode>)
        -> ManualPlanePilotingItfCore {
        if _assistanceMode.update(supportedValues: newSupportedAssistanceModes) {
            markChanged()
        }
        return self
    }

    /// Updates assistance mode
    ///
    /// - Parameter assistanceMode: new assistance mode.
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(assistanceMode newValue: AssistanceMode) -> ManualPlanePilotingItfCore {
        if _assistanceMode.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates takeoff state
    ///
    /// - Parameter takeoffState: new takeoff state.
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(takeoffState newValue: TakeoffState?) -> ManualPlanePilotingItfCore {
        if takeoffState != newValue {
            takeoffState = newValue
            markChanged()
        }
        return self
    }

    /// Changes supported loiter shapes
    ///
    /// - Parameter newSupportedLoiterShapes: new supported loiter shapes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(supportedLoiterShapes newSupportedLoiterShapes: Set<LoiterShape>)
        -> ManualPlanePilotingItfCore {
            if _loiterShape.update(supportedValues: newSupportedLoiterShapes) {
            markChanged()
        }
        return self
    }

    /// Changes supported loiter directions
    ///
    /// - Parameter supportedLoiterDirections: new supported loiter directions
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(supportedLoiterDirections newSupportedLoiterDirections: Set<LoiterDirection>)
        -> ManualPlanePilotingItfCore {
            if _loiterDirection.update(supportedValues: newSupportedLoiterDirections) {
            markChanged()
        }
        return self
    }

    /// Updates loiter radius
    ///
    /// - Parameter loiterRadius: new loiter radius.
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(loiterRadius newLoiterRadius:(min: Double?, value: Double?, max: Double?))
        -> ManualPlanePilotingItfCore {
            if _loiterRadius.update(min: newLoiterRadius.min, value: newLoiterRadius.value,
                                    max: newLoiterRadius.max) {
            markChanged()
        }
        return self
    }

    /// Updates loiter shape
    ///
    /// - Parameter loiterShape: new loiter shape.
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(loiterShape newValue: LoiterShape) -> ManualPlanePilotingItfCore {
        if _loiterShape.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates loiter direction
    ///
    /// - Parameter loiterMode: new loiter direction.
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(loiterDirection newValue: LoiterDirection) -> ManualPlanePilotingItfCore {
        if _loiterDirection.update(value: newValue) {
            markChanged()
        }
        return self
    }

    /// Changes takeoff hovering altitude
    ///
    /// - Parameter takeoffHoveringAltitude: tuple containing new values. Only not nil values are updated
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(takeoffHoveringAltitude newSetting: (min: Double?, value: Double?,
                                                                               max: Double?))
    -> ManualPlanePilotingItfCore {
        if _takeoffHoveringAltitude == nil {
            _takeoffHoveringAltitude = DoubleSettingCore(didChangeDelegate: self) { [unowned self] newValue in
                self.manualPlaneBackend.set(takeoffHoveringAltitude: newValue)
            }
        }
        if _takeoffHoveringAltitude!.update(min: newSetting.min,
                                            value: newSetting.value, max: newSetting.max) {
            markChanged()
        }
        return self
    }

    /// Updates vehicle type
    ///
    /// - Parameter vehicleType: new vehicle type.
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(vehicleType newValue: VehicleType?) -> ManualPlanePilotingItfCore {
        if vehicleType != newValue {
            vehicleType = newValue
            markChanged()
        }
        return self
    }

    /// Changes maximum yaw rotation speed settings
    ///
    /// - Parameter maxYawRotationSpeed: tuple containing new values. Only not nil values are updated
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(maxYawRotationSpeed newSetting: (min: Double?, value: Double?, max: Double?))
        -> ManualPlanePilotingItfCore {
            if _maxYawRotationSpeed!.update(min: newSetting.min, value: newSetting.value, max: newSetting.max) {
                markChanged()
            }
            return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> ManualPlanePilotingItfCore {
        _assistanceMode.cancelRollback { markChanged() }
        _loiterShape.cancelRollback { markChanged() }
        _loiterDirection.cancelRollback { markChanged() }
        _loiterRadius.cancelRollback { markChanged() }
        _takeoffHoveringAltitude?.cancelRollback { markChanged() }
        _maxYawRotationSpeed.cancelRollback { markChanged() }
        return self
    }
}
