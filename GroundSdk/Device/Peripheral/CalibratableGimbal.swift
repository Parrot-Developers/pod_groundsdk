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

/// Gimbal error.
@objc(GSGimbalError)
public enum GimbalError: Int, CustomStringConvertible {
    /// Calibration error.
    ///
    /// May happen during manual or automatic calibration.
    ///
    /// Application should inform the user that the gimbal is currently inoperable and suggest to verify that
    /// nothing currently hinders proper gimbal movement.
    ///
    /// The device will retry calibration regularly; after several failed attempts, it will escalate the current
    /// error to `.critical` level, at which point the gimbal becomes inoperable until both the issue
    /// is fixed and the device is restarted.
    case calibration
    /// Overload error.
    ///
    /// May happen during normal operation of the gimbal.
    ///
    /// Application should inform the user that the gimbal is currently inoperable and suggest to verify that
    /// nothing currently hinders proper gimbal movement.
    ///
    /// The device will retry stabilization regularly; after several failed attempts, it will escalate the current
    /// error to `.critical` level, at which point the gimbal becomes inoperable until both the issue
    /// is fixed and the device is restarted.
    case overload
    /// Communication error.
    ///
    /// Communication with the gimbal is broken due to some unknown software and/or hardware issue.
    ///
    /// Application should inform the user that the gimbal is currently inoperable.
    /// However, there is nothing the application should recommend the user to do at that point: either the issue
    /// will hopefully resolve itself (most likely a software issue), or it will escalate to critical level
    /// (probably hardware issue) and the application should recommend the user to send back the device for repair.
    ///
    /// The device will retry stabilization regularly; after several failed attempts, it will escalate the current
    /// error to `.critical` level, at which point the gimbal becomes inoperable until both the issue
    /// is fixed and the device is restarted.
    case communication
    /// Critical error.
    ///
    /// May occur at any time; in particular, occurs when any of the other errors persists after
    /// multiple retries from the device.
    ///
    /// Application should inform the user that the gimbal has become completely inoperable until the issue is
    /// fixed and the device is restarted, as well as suggest to verify that nothing currently hinders proper gimbal
    /// movement and that the gimbal is not damaged in any way.
    case critical

    /// Debug description.
    public var description: String {
        switch self {
        case .calibration:      return "calibration"
        case .overload:         return "overload"
        case .communication:    return "communication"
        case .critical:         return "critical"
        }
    }

    /// Set containing all axes.
    public static let allCases: Set<GimbalError> = [.calibration, .overload, .communication, critical]
}

/// Gimbal calibration process state.
@objc(GSGimbalCalibrationProcessState)
public enum GimbalCalibrationProcessState: Int, CustomStringConvertible {
    /// No ongoing calibration process.
    case none
    /// Calibration process in progress.
    case calibrating
    /// Calibration was successful.
    ///
    /// This result is transient, calibration state will change back to `.none` immediately after success is notified.
    case success
    /// Calibration failed.
    ///
    /// This result is transient, calibration state will change back to `.none` immediately after failure is notified.
    case failure
    /// Calibration was canceled.
    ///
    /// This result is transient, calibration state will change back to `.none` immediately after canceled is notified.
    case canceled

    /// Debug description.
    public var description: String {
        switch self {
        case .none: return "none"
        case .calibrating: return "calibrating"
        case .success: return "success"
        case .failure: return "failure"
        case .canceled: return "canceled"
        }
    }
}

/// This is the master class for gimbals
public protocol CalibratableGimbal: Peripheral {
    /// Set of current errors.
    ///
    /// When empty, the gimbal can be operated normally, otherwise, it is currently inoperable.
    /// In case the returned set contains the `.critical` error, then gimbal has become completely inoperable
    /// until both all other reported errors are fixed and the device is restarted.
    var currentErrors: Set<GimbalError> { get }

    /// Set of currently locked axes.
    /// While an axis is locked, you cannot set a speed or a position.
    ///
    /// An axis can be locked because the drone is controlling this axis on itself, thus it does not allow the
    /// controller to change its orientation. This might be the case during a FollowMe or when the
    /// `PointOfInterestPilotingItf` is active.
    ///

    /// Whether the gimbal is calibrated.
    var calibrated: Bool { get }

    /// Calibration process state.
    /// See `startCalibration()` and `cancelCalibration()`
    var calibrationProcessState: GimbalCalibrationProcessState { get }

    /// Starts calibration process.
    /// Does nothing when `calibrationProcessState` is `calibrating`.
    func startCalibration()

    /// Cancels the current calibration process.
    /// Does nothing when `calibrationProcessState` is not `calibrating`.
    func cancelCalibration()

}

/// Objective-C version of Gimbal.
///
/// The gimbal is the peripheral "holding" and orientating the camera. It can be a real mechanical gimbal, or a software
/// one.
///
/// The gimbal can act on one or multiple axes. It can stabilize a given axis, meaning that the movement on this axis
/// will be following the horizon (for `.roll` and `.pitch`) or the North (for the `.yaw`).
///
/// - Note: This class is for Objective-C only and must not be used in Swift.
@objc
public protocol GSCalibratableGimbal: Peripheral {
    /// Whether the gimbal is calibrated.
    var calibrated: Bool { get }

    /// Calibration process state.
    /// See `startCalibration()` and `cancelCalibration()`
    var calibrationProcessState: GimbalCalibrationProcessState { get }

    /// Tells whether the gimbal currently has the given error.
    ///
    /// - Parameter error: the error to query
    /// - Returns: `true` if the error is currently happening
    func hasError(_ error: GimbalError) -> Bool

    /// Starts calibration process.
    func startCalibration()

    /// Cancels the current calibration process.
    func cancelCalibration()
}
