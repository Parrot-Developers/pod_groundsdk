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

/// Thermal control base backend part.
public protocol ThermalControlBaseBackend: AnyObject {

    /// Sets thermal camera calibration mode.
    ///
    /// - Parameter calibrationMode: the new calibration mode
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(calibrationMode: ThermalCalibrationMode) -> Bool

    /// Triggers a calibration of the thermal camera.
    ///
    /// - Returns: true if the command has been sent, false otherwise
    func calibrate() -> Bool

    /// Abort thermal camera calibration
    ///
    /// - Returns: true if the command has been sent, false otherwise
    func abortCalibration() -> Bool

    /// Confirms that the user did the required action.
    ///
    /// - Returns: true if the command has been sent, false otherwise
    func confirmUserAction() -> Bool

    /// Set power saving mode
    ///
    /// - Parameter powerSavingMode: power saving mode configuration
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(powerSavingMode: ThermalPowerSavingMode) -> Bool
}

/// Thermal camera calibration implementation
class ThermalCalibrationCore: ThermalCalibration, CustomDebugStringConvertible {

    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    /// Checks whether a user-action is required for the current state.
    var userActionRequired: Bool

    /// Supported calibration modes
    var supportedModes: Set<ThermalCalibrationMode> = [.automatic, .manual]

    /// Current calibration mode
    var mode: ThermalCalibrationMode {
        get {
            return _mode
        }
        set {
            if _mode != newValue, supportedModes.contains(newValue) {
                if backend.set(calibrationMode: newValue) {
                    let oldValue = _mode
                    // value sent to the backend, update setting value and mark it updating
                    _mode = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(mode: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }
    /// Calibration mode
    private var _mode: ThermalCalibrationMode = .automatic

    /// Calibration state
    private var _calibrationState: CalibrationState = .unknown

    /// Current calibration state
    var calibrationState: CalibrationState {
        return _calibrationState
    }

    /// Implementation backend
    private unowned let backend: ThermalControlBaseBackend

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: ThermalControlBaseBackend) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
        self.userActionRequired = false
    }

    /// Called by the backend, change the current calibration mode
    ///
    /// - Parameter mode: new thermal calibration mode
    /// - Returns: true if the setting has been changed, false otherwise
    func update(mode newMode: ThermalCalibrationMode) -> Bool {
        if updating || _mode != newMode {
            _mode = newMode
            timeout.cancel()
            return true
        }
        return false
    }

    /// Called by the backend, change the current supported mode
    ///
    /// - Parameter supportedMode: new supported mode
    /// - Returns: true if the setting has been changed, false otherwise
    func update(supportedMode newSupportedMode: Set<ThermalCalibrationMode>) -> Bool {
        if supportedModes != newSupportedMode {
            supportedModes = newSupportedMode
            timeout.cancel()
            return true
        }
        return false
    }

    /// Called by the backend, change the current calibration state
    ///
    /// - Parameter calibrationState: new calibration state
    /// - Returns: true if the setting has been changed, false otherwise
    func update(calibrationState newCalibrationState: CalibrationState) -> Bool {
        if updating || _calibrationState != newCalibrationState {
            _calibrationState = newCalibrationState
            timeout.cancel()
            return true
        }
        return false
    }

    /// Called by the backend, change the current user action requied
    ///
    /// - Parameter newUserActionRequired: new user action required
    /// - Returns: true if the setting has been changed, false otherwise
    func update(userActionRequired newUserActionRequired: Bool) -> Bool {
        if userActionRequired != newUserActionRequired {
            userActionRequired = newUserActionRequired
            timeout.cancel()
            return true
        }
        return false
    }

    /// Cancels any pending rollback.
    ///
    /// - Parameter completionClosure: block that will be called if a rollback was pending
    func cancelRollback(completionClosure: () -> Void) {
        if timeout.isScheduled {
            timeout.cancel()
            completionClosure()
        }
    }

    func calibrate() -> Bool {
        return backend.calibrate()
    }

    func abortCalibration() -> Bool {
        return backend.abortCalibration()
    }

    func confirmUserAction() -> Bool {
        return backend.confirmUserAction()
    }

    /// Debug description
    var debugDescription: String {
        return "calibration mode: \(_mode) \(supportedModes) updating: [\(updating)]"
    }
}

/// Internal thermal control peripheral implementation
public class ThermalControlBaseCore: PeripheralCore {
    /// Thermal camera calibration
    public var calibration: ThermalCalibration? {
        return _calibration
    }
    private var _calibration: ThermalCalibrationCore?

    /// Thermal power saving mode
    public var powerSavingMode: EnumSetting<ThermalPowerSavingMode> {
        return _powerSavingMode
    }
    private var _powerSavingMode: EnumSettingCore<ThermalPowerSavingMode>!

    /// Implementation backend
    internal unowned let backend: ThermalControlBaseBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///    - desc: component descriptor
    ///    - store: store where this peripheral will be stored
    ///    - backend: thermal control backend
    public init(desc: ComponentDescriptor, store: ComponentStoreCore, backend: ThermalControlBaseBackend) {
        self.backend = backend

        super.init(desc: desc, store: store)
        _powerSavingMode = EnumSettingCore<ThermalPowerSavingMode>(defaultValue: .max,
                                                               supportedValues: Set([ThermalPowerSavingMode.max]),
                                                               didChangeDelegate: self,
                                                                   backend: { [unowned self] powerSavingMode in
            return self.backend.set(powerSavingMode: powerSavingMode)})
    }
}

/// Backend callback methods
extension ThermalControlBaseCore {

    /// Updates thermal camera calibration mode.
    ///
    /// - Parameter mode: new calibration mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(mode newMode: ThermalCalibrationMode) -> ThermalControlBaseCore {
        if _calibration == nil {
            _calibration = ThermalCalibrationCore(didChangeDelegate: self, backend: backend)
            markChanged()
        }
        if _calibration!.update(mode: newMode) {
            markChanged()
        }
        return self
    }

    /// Updates thermal calibration state.
    ///
    /// - Parameter mode: new calibration state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(
        calibrationState newCalibrationState: CalibrationState) -> ThermalControlBaseCore {
        if _calibration == nil {
            _calibration = ThermalCalibrationCore(didChangeDelegate: self, backend: backend)
            markChanged()
        }
        if _calibration!.update(calibrationState: newCalibrationState) {
            markChanged()
        }
        return self
    }

    /// Updates thermal camera user action required.
    ///
    /// - Parameter mode: new user action required
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(
        userActionRequired newUserActionRequired: Bool) -> ThermalControlBaseCore {
        if _calibration == nil {
            _calibration = ThermalCalibrationCore(didChangeDelegate: self, backend: backend)
            markChanged()
        }
        if _calibration!.update(userActionRequired: newUserActionRequired) {
            markChanged()
        }
        return self
    }

    /// Updates supported calibration mode.
    ///
    /// - Parameter mode: new supported calibration mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(
        supportedCalibrationMode newSupportedCalibrationMode: Set<ThermalCalibrationMode>) -> ThermalControlBaseCore {
        if _calibration == nil {
            _calibration = ThermalCalibrationCore(didChangeDelegate: self, backend: backend)
            markChanged()
        }
        if _calibration!.update(supportedMode: newSupportedCalibrationMode) {
            markChanged()
        }
        return self
    }

    /// Updates supported power saving mode
    ///
    /// - Parameter supportedPowerSavingModes: new supported power saving modes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(
        supportedPowerSavingModes newSupportedPowerSavingModes: Set<ThermalPowerSavingMode>) -> ThermalControlBaseCore {
        if _powerSavingMode!.update(supportedValues: newSupportedPowerSavingModes) {
            markChanged()
        }
        return self
    }

    /// Updates power saving mode
    ///
    /// - Parameter powerSavingMode: new power saving mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(
        powerSavingMode newPowerSavingMode: ThermalPowerSavingMode) -> ThermalControlBaseCore {
        if _powerSavingMode!.update(value: newPowerSavingMode) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @objc @discardableResult public func cancelSettingsRollback() -> ThermalControlBaseCore {
        _calibration?.cancelRollback { markChanged() }
        _powerSavingMode?.cancelRollback { markChanged() }
        return self
    }
}
