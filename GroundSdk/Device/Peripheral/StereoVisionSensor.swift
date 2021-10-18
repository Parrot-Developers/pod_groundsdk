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

/// Calibration result.
public enum StereoVisionResult: String, CustomStringConvertible {
    /// No result available because calibration is still in progress.
    case none

    /// Calibration was successful.
    case success

    /// Calibration failed.
    case failed

    /// Calibration was canceled.
    case canceled

    /// Debug description.
    public var description: String { return rawValue }
}

/// Drone indication for stereo vision sensor calibration.
public enum StereoVisionIndication: String, CustomStringConvertible {
    /// No indication is provided for the moment.
    case none

    /// The smart board should be placed within sight of the sensor.
    case placeWithinSight

    /// The sensor cannot see the entire board. The user should check that:
    /// - there is no obstacle between the sensor and the board,
    /// - there is no highlight on the board,
    /// - the board is clean,
    /// - both cameras are clean.
    case checkBoardAndCameras

    /// The smart board should be moved away from the sensor.
    case moveAway

    /// The smart board should be moved closer to the sensor.
    case moveCloser

    /// The smart board should be moved to the left.
    case moveLeft

    /// The smart board should be moved to the right.
    case moveRight

    /// The smart board should be moved upward.
    case moveUpward

    /// The smart board should be moved downward.
    case moveDownward

    /// The smart board should be turned clockwise.
    case turnClockwise

    /// The smart board should be turned counter-clockwise.
    case turnCounterClockwise

    /// The smart board should be tilted to the left.
    case tiltLeft

    /// The smart board should be tilted to the right.
    case tiltRight

    /// The smart board should be tilted forward.
    case tiltForward

    /// The smart board should be tilted backward.
    case tiltBackward

    /// The smart board is in the correct position and should not be moved for a while.
    case stop

    /// Debug description.
    public var description: String { return rawValue }

}

/// Frame
public protocol StereoVisionFrame {
    /// Retrieves the left top vertex.
    func getLeftTopVertex() -> StereoVisionVertex

    /// Retrieves the right top vertex.
    func getRightTopVertex() -> StereoVisionVertex

    /// Retrieves the left bottom vertex.
    func getLeftBottomVertex() -> StereoVisionVertex

    /// Retrieves the right bottom vertex.
    func getRightBottomVertex() -> StereoVisionVertex
}

/// Frame vertex.
public protocol StereoVisionVertex {
    /// Retrieves the X coordinate of the vertex.
    func getX() -> Double

    /// Retrieves the Y coordinate of the vertex.
    func getY() -> Double
}

/// Rotation along X and Y axes.
public protocol StereoVisionRotation {
    /// Retrieves rotation angle along the X axis, in degrees.
    /// Positive value means backward tilt, negative value means forward tilt.
    var xAngle: Double { get }

    /// Retrieves rotation angle along the Y axis, in degrees.
    /// Positive value means left tilt, negative value means right tilt.
    var yAngle: Double { get }
}

/// Sensor calibration process state.
public protocol StereoVisionCalibrationProcessState {

    /// Retrieves the current calibration step, starting from 0.
    var currentStep: Int { get }

    /// Retrieves the required position of the board for the current step.
    var requiredPosition: StereoVisionFrame? { get }

    /// Retrieves the current board position.
    var currentPosition: StereoVisionFrame? { get }

    /// Retrieves the required rotation of the board for the current step.
    var requiredRotation: StereoVisionRotation? { get }

    /// Retrieves the current board rotation.
    var currentRotation: StereoVisionRotation? { get }

    /// Retrieves the calibration indication.
    var indication: StereoVisionIndication { get }

    /// Retrieves the calibration result.
    var result: StereoVisionResult { get }

    /// Indicates if drone is computing results at the end of calibration process.
    var isComputing: Bool { get }
}

/// Stereo Vision Sensor peripheral interface for drones.
///
/// This peripheral allows to calibrate the stereo vision sensor.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.stereoVisionSensor)
/// ```
public protocol StereoVisionSensor: Peripheral {

    /// `true` if the device is calibrated, `false` otherwise.
    var isCalibrated: Bool { get }

    /// Retrieves the number of steps required for sensor calibration.
    var calibrationStepCount: Int { get }

    /// Retrieves the sensor aspect ratio.
    var aspectRatio: Double { get }

    /// State of the calibration process.
    ///
    /// - Note: To start a calibration process, use `startCalibration()`.
    var calibrationProcessState: StereoVisionCalibrationProcessState? { get }

    /// Starts the calibration process.
    ///
    /// After this call, `calibrationProcessState` should not be nil as the process has started.
    /// The process ends either when all steps are achieved or when you call `cancelCalibration()`.
    ///
    /// - Note: No change if the process is already started.
    func startCalibration()

    /// Cancels the calibration process.
    ///
    /// Cancel a process that has been started with `startCalibration()`.
    /// After this call, `calibrationProcessState()` should return a null object as the process has ended.
    ///
    /// - Note: No change if the process is not started.
    func cancelCalibration()
}

/// :nodoc:
/// Dri description
public class StereoVisionSensorDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = StereoVisionSensor
    public let uid = PeripheralUid.stereoVisionSensor.rawValue
    public let parent: ComponentDescriptor? = nil
}
