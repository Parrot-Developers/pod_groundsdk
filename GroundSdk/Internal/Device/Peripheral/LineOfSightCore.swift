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

/// LineOfSight backend part.
public protocol LineOfSightBackend: AnyObject {
    /// Starts calibration process.
    func calibrate()

    /// Resets line of sight calibration.
    func resetCalibration()
}

/// Internal LineOfSight peripheral implementation
public class LineOfSightCore: PeripheralCore, LineOfSight {

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    private(set) public var currentIssues: Set<LineOfSightCalibrationIssue> = []

    private(set) public var calibrationState: LineOfSightCalibrationState = .required

    private(set) public var calibrationResult: LineOfSightCalibrationResult?

    private(set) public var failureReasons: Set<LineOfSightCalibrationFailureReason> = []

    /// Implementation backend
    unowned let backend: LineOfSightBackend

    /// Constructor
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored
    ///   - backend: LineOfSight backend
    public init(store: ComponentStoreCore, backend: LineOfSightBackend) {
        self.backend = backend
        super.init(desc: Peripherals.lineOfSight, store: store)
    }

    public func calibrate() {
        if currentIssues.isEmpty {
            backend.calibrate()
            set(state: .calibrating)
        }
    }

    /// Change the state from the api.
    ///
    /// - Parameter newState: the new state to set
    private func set(state newState: LineOfSightCalibrationState) {
        if calibrationState != newState {
            let oldState = calibrationState
            calibrationState = newState
            timeout.schedule { [weak self] in
                if let `self` = self, self._update(calibrationState: oldState) {
                    self.userDidChangeSetting()
                }
            }
            userDidChangeSetting()
        }
    }

    /// Changes calibration state.
    ///
    /// - Parameter newState: new calibration state
    /// - Returns: true if the state has been changed, false otherwise
    private func _update(calibrationState newState: LineOfSightCalibrationState) -> Bool {
        if calibrationState != newState {
            calibrationState = newState
            timeout.cancel()
            return true
        }
        return false
    }

    public func resetCalibration() {
        backend.resetCalibration()
    }
}

/// Backend callback methods
extension LineOfSightCore {

    /// Updates the set of current issues.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: new set of current issues
    /// - Returns: self to allow call chaining
    @discardableResult public func update(currentIssues newValue: Set<LineOfSightCalibrationIssue>) -> LineOfSightCore {
        if newValue != currentIssues {
            currentIssues = newValue
            markChanged()
        }
        return self
    }

    /// Updates the calibration state.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: new calibration state
    /// - Returns: self to allow call chaining
    @discardableResult public func update(calibrationState newValue: LineOfSightCalibrationState) -> LineOfSightCore {
        if _update(calibrationState: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates the calibration result.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: new calibration result
    /// - Returns: self to allow call chaining
    @discardableResult public func update(calibrationResult
                                          newValue: LineOfSightCalibrationResult?) -> LineOfSightCore {
        if calibrationResult != newValue {
            calibrationResult = newValue
            markChanged()
        }
        return self
    }

    /// Updates the set of failure reasons.
    ///
    /// - Note: Changes are not notified until notifyUpdated() is called.
    ///
    /// - Parameter newValue: new set of failure reasons
    /// - Returns: self to allow call chaining
    @discardableResult public func update(failureReasons newValue:
                                          Set<LineOfSightCalibrationFailureReason>) -> LineOfSightCore {
        if newValue != failureReasons {
            failureReasons = newValue
            markChanged()
        }
        return self
    }
}
