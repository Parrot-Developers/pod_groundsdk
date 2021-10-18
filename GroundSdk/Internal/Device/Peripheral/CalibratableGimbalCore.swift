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

/// Gimbal backend part.
public protocol CalibratableGimbalBackend: AnyObject {
    /// Starts calibration process.
    func startCalibration()

    /// Cancels calibration process.
    func cancelCalibration()
}

/// Internal gimbal peripheral implementation
public class CalibratableGimbalCore: PeripheralCore, CalibratableGimbal {

    private(set) public var currentErrors: Set<GimbalError> = []

    /// Tells whether the gimbal is calibrated.
    private(set) public var calibrated = false

    /// Calibration process state.
    private(set) public var calibrationProcessState = GimbalCalibrationProcessState.none

    /// Implementation backend
    unowned let backend: CalibratableGimbalBackend

    /// Constructor
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored
    ///   - backend: gimbal backend
    public init(desc: ComponentDescriptor, store: ComponentStoreCore, backend: CalibratableGimbalBackend) {
        self.backend = backend
        super.init(desc: desc, store: store)
    }

    public func startCalibration() {
        if calibrationProcessState != .calibrating {
            backend.startCalibration()
        }
    }

    public func cancelCalibration() {
        if calibrationProcessState == .calibrating {
            backend.cancelCalibration()
        }
    }

}

/// Backend callback methods
extension CalibratableGimbalCore {

    /// Updates the set of current errors.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: new set of current errors
    /// - Returns: self to allow call chaining
    @discardableResult public func update(currentErrors newValue: Set<GimbalError>) -> CalibratableGimbalCore {
        if newValue != currentErrors {
            currentErrors = newValue
            markChanged()
        }
        return self
    }

    /// Updates the calibrated state.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: whether the gimbal is calibrated
    /// - Returns: self to allow call chaining
    @discardableResult public func update(calibrated newValue: Bool) -> CalibratableGimbalCore {
        if calibrated != newValue {
            calibrated = newValue
            markChanged()
        }
        return self
    }

    /// Updates the calibration process state.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: new calibration process state
    /// - Returns: self to allow call chaining
    @discardableResult public func update(
        calibrationProcessState newValue: GimbalCalibrationProcessState) -> CalibratableGimbalCore {
        if calibrationProcessState != newValue {
            calibrationProcessState = newValue
            markChanged()
        }
        return self
    }
}

/// Extension of Gimbal that implements ObjC API
extension CalibratableGimbalCore: GSCalibratableGimbal {
    public func hasError(_ error: GimbalError) -> Bool {
        return currentErrors.contains(error)
    }
}
