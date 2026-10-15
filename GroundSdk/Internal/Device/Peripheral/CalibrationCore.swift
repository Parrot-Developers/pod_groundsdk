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

/// Calibration backend part.
public protocol CalibrationBackend: AnyObject {

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

/// Internal calibration peripheral implementation
public class CalibrationCore: PeripheralCore, Calibration {
    private(set) public var sensors: [CalibrationSensor] = []

    /// Implementation backend
    private unowned let backend: CalibrationBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: calibration backend
    public init(store: ComponentStoreCore, backend: CalibrationBackend) {
        self.backend = backend
        super.init(desc: Peripherals.calibration, store: store)
    }

    public func start(sensor: CalibrationSensorType) -> Bool {
        guard let sensorFound = sensors.first(where: { $0.type == sensor }) else {
            return false
        }
        return sensorFound.state != .inProgress && backend.start(sensor: sensor)
    }

    public func abort(sensor: CalibrationSensorType) -> Bool {
        guard let sensorFound = sensors.first(where: { $0.type == sensor }) else {
            return false
        }
        return sensorFound.state == .inProgress && backend.abort(sensor: sensor)
    }

    /// Updates the sensors array.
    ///
    /// - Parameter sensors: new sensors array
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(sensors newValue: [CalibrationSensor])
    -> CalibrationCore {
        if newValue != sensors {
            sensors = newValue
            markChanged()
        }
        return self
    }
}
