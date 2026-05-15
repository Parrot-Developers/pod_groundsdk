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

/// Line of sight calibration issue.
public enum LineOfSightCalibrationIssue: Int, CaseIterable {

    /// Drone is too close to perform accurate calibration.
    case tooLow

    /// Drone is too low to perform accurate calibration.
    case tooClose

    /// Controller coordinates are invalid
    case invalidControllerCoords

    /// Drone gimbal pitch is not adequate
    case badPitch
}

/// Line of sight calibration state
public enum LineOfSightCalibrationState: Int, CaseIterable {

    /// Line of sight not calibrated
    case required

    /// Calibration process in progress
    case calibrating

    /// Line of sight calibrated
    case calibrated
}

/// Calibration result.
public enum LineOfSightCalibrationResult: Int, CaseIterable {

    /// Calibration process has succeeded.
    case success

    /// Calibration process has failed.
    case failure
}

/// Calibration failure reason.
public enum LineOfSightCalibrationFailureReason: Int, CaseIterable {

    /// At least one `CalibrationIssue` is still present at the time of calibration request.
    case unmetPositionRequirements

    /// Drone's and/or pilot's locations are not precise enough for calibration.
    case impreciseLocation

    /// Gimbal pitch is incoherent with the expected range.
    case tooLargePitchOffset
}

/// LineOfSight peripheral for drones.
///
/// Allows to calibrate the line of sight, which is required for the activation of the center image coordinates feature.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.lineOfSight)
/// ```
public protocol LineOfSight: Peripheral {

    /// Line of sight calibration state.
    var calibrationState: LineOfSightCalibrationState { get }

    /// Current issues preventing calibration to be performed.
    /// When empty, the line of sight can be calibrated
    var currentIssues: Set<LineOfSightCalibrationIssue> { get }

    /// Latest calibration result.
    ///
    /// This property is *transient*: it will be set once when the calibration process completes,
    ///  and then immediately back to `nil`.
    var calibrationResult: LineOfSightCalibrationResult? { get }

    /// Latest calibration failure reasons.
    ///
    /// This property is *transient*: it will be set once when the calibration process fails,
    /// and then immediately back to empty.
    var failureReasons: Set<LineOfSightCalibrationFailureReason> { get }

    /// Calibrates the line of sight.
    ///
    /// The user should first make the camera point to himself, and make sure that no issue is preventing calibration
    /// before triggering it. In this case, the line of sight is immediately calibrated.
    /// - Returns: `true` if the calibration request was sent to the drone
    func calibrate()

    /// Resets the line of sight calibration.
    ///
    /// - Returns: `true` if the reset request was sent to the drone
    func resetCalibration()

}

public class LineOfSightDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = LineOfSight
    public let uid = PeripheralUid.lineOfSight.rawValue
    public let parent: ComponentDescriptor? = nil
}
