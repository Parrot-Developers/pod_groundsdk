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

/// LookAtPilotingItf backend protocol
public protocol LookAtPilotingItfBackend: TrackingPilotingItfBackend {
    /// Set the desired look at mode
    func set(lookAtMode newLookAtMode: LookAtMode) -> Bool
}

/// Internal LookAtModeSetting implementation
class LookAtModeSettingCore: LookAtModeSetting, CustomStringConvertible {
    /// Delegate called when the setting value is changed by setting `value` property
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    private(set) var supportedModes: Set<LookAtMode> = [.lookAt]

    /// Setting current value
    public var value: LookAtMode {
        get {
            return _value
        }
        set {
            if supportedModes.contains(newValue) && _value != newValue {
                if backend(newValue) {
                    let oldValue = _value
                    // value sent to the backend, update setting value and mark it updating
                    _value = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(lookAtMode: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }
    /// Internal value
    private var _value = LookAtMode.lookAt

    /// Closure to call to change the value.
    /// Return `true` if the new value has been sent and setting must become updating.
    private let backend: (LookAtMode) -> Bool

    /// Debug description.
    public var description: String {
        return "\(value) [\(updating)]"
    }

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting `value` property
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (LookAtMode) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, change the supported look at modes
    ///
    /// - Parameter supportedLookAtMode: new supported look at modes
    /// - Returns: `true` if the setting has been changed
    func update(supportedLookAtModes newValue: Set<LookAtMode>) -> Bool {
        var changed = false

        if supportedModes != newValue {
            supportedModes = newValue
            changed = true
        }
        return changed
    }

    /// Called by the backend, change the look at mode setting
    ///
    /// - Parameter lookAtMode: new value for lookAtMode
    /// - Returns: true if the setting has been changed, false else
    func update(lookAtMode newValue: LookAtMode) -> Bool {
        var changed = false

        if updating || _value != newValue {
            _value = newValue
            changed = true
            timeout.cancel()
        }
        return changed
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
}

/// Internal LookAt piloting interface implementation
public class LookAtPilotingItfCore: TrackingPilotingItfCore, LookAtPilotingItf {
    /// The look at mode to use. Note: this setting is not saved at the application level.
    public var lookAtMode: LookAtModeSetting {
        return _lookAtMode
    }
    /// Internal value
    private var _lookAtMode: LookAtModeSettingCore!

    /// Super class backend as LookAtMePilotingItfBackend
    private var lookAtBackend: LookAtPilotingItfBackend {
        return backend as! LookAtPilotingItfBackend
    }

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this interface will be stored
    ///    - backend: LookAtPilotingItf backend
    public init(store: ComponentStoreCore, backend: LookAtPilotingItfBackend) {
        super.init(desc: PilotingItfs.lookAt, store: store, backend: backend)
        _lookAtMode = LookAtModeSettingCore(didChangeDelegate: self, backend: { [unowned self] lookAtMode in
                return self.lookAtBackend.set(lookAtMode: lookAtMode)
        })
    }
}

/// Backend callback methods
extension LookAtPilotingItfCore {

    /// Updates the supported lookAtMode
    ///
    /// - Parameter newValue: new supported lookAtMode
    /// - Returns: self to allow call chaining
    @discardableResult public func update(supportedLookAtModes newValue: Set<LookAtMode>) -> LookAtPilotingItfCore {
        if _lookAtMode.update(supportedLookAtModes: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates the lookAtMode
    ///
    /// - Parameter newValue: new lookAtMode
    /// - Returns: self to allow call chaining
    @discardableResult public func update(lookAtMode newValue: LookAtMode) -> LookAtPilotingItfCore {
        if _lookAtMode.update(lookAtMode: newValue) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> LookAtPilotingItfCore {
        _lookAtMode.cancelRollback { markChanged() }
        return self
    }
}

extension LookAtModeSettingCore: GSLookAtModeSetting {
    func modeIsSupported(_ mode: LookAtMode) -> Bool {
        return supportedModes.contains(mode)
    }
}
