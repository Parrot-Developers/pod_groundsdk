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

/// Gimbal backend part.
public protocol GimbalBackend: CalibratableGimbalBackend {
    /// Sets the stabilization on a given axis
    ///
    /// - Parameters:
    ///   - stabilization: whether or not stabilization is wanted
    ///   - axis: the axis
    /// - Returns: true if stabilization change has been asked.
    func set(stabilization: Bool, onAxis axis: GimbalAxis) -> Bool

    /// Sets the max speed on a given axis
    ///
    /// - Parameters:
    ///   - maxSpeed: the desired max speed
    ///   - axis: the axis
    /// - Returns: true if the new max speed has been asked
    func set(maxSpeed: Double, onAxis axis: GimbalAxis) -> Bool

    /// Sets the calibration offset on a given axis
    ///
    /// - Parameters:
    ///   - calibrationOffset: the desired calibration offset
    ///   - axis: the axis
    /// - Returns: true if the new max speed has been asked
    func set(offsetCorrection: Double, onAxis axis: GimbalAxis) -> Bool

    /// Controls the gimbal
    ///
    /// - Parameters:
    ///   - mode: control mode
    ///   - yaw: yaw target, nil if yaw should not be changed
    ///   - pitch: pitch target, nil if pitch should not be changed
    ///   - roll: roll target, nil if roll should not be changed
    func control(mode: GimbalControlMode, yaw: Double?, pitch: Double?, roll: Double?)

    /// Resets the attitude of the gimbal.
    func resetAttitude()

    /// Starts the offsets correction process.
    func startOffsetsCorrectionProcess()

    /// Stops the offsets correction process.
    func stopOffsetsCorrectionProcess()

}

/// Internal gimbal peripheral implementation
public class GimbalCore: CalibratableGimbalCore, Gimbal {

    private(set) public var supportedAxes: Set<GimbalAxis> = []

    private(set) public var lockedAxes: Set<GimbalAxis> = []

    private(set) public var attitudeBounds: [GimbalAxis: Range<Double>] = [:]

    public var maxSpeedSettings: [GimbalAxis: DoubleSetting] {
        return _maxSpeedSettings
    }
    private var _maxSpeedSettings: [GimbalAxis: DoubleSettingCore] = [:]

    public var stabilizationSettings: [GimbalAxis: BoolSetting] {
        return _stabilizationSettings
    }
    private var _stabilizationSettings: [GimbalAxis: BoolSettingCore] = [:]

    private(set) public var _absoluteAttitude: [GimbalAxis: Double] = [:]
    private(set) public var _relativeAttitude: [GimbalAxis: Double] = [:]

    public var currentAttitude: [GimbalAxis: Double] {
        var attitude: [GimbalAxis: Double] = [:]
        GimbalAxis.allCases.forEach {
            if let stabilization = stabilizationSettings[$0] {
                attitude[$0] = stabilization.value ? _absoluteAttitude[$0] : _relativeAttitude[$0]
            }
        }
        return attitude
    }

    private(set) public var offsetsCorrectionProcess: GimbalOffsetsCorrectionProcess?

    /// Super class backend as GimbalBackend
    private var gimbalBackend: GimbalBackend {
        return backend as! GimbalBackend
    }

    /// Constructor
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored
    ///   - backend: gimbal backend
    public init(store: ComponentStoreCore, backend: GimbalBackend) {
        super.init(desc: Peripherals.gimbal, store: store, backend: backend)
    }

    public func control(mode: GimbalControlMode, yaw: Double?, pitch: Double?, roll: Double?) {
        let yawInRange: Double?
        let pitchInRange: Double?
        let rollInRange: Double?
        if let yawRange = attitudeBounds[.yaw], let yaw = yaw {
            yawInRange = yawRange.clamp(yaw)
        } else {
            yawInRange = yaw
        }
        if let pitchRange = attitudeBounds[.pitch], let pitch = pitch {
            pitchInRange = pitchRange.clamp(pitch)
        } else {
            pitchInRange = pitch
        }
        if let rollRange = attitudeBounds[.roll], let roll = roll {
            rollInRange = rollRange.clamp(roll)
        } else {
            rollInRange = roll
        }
        gimbalBackend.control(
            mode: mode,
            yaw: supportedAxes.contains(.yaw) ? yawInRange : nil,
            pitch: supportedAxes.contains(.pitch) ? pitchInRange : nil,
            roll: supportedAxes.contains(.roll) ? rollInRange : nil)
    }

    public func resetAttitude() {
        gimbalBackend.resetAttitude()
    }

    public func startOffsetsCorrectionProcess() {
        if offsetsCorrectionProcess == nil {
            gimbalBackend.startOffsetsCorrectionProcess()
        }
    }

    public func stopOffsetsCorrectionProcess() {
        if offsetsCorrectionProcess != nil {
            gimbalBackend.stopOffsetsCorrectionProcess()
        }
    }

    public func currentAttitude(frameOfReference: FrameOfReference) -> [GimbalAxis: Double] {
        if frameOfReference == .absolute {
            return _absoluteAttitude
        } else {
            return _relativeAttitude
        }
    }
}

/// Backend callback methods
extension GimbalCore {

    /// Updates the set of supported axes.
    ///
    /// - Note:
    ///   - this will also remove each axes that are not supported from the other gimbal attributes
    ///     (like max speeds, locked axes...)
    ///   - changes are not notified until notifyUpdated() is called
    ///
    /// - Parameter newValue: new supported axes
    /// - Returns: self to allow call chaining
    @discardableResult public func update(supportedAxes newValue: Set<GimbalAxis>) -> GimbalCore {
        if newValue != supportedAxes {
            supportedAxes = newValue

            // remove each axes that are not supported from the other gimbal attributes
            // (like max speeds, locked axes...)
            GimbalAxis.allCases.subtracting(supportedAxes).forEach {
                attitudeBounds[$0] = nil
                _maxSpeedSettings[$0] = nil
                lockedAxes.remove($0)
                _stabilizationSettings[$0] = nil
                _absoluteAttitude[$0] = nil
                _relativeAttitude[$0] = nil
            }

            markChanged()
        }
        return self
    }

    /// Updates the set of temporarily locked axes.
    ///
    /// - Note:
    ///   - only apply the update if the axis is supported
    ///   - changes are not notified until notifyUpdated() is called
    ///
    /// - Parameter newValue: the new set of locked axes
    /// - Returns: self to allow call chaining
    @discardableResult public func update(lockedAxes newValue: Set<GimbalAxis>) -> GimbalCore {
        // only add supported axes
        let filteredLockedAxes = newValue.filter { supportedAxes.contains($0) }
        if filteredLockedAxes != lockedAxes {
            lockedAxes = filteredLockedAxes
            markChanged()
        }
        return self
    }

    /// Updates the position bounds on a given axis.
    ///
    /// - Note:
    ///   - only apply the update if the axis is supported
    ///   - changes are not notified until notifyUpdated() is called
    ///
    /// - Parameters:
    ///   - newValue: new bounds, or nil if bounds should be cleared for this axis
    ///   - axis: the axis
    /// - Returns: self to allow call chaining
    @discardableResult public func update(axisBounds newValue: Range<Double>?, onAxis axis: GimbalAxis) -> GimbalCore {
        if supportedAxes.contains(axis) && newValue != attitudeBounds[axis] {
            attitudeBounds[axis] = newValue
            markChanged()
        }
        return self
    }

    /// Updates the max speed setting for a given axis.
    ///
    /// - Note:
    ///   - only apply the update if the axis is supported
    ///   - changes are not notified until notifyUpdated() is called
    ///
    /// - Parameters:
    ///   - newSetting: tuple containing new values. Only not nil values are updated
    ///   - axis: the axis
    /// - Returns: self to allow call chaining
    @discardableResult public func update(
        maxSpeedSetting newSetting: (min: Double?, value: Double?, max: Double?),
        onAxis axis: GimbalAxis) -> GimbalCore {

        if supportedAxes.contains(axis) {
            if _maxSpeedSettings[axis] == nil {
                _maxSpeedSettings[axis] = DoubleSettingCore(didChangeDelegate: self) { [unowned self] newValue in
                    return self.gimbalBackend.set(maxSpeed: newValue, onAxis: axis)
                }
            }

            if _maxSpeedSettings[axis]!.update(min: newSetting.min, value: newSetting.value, max: newSetting.max) {
                markChanged()
            }
        }
        return self
    }

    /// Updates the stabilization of a given axis
    ///
    /// - Note:
    ///   - only apply the update if the axis is supported
    ///   - changes are not notified until notifyUpdated() is called
    ///
    /// - Parameters:
    ///   - newSetting: the new stabilization status
    ///   - axis: the axis
    /// - Returns: self to allow call chaining
    @discardableResult public func update(stabilization newSetting: Bool, onAxis axis: GimbalAxis) -> GimbalCore {
        if supportedAxes.contains(axis) {
            if _stabilizationSettings[axis] == nil {
                _stabilizationSettings[axis] = BoolSettingCore(didChangeDelegate: self) { [unowned self] newValue in
                    return self.gimbalBackend.set(stabilization: newValue, onAxis: axis)
                }
                markChanged()
            }

            if _stabilizationSettings[axis]!.update(value: newSetting) {
                markChanged()
            }
        }
        return self
    }

    /// Updates the absolute attitude of the given axis.
    ///
    /// - Note:
    ///   - only apply the update if the axis is supported
    ///   - changes are not notified until notifyUpdated() is called
    ///
    /// - Parameters:
    ///   - newValue: the attitude in degrees.
    ///   - axis: the axis
    /// - Returns: self to allow call chaining
    @discardableResult public func update(absoluteAttitude newValue: Double?, onAxis axis: GimbalAxis) -> GimbalCore {
        guard supportedAxes.contains(axis) else {
            return self
        }
        if _absoluteAttitude[axis] == nil && newValue != nil {
            _absoluteAttitude[axis] = newValue
            markChanged()
        } else {
            if let newValue = newValue {
                if let currentAtt = _absoluteAttitude[axis],
                    newValue != currentAtt {
                    _absoluteAttitude[axis] = newValue
                    markChanged()
                }
            } else {
                _absoluteAttitude[axis] = nil
                markChanged()
            }
        }
        return self
    }

    /// Updates the relative attitude of the given axis.
    ///
    /// - Note:
    ///   - only apply the update if the axis is supported
    ///   - changes are not notified until notifyUpdated() is called
    ///
    /// - Parameters:
    ///   - newValue: the attitude in degrees.
    ///   - axis: the axis
    /// - Returns: self to allow call chaining
    @discardableResult public func update(relativeAttitude newValue: Double?, onAxis axis: GimbalAxis) -> GimbalCore {
        guard supportedAxes.contains(axis) else {
            return self
        }
        if _relativeAttitude[axis] == nil && newValue != nil {
            _relativeAttitude[axis] = newValue
            markChanged()
        } else {
            if let newValue = newValue {
                if let currentAtt = _relativeAttitude[axis],
                    newValue != currentAtt {
                    _relativeAttitude[axis] = newValue
                    markChanged()
                }
            } else {
                _relativeAttitude[axis] = nil
                markChanged()
            }
        }
        return self
    }

    /// Updates the offsets calibration process state.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: whether the correction process is started
    /// - Returns: self to allow call chaining
    @discardableResult public func update(offsetsCorrectionProcessStarted: Bool) -> GimbalCore {
        if offsetsCorrectionProcessStarted && offsetsCorrectionProcess == nil {
            offsetsCorrectionProcess = GimbalOffsetsCorrectionProcess()
            markChanged()
        } else if !offsetsCorrectionProcessStarted && offsetsCorrectionProcess != nil {
            offsetsCorrectionProcess = nil
            markChanged()
        }
        return self
    }

    /// Updates the set of calibratable axes.
    ///
    /// - Note:
    ///   - this will also remove each axes that are not calibratable from the calibration offsets
    ///   - changes are not notified until notifyUpdated() is called
    ///
    /// - Parameter newValue: new calibratable axes
    /// - Returns: self to allow call chaining
    @discardableResult public func update(calibratableAxes newValue: Set<GimbalAxis>) -> GimbalCore {
        if let offsetsCorrectionProcess = offsetsCorrectionProcess,
            offsetsCorrectionProcess.correctableAxes != newValue {

            offsetsCorrectionProcess.correctableAxes = newValue

            // remove each axes that are not calibratable from the calibration offsets
            GimbalAxis.allCases.subtracting(offsetsCorrectionProcess.correctableAxes).forEach {
                offsetsCorrectionProcess._offsetsCorrection[$0] = nil
            }

            markChanged()
        }
        return self
    }

    /// Updates the calibration offset for a given axis.
    ///
    /// - Note:
    ///   - only apply the update if the axis is calibratable
    ///   - changes are not notified until notifyUpdated() is called
    ///
    /// - Parameters:
    ///   - newSetting: tuple containing new values. Only not nil values are updated
    ///   - axis: the axis
    /// - Returns: self to allow call chaining
    @discardableResult public func update(
        calibrationOffset newOffset: (min: Double?, value: Double?, max: Double?),
        onAxis axis: GimbalAxis) -> GimbalCore {

        if let offsetsCorrectionProcess = offsetsCorrectionProcess,
            offsetsCorrectionProcess.correctableAxes.contains(axis) {

            if offsetsCorrectionProcess.offsetsCorrection[axis] == nil {
                offsetsCorrectionProcess._offsetsCorrection[axis] = DoubleSettingCore(didChangeDelegate: self) {
                    // swiftlint:disable:next closure_parameter_position
                    [unowned self] newValue in
                    return self.gimbalBackend.set(offsetCorrection: newValue, onAxis: axis)
                }
            }

            if offsetsCorrectionProcess._offsetsCorrection[axis]!.update(
                min: newOffset.min, value: newOffset.value, max: newOffset.max) {

                markChanged()
            }
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> GimbalCore {
        GimbalAxis.allCases.forEach { axis in
            _maxSpeedSettings[axis]?.cancelRollback { markChanged() }
            _stabilizationSettings[axis]?.cancelRollback { markChanged() }
            if let offsetsCorrectionProcess = offsetsCorrectionProcess {
                offsetsCorrectionProcess._offsetsCorrection[axis]?.cancelRollback { markChanged() }
            }
        }
        return self
    }
}

/// Extension of Gimbal that implements ObjC API
extension GimbalCore: GSGimbal {

    public func isAxisSupported(_ axis: GimbalAxis) -> Bool {
        return supportedAxes.contains(axis)
    }

    public func isAxisLocked(_ axis: GimbalAxis) -> Bool {
        return lockedAxes.contains(axis)
    }

    public func attitudeLowerBound(onAxis axis: GimbalAxis) -> NSNumber? {
        if let lowerBound = attitudeBounds[axis]?.lowerBound {
            return NSNumber(value: lowerBound)
        }
        return nil
    }

    public func attitudeUpperBound(onAxis axis: GimbalAxis) -> NSNumber? {
        if let upperBound = attitudeBounds[axis]?.upperBound {
            return NSNumber(value: upperBound)
        }
        return nil
    }

    public func maxSpeed(onAxis axis: GimbalAxis) -> DoubleSetting? {
        return maxSpeedSettings[axis]
    }

    public func stabilization(onAxis axis: GimbalAxis) -> BoolSetting? {
        return stabilizationSettings[axis]
    }

    public func currentAttitude(onAxis axis: GimbalAxis) -> NSNumber? {
        if let stabilization = _stabilizationSettings[axis] {
            return NSNumber(value: (stabilization.value ? _absoluteAttitude[axis] : _relativeAttitude[axis]) ?? 0)
        }
        return nil
    }

    public func currentAttitude(onAxis axis: GimbalAxis, frameOfReference: FrameOfReference) -> NSNumber? {
        return NSNumber(value: (frameOfReference == .absolute ? _absoluteAttitude[axis] : _relativeAttitude[axis]) ?? 0)
    }

    public func control(mode: GimbalControlMode, yaw: NSNumber?, pitch: NSNumber?, roll: NSNumber?) {
        control(mode: mode, yaw: yaw?.doubleValue, pitch: pitch?.doubleValue, roll: roll?.doubleValue)
    }
}
