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

/// The callibration sensor type.
public enum CalibrationSensorType: CustomStringConvertible {

    /// Pilot sensor.
    case pitot

    /// Debug description.
    public var description: String {
        switch self {
        case .pitot:    return "pitot"
        }
    }
}

/// Sensor calibration state.
public enum SensorCalibrationState: CustomStringConvertible {

    /// Calibration is idle.
    case idle

    /// Calibration in progress.
    case inProgress

    /// Calibration is done.
    case done

    /// Calibration failed.
    case failed

    /// Calibration aborted.
    case aborted

    /// Debug description.
    public var description: String {
        switch self {
        case .inProgress:       return "inProgress"
        case .done:             return "done"
        case .failed:           return "failed"
        case .idle:             return "idle"
        case .aborted:          return "aborted"
        }
    }
}

/// Calibration sensor.
public struct CalibrationSensor: Equatable {

    /// Calibration sensor type.
    public var type: CalibrationSensorType

    /// Sensor calibration state.
    public var state: SensorCalibrationState

    /// Whether or not calibration is required.
    public var isRequired: Bool

    /// Constructor.
    ///
    /// - Parameters:
    ///   - type: the calibration sensor type
    ///   - state: the sensor calibration state
    ///   - isRequired: whether or not calibration is required
    public init(type: CalibrationSensorType, state: SensorCalibrationState, isRequired: Bool) {
        self.type = type
        self.state = state
        self.isRequired = isRequired
    }
}

/// Sensor calibration peripheral interface.
///
/// This peripheral allows calibrate drone sensors.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.calibration)
/// ```
public protocol Calibration: Peripheral {

    /// List of calibration sensors.
    var sensors: [CalibrationSensor] { get }

    /// Starts sensor calibration.
    ///
    /// - Parameter sensor: sensor to calibrate
    /// - Returns: `true` if calibrate was successfully requested
    func start(sensor: CalibrationSensorType) -> Bool

    /// Aborts sensor calibration.
    ///
    /// - Parameter sensor: sensor whose calibration must be aborted
    /// - Returns: `true` if abort was successfully requested
    func abort(sensor: CalibrationSensorType) -> Bool
}

/// :nodoc:
/// Calibration description
public class CalibrationDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = Calibration
    public let uid = PeripheralUid.calibration.rawValue
    public let parent: ComponentDescriptor? = nil
}
