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

/// Anafi stereo vision sensor backend part.
public protocol StereoVisionSensorBackend: AnyObject {
    /// Starts calibration process.
    func startCalibration()

    /// Cancels the current calibration process.
    func cancelCalibration()
}

/// Core class for CalibrationProcessState.
public class StereoCalibrationProcessStateCore: StereoVisionCalibrationProcessState {

    /// Required board position for the current step.
    private var _requiredPosition: FrameCore?

    /// Current board position.
    private var _currentPosition: FrameCore?

    /// Current calibration step.
    private (set) public var currentStep: Int = 0

    /// Indication to position the board properly.
    fileprivate(set) public var indication = StereoVisionIndication.none

    /// Calibration result.
    fileprivate(set) public var result = StereoVisionResult.none

    public var requiredPosition: StereoVisionFrame? {
        return _requiredPosition
    }

    public var currentPosition: StereoVisionFrame? {
        if indication == .none || indication == .placeWithinSight || indication == .checkBoardAndCameras {
            return nil
        }
        return _currentPosition
    }

    /// Required rotation for the current step.
    private var _requiredRotation: RotationCore?

    /// Current rotation.
    private var _currentRotation: RotationCore?

    public var requiredRotation: StereoVisionRotation? {
        return _requiredRotation
    }

    public var currentRotation: StereoVisionRotation? {
        if indication == .none || indication == .placeWithinSight || indication == .checkBoardAndCameras {
            return nil
        }
        return _currentRotation
    }

    /// Indicates if drone is computing results at the end of calibration of the process.
    fileprivate(set) public var isComputing = false
}

extension StereoCalibrationProcessStateCore {

    /// Clean rotations and position both required and current.
    /// - Returns: true if the clean has been done, false otherwise
    @discardableResult public func cleanPositionsAndRotation() -> Bool {
        var changed = false
        if _currentRotation != nil || _requiredRotation != nil || _currentPosition != nil || _requiredPosition != nil {
            _currentRotation = nil
            _requiredRotation = nil
            _currentPosition = nil
            _requiredPosition = nil
            changed = true
        }
        return changed
    }

    /// Changes current step.
    ///
    /// - Parameter currentStep: the currentStep to set
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(currentStep newValue: Int) -> Bool {
        var changed = false
        if currentStep != newValue {
            currentStep = newValue
            changed = true
        }
        return changed
    }

    /// Updates current rotation.
    ///
    /// - Parameters:
    ///   - xAngle: the new X angle
    ///   - yAngle: the new Y angle
    /// - Returns: self to allow call chaining
    /// - Note: true if the current rotation has been changed, false otherwise
    public func updateCurrentRotation(xAngle: Double, yAngle: Double) ->
        Bool {
            var changed = false
            if _currentRotation == nil {
                _currentRotation = RotationCore()
                changed = true
            }

            if _currentRotation!.update(xAngle: xAngle, yAngle: yAngle) {
                changed = true
            }
            return changed
    }

    /// Updates required rotation.
    ///
    /// - Parameters:
    ///   - xAngle: the new X angle
    ///   - yAngle: the new Y angle
    /// - Returns: self to allow call chaining
    /// - Note: true if the required rotation has been changed, false otherwise
    public func updateRequiredRotation(xAngle: Double, yAngle: Double) ->
        Bool {
            var changed = false
            if _requiredRotation == nil {
                _requiredRotation = RotationCore()
                changed = true
            }

            if _requiredRotation!.update(xAngle: xAngle, yAngle: yAngle) {
                changed = true
            }
            return changed
    }

    /// Updates current position.
    ///
    /// - Parameters:
    ///   - leftTopX: the new X coordinate of the left top vertex
    ///   - leftTopY: the new Y coordinate of the left top vertex
    ///   - rightTopX: the new X coordinate of the right top vertex
    ///   - rightTopY: the new Y coordinate of the right top vertex
    ///   - leftBottomX: the new X coordinate of the left bottom vertex
    ///   - leftBottomY: the new Y coordinate of the left bottom vertex
    ///   - rightBottomX: the new X coordinate of the right bottom vertex
    ///   - rightBottomY: the new Y coordinate of the right bottom vertex
    /// - Returns: self to allow call chaining
    /// - Note: true if the current position has been changed, false otherwise
    public func updateCurrentPosition(leftTopX: Double, leftTopY: Double,
                                      rightTopX: Double, rightTopY: Double,
                                      leftBottomX: Double, leftBottomY: Double,
                                      rightBottomX: Double, rightBottomY: Double) ->
        Bool {
            var changed = false
            if _currentPosition == nil {
                _currentPosition = FrameCore()
                changed = true
            }

            if _currentPosition!.update(leftTopX: leftTopX, leftTopY: leftTopY,
                                        rightTopX: rightTopX, rightTopY: rightTopY,
                                        leftBottomX: leftBottomX, leftBottomY: leftBottomY,
                                        rightBottomX: rightBottomX, rightBottomY: rightBottomY) {
                changed = true
            }
            return changed
    }

    /// Updates required position.
    ///
    /// - Parameters:
    ///   - leftTopX: the new X coordinate of the left top vertex
    ///   - leftTopY: the new Y coordinate of the left top vertex
    ///   - rightTopX: the new X coordinate of the right top vertex
    ///   - rightTopY: the new Y coordinate of the right top vertex
    ///   - leftBottomX: the new X coordinate of the left bottom vertex
    ///   - leftBottomY: the new Y coordinate of the left bottom vertex
    ///   - rightBottomX: the new X coordinate of the right bottom vertex
    ///   - rightBottomY: the new Y coordinate of the right bottom vertex
    /// - Returns: true if the current position has been changed, false otherwise
    public func updateRequiredPosition(leftTopX: Double, leftTopY: Double,
                                       rightTopX: Double, rightTopY: Double,
                                       leftBottomX: Double, leftBottomY: Double,
                                       rightBottomX: Double, rightBottomY: Double) ->
        Bool {
            var changed = false
        if _requiredPosition == nil {
            _requiredPosition = FrameCore()
            changed = true
        }

        if _requiredPosition!.update(leftTopX: leftTopX, leftTopY: leftTopY,
                                   rightTopX: rightTopX, rightTopY: rightTopY,
                                   leftBottomX: leftBottomX, leftBottomY: leftBottomY,
                                   rightBottomX: rightBottomX, rightBottomY: rightBottomY) {
            changed = true
        }
        return changed
    }

    /// Updates the calibration indication.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: the new indication of the process state
    /// - Returns: true if the indicaiton has been changed, false otherwise
    public func update(indication
        newValue: StereoVisionIndication) -> Bool {
        var changed = false
        if indication != newValue {
            indication = newValue
            changed = true
        }
        return changed
    }

    /// Updates the calibration result.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: the new result of the process state
    /// - Returns: true if the result has been changed, false otherwise
    @discardableResult public func update(result
        newValue: StereoVisionResult) -> Bool {
        var changed = false
        if result != newValue {
            result = newValue
            changed = true
        }
        return changed
    }

    /// Updates the isComputing.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: the new isComputing flag
    /// - Returns: true if the flag has been changed, false otherwise
    @discardableResult public func update(isComputing
        newValue: Bool) -> Bool {
        var changed = false
        if isComputing != newValue {
            isComputing = newValue
            changed = true
            if isComputing {
                indication = .none
                _requiredPosition = nil
                _currentPosition = nil
                _requiredRotation = nil
                _currentRotation = nil
            }
        }
        return changed
    }
}

/// Core class for Rotation.
public class RotationCore: StereoVisionRotation {
    /// Rotation angle along the X axis, in degrees.
    private var _xAngle: Double = 0.0

    /// Rotation angle along the Y axis, in degrees.
    private var _yAngle: Double = 0.0

    public var xAngle: Double {
        return _xAngle
    }

    public var yAngle: Double {
        return _yAngle
    }

    /// Updates this rotation's angles with the given angles.
    ///
    /// - Parameters:
    ///   - xAngle: the new X angle
    ///   - yAngle: the new Y angle
    /// - Returns: `true` if at least one of the rotation angles have been updated, `false` otherwise
    public func update(xAngle: Double, yAngle: Double) -> Bool {
        var hasChanged = false
        if _xAngle != xAngle {
            _xAngle = xAngle
            hasChanged = true
        }
        if _yAngle != yAngle {
            _yAngle = yAngle
            hasChanged = true
        }
        return hasChanged
    }
}

/// Core class for Frame.
public class FrameCore: StereoVisionFrame {
    /// Left top vertex.
    private var _leftTopVertex: VertexCore

    /// Right top vertex.
    private var _rightTopVertex: VertexCore

    /// Left bottom vertex.
    private var _leftBottomVertex: VertexCore

    /// Right bottom vertex.
    private var _rightBottomVertex: VertexCore

    public func getLeftTopVertex() -> StereoVisionVertex {
        return _leftTopVertex
    }

    public func getRightTopVertex() -> StereoVisionVertex {
        return _rightTopVertex
    }

    public func getLeftBottomVertex() -> StereoVisionVertex {
        return _leftBottomVertex
    }

    public func getRightBottomVertex() -> StereoVisionVertex {
        return _rightBottomVertex
    }

    init() {
        _leftTopVertex = VertexCore()
        _rightTopVertex = VertexCore()
        _leftBottomVertex = VertexCore()
        _rightBottomVertex = VertexCore()
    }

    /// Updates this frame's coordinates with the given coordinates.
    ///
    /// - Parameters:
    ///   - leftTopX: the new X coordinate of the left top vertex
    ///   - leftTopY: the new Y coordinate of the left top vertex
    ///   - rightTopX: the new X coordinate of the right top vertex
    ///   - rightTopY: the new Y coordinate of the right top vertex
    ///   - leftBottomX: the new X coordinate of the left bottom vertex
    ///   - leftBottomY: the new Y coordinate of the left bottom vertex
    ///   - rightBottomX: the new X coordinate of the right bottom vertex
    ///   - rightBottomY: the new Y coordinate of the right bottom vertex
    /// - Returns: `true` if the frame's coordinates have been updated, `false` otherwise
    public func update(leftTopX: Double, leftTopY: Double,
                       rightTopX: Double, rightTopY: Double,
                       leftBottomX: Double, leftBottomY: Double,
                       rightBottomX: Double, rightBottomY: Double) -> Bool {
        if _leftTopVertex._X != leftTopX || _leftTopVertex._Y != leftTopY ||
            _rightTopVertex._X != rightTopX || _rightTopVertex._Y != rightTopY ||
            _leftBottomVertex._X != leftBottomX || _leftBottomVertex._Y != leftBottomY ||
            _rightBottomVertex._X != rightBottomX || _rightBottomVertex._Y != rightBottomY {
            _leftTopVertex._X = leftTopX
            _leftTopVertex._Y = leftTopY
            _rightTopVertex._X = rightTopX
            _rightTopVertex._Y = rightTopY
            _leftBottomVertex._X = leftBottomX
            _leftBottomVertex._Y = leftBottomY
            _rightBottomVertex._X = rightBottomX
            _rightBottomVertex._Y = rightBottomY
            return true
        }
        return false
    }
}

/// Core class for Vertex.
public class VertexCore: StereoVisionVertex {
    fileprivate var _X: Double = 0.0
    fileprivate var _Y: Double = 0.0

    public func getX() -> Double {
        return _X
    }

    public func getY() -> Double {
        return _Y
    }

}

/// Internal Anafi stereo vision sensor peripheral implementation
public class StereoVisionSensorCore: PeripheralCore, StereoVisionSensor {

    private (set) public var isCalibrated: Bool = false

    private (set) public var calibrationStepCount: Int = 0

    /// Sensor aspect ratio
    public private(set) var aspectRatio = 0.0

    /// implementation backend
    private unowned let backend: StereoVisionSensorBackend

    private(set) public var _calibrationProcessState: StereoCalibrationProcessStateCore?

    public var calibrationProcessState: StereoVisionCalibrationProcessState? {
        return _calibrationProcessState
    }

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: Stereo Vision SensorBackend
    public init(store: ComponentStoreCore, backend: StereoVisionSensorBackend) {
        self.backend = backend
        super.init(desc: Peripherals.stereoVisionSensor, store: store)
    }

    public func startCalibration() {
        if calibrationProcessState == nil {
            _calibrationProcessState = StereoCalibrationProcessStateCore()
            backend.startCalibration()
            // notify the changes
            markChanged()
            notifyUpdated()
        }
    }

    public func cancelCalibration() {
        if calibrationProcessState != nil {
            backend.cancelCalibration()
            _calibrationProcessState?.cleanPositionsAndRotation()
            _calibrationProcessState = nil
            // notify the changes
            markChanged()
            notifyUpdated()
        }
    }
}

/// Backend callback methods
extension StereoVisionSensorCore {

    ///  Sets the calibration process as started.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///     This method has no effect if the calibration process has already been started.
    ///
    /// - Parameter newValue: whether the stereo vision sensor is calibrated
    /// - Returns: self to allow call chaining
    @discardableResult public func setCalibrationStarted() -> StereoVisionSensorCore {
        if _calibrationProcessState == nil {
            _calibrationProcessState = StereoCalibrationProcessStateCore()
            markChanged()
        }
        return self
    }

    ///  Sets the calibration process as stopped.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///     This method has no effect if the calibration process has not been started.
    ///
    /// - Returns: self to allow call chaining
    @discardableResult public func setCalibrationStopped() -> StereoVisionSensorCore {
        if _calibrationProcessState != nil {
            _calibrationProcessState?.cleanPositionsAndRotation()
            _calibrationProcessState = nil
            markChanged()
        }
        return self
    }

    /// Updates the calibrated state.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: whether the stereo vision sensor is calibrated
    /// - Returns: self to allow call chaining
    @discardableResult public func update(calibrated newValue: Bool) -> StereoVisionSensorCore {
        if isCalibrated != newValue {
            isCalibrated = newValue
            markChanged()
        }
        return self
    }

    /// Changes calibration step count.
    ///
    /// - Parameter calibrationStepCount: the calibrationStepCount to set
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(calibrationStepCount newValue: Int) -> StereoVisionSensorCore {
        if calibrationStepCount != newValue {
            calibrationStepCount = newValue
            markChanged()
        }
        return self
    }

    /// Changes calibration aspect ratio.
    ///
    /// - Parameter aspectRatio: the aspectRatio to set
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(aspectRatio newValue: Double) -> StereoVisionSensorCore {
        if aspectRatio != newValue {
            aspectRatio = newValue
            markChanged()
        }
        return self
    }

    /// Changes current step.
    ///
    /// - Parameter currentStep: the currentStep to set
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(currentStep newValue: Int) -> StereoVisionSensorCore {
        guard let calibrationProcessState = _calibrationProcessState else {
            return self
        }
        if calibrationProcessState.update(currentStep: newValue) {
            markChanged()
        }

        return self
    }

    /// Updates current rotation.
    ///
    /// - Parameters:
    ///   - xAngle: the new X angle
    ///   - yAngle: the new Y angle
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func updateCurrentRotation(xAngle: Double, yAngle: Double) ->
        StereoVisionSensorCore {
            guard let calibrationProcessState = _calibrationProcessState else {
                return self
            }
            if calibrationProcessState.updateCurrentRotation(xAngle: xAngle, yAngle: yAngle) {
                markChanged()
            }
            return self
    }

    /// Updates required rotation.
    ///
    /// - Parameters:
    ///   - xAngle: the new X angle
    ///   - yAngle: the new Y angle
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func updateRequiredRotation(xAngle: Double, yAngle: Double) ->
        StereoVisionSensorCore {
            guard let calibrationProcessState = _calibrationProcessState else {
                return self
            }
            if calibrationProcessState.updateRequiredRotation(xAngle: xAngle, yAngle: yAngle) {
                markChanged()
            }
            return self
    }

    /// Updates current position.
    ///
    /// - Parameters:
    ///   - leftTopX: the new X coordinate of the left top vertex
    ///   - leftTopY: the new Y coordinate of the left top vertex
    ///   - rightTopX: the new X coordinate of the right top vertex
    ///   - rightTopY: the new Y coordinate of the right top vertex
    ///   - leftBottomX: the new X coordinate of the left bottom vertex
    ///   - leftBottomY: the new Y coordinate of the left bottom vertex
    ///   - rightBottomX: the new X coordinate of the right bottom vertex
    ///   - rightBottomY: the new Y coordinate of the right bottom vertex
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func updateCurrentPosition(leftTopX: Double, leftTopY: Double,
                                                         rightTopX: Double, rightTopY: Double,
                                                         leftBottomX: Double, leftBottomY: Double,
                                                         rightBottomX: Double, rightBottomY: Double) ->
        StereoVisionSensorCore {
            guard let calibrationProcessState = _calibrationProcessState else {
                return self
            }
            if calibrationProcessState.updateCurrentPosition(leftTopX: leftTopX, leftTopY: leftTopY,
                                                               rightTopX: rightTopX, rightTopY: rightTopY,
                                                               leftBottomX: leftBottomX, leftBottomY: leftBottomY,
                                                               rightBottomX: rightBottomX, rightBottomY: rightBottomY) {
                markChanged()
            }
            return self
    }

    /// Updates required position.
    ///
    /// - Parameters:
    ///   - leftTopX: the new X coordinate of the left top vertex
    ///   - leftTopY: the new Y coordinate of the left top vertex
    ///   - rightTopX: the new X coordinate of the right top vertex
    ///   - rightTopY: the new Y coordinate of the right top vertex
    ///   - leftBottomX: the new X coordinate of the left bottom vertex
    ///   - leftBottomY: the new Y coordinate of the left bottom vertex
    ///   - rightBottomX: the new X coordinate of the right bottom vertex
    ///   - rightBottomY: the new Y coordinate of the right bottom vertex
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func updateRequiredPosition(leftTopX: Double, leftTopY: Double,
                                                          rightTopX: Double, rightTopY: Double,
                                                          leftBottomX: Double, leftBottomY: Double,
                                                          rightBottomX: Double, rightBottomY: Double) ->
        StereoVisionSensorCore {
            guard let calibrationProcessState = _calibrationProcessState else {
                return self
            }

            if calibrationProcessState.updateRequiredPosition(leftTopX: leftTopX, leftTopY: leftTopY,
                                                             rightTopX: rightTopX, rightTopY: rightTopY,
                                                             leftBottomX: leftBottomX, leftBottomY: leftBottomY,
                                                             rightBottomX: rightBottomX, rightBottomY: rightBottomY) {
                markChanged()
            }
            return self
    }

    /// Updates the calibration indication.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: the new indication of the process state
    /// - Returns: self to allow call chaining
    @discardableResult public func update(indication
        newValue: StereoVisionIndication) -> StereoVisionSensorCore {
        guard let calibrationProcessState = _calibrationProcessState else {
            return self
        }
        if calibrationProcessState.indication != newValue {
            calibrationProcessState.indication = newValue
            markChanged()
        }
        return self
    }

    /// Updates the calibration result.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: the new result of the process state
    /// - Returns: self to allow call chaining
    @discardableResult public func update(result
        newValue: StereoVisionResult) -> StereoVisionSensorCore {
        guard let calibrationProcessState = _calibrationProcessState else {
            return self
        }
        if calibrationProcessState.result != newValue {
            calibrationProcessState.result = newValue
            markChanged()
        }
        return self
    }

    /// Updates the isComputing.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: the new isComputing flag
    /// - Returns: self to allow call chaining
    @discardableResult public func update(isComputing
        newValue: Bool) -> StereoVisionSensorCore {
        guard let calibrationProcessState = _calibrationProcessState else {
            return self
        }
        if calibrationProcessState.update(isComputing: newValue) {
            markChanged()
        }
        return self
    }
}
