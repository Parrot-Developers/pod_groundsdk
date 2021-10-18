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

/// FollowMePilotingItf backend protocol
public protocol FollowMePilotingItfBackend: TrackingPilotingItfBackend {
    /// Set the desired follow mode
    func set(followMode newFollowMode: FollowMode) -> Bool
}

/// Internal FollowModeSetting implementation
class FollowModeSettingCore: FollowModeSetting, CustomStringConvertible {
    /// Delegate called when the setting value is changed by setting `value` property
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    private(set) var supportedModes: Set<FollowMode> = []

    /// Setting current value
    public var value: FollowMode {
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
                        if let `self` = self, self.update(followMode: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }
    /// Internal value
    private var _value = FollowMode.geographic

    /// Closure to call to change the value.
    /// Return `true` if the new value has been sent and setting must become updating.
    private let backend: (FollowMode) -> Bool

    /// Debug description.
    public var description: String {
        return "\(value) [\(updating)]"
    }

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting `value` property
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (FollowMode) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, change the supported follow modes
    ///
    /// - Parameter supportedFollowMode: new supported follow modes
    /// - Returns: `true` if the setting has been changed
    func update(supportedFollowModes newValue: Set<FollowMode>) -> Bool {
        var changed = false

        if supportedModes != newValue {
            supportedModes = newValue
            changed = true
        }
        return changed
    }

    /// Called by the backend, change the follow mode setting
    ///
    /// - Parameter followMode: new value for followMode
    /// - Returns: true if the setting has been changed, false else
    func update(followMode newValue: FollowMode) -> Bool {
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

extension FollowModeSettingCore: GSFollowModeSetting {
    func modeIsSupported(_ mode: FollowMode) -> Bool {
        return supportedModes.contains(mode)
    }
}

/// Internal FollowMe piloting interface implementation
public class FollowMePilotingItfCore: TrackingPilotingItfCore, FollowMePilotingItf {

    /// The follow mode to use. Note: this setting is not saved at the application level.
    public var followMode: FollowModeSetting {
        return _followMode
    }
    /// Internal value
    private var _followMode: FollowModeSettingCore!

    public private(set) var followBehavior: FollowBehavior?

    /// Super class backend as FollowMePilotingItfBackend
    private var followMeBackend: FollowMePilotingItfBackend {
        return backend as! FollowMePilotingItfBackend
    }

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this interface will be stored
    ///    - backend: FollowMePilotingItf backend
    public init(store: ComponentStoreCore, backend: FollowMePilotingItfBackend) {
        super.init(desc: PilotingItfs.followMe, store: store, backend: backend)
        _followMode = FollowModeSettingCore(didChangeDelegate: self, backend: { [unowned self] followMode in
                return self.followMeBackend.set(followMode: followMode)
        })
    }
}

/// Backend callback methods
extension FollowMePilotingItfCore {

    /// Updates the supported followMode
    ///
    /// - Parameter newValue: new supported followMode
    /// - Returns: self to allow call chaining
    @discardableResult public func update(supportedFollowModes newValue: Set<FollowMode>) -> FollowMePilotingItfCore {
        if _followMode.update(supportedFollowModes: newValue) {
            markChanged()
        }
        return self
    }

    /// Updates the followMode
    ///
    /// - Parameter newValue: new followMode
    /// - Returns: self to allow call chaining
    @discardableResult public func update(followMode newValue: FollowMode) -> FollowMePilotingItfCore {
        if _followMode.update(followMode: newValue) {
            markChanged()
        }
        return self
    }

    /// Change followBehavior
    ///
    /// - Parameter followBehavior: new followBehavior
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(followBehavior newValue: FollowBehavior?) -> FollowMePilotingItfCore {
        if followBehavior != newValue {
            followBehavior = newValue
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> FollowMePilotingItfCore {
        _followMode.cancelRollback { markChanged() }
        return self
    }
}

// MARK: - objc compatibility

/// Internal FollowMePilotingItfCore implementation for objectiveC
extension FollowMePilotingItfCore: GSFollowMePilotingItf {

    public var gsFollowMode: GSFollowModeSetting {
        return _followMode
    }

    /// The current follow state if this interface is `.active`, otherwise the value is not significant.
    ///
    /// When the FollowMe mode is active, the drone follows its target (moving the drone and the camera). If the Follow
    /// mode prerequisites are not met, the drone may remain stationary (while visually following its target).
    public var gsFollowBehavior: FollowBehavior {
        if let followBehavior = followBehavior {
            return followBehavior
        } else {
            return .stationary
        }
    }
}
