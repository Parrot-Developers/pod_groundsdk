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

/// Obstacle avoidance backend part.
public protocol ObstacleAvoidanceBackend: AnyObject {
    /// Sets obstacle avoidance preferred mode.
    ///
    /// - Parameter preferredMode: the new preferred mode
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(preferredMode: ObstacleAvoidanceMode) -> Bool
}

/// Core implementation of ObstacleAvoidanceSetting.
class ObstacleAvoidanceSettingCore: ObstacleAvoidanceSetting, CustomDebugStringConvertible {
    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    /// Supported obstacle avoidance modes.
    public private(set) var supportedValues: Set<ObstacleAvoidanceMode> = [.disabled, .standard]

    /// Obstacle avoidance preferred mode.
    public var preferredValue: ObstacleAvoidanceMode {
        get {
            return _preferredValue
        }
        set {
            if _preferredValue != newValue {
                if supportedValues.contains(newValue) && backend(newValue) {
                    let oldValue = _preferredValue
                    // value sent to the backend, update setting value and mark it updating
                    _preferredValue = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(preferredMode: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }

    /// Obstacle avoidance mode.
    private var _preferredValue: ObstacleAvoidanceMode = .disabled

    /// Closure to call to change the value
    private let backend: ((ObstacleAvoidanceMode) -> Bool)

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (ObstacleAvoidanceMode) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Changes obstacle avoidance preferred mode.
    ///
    /// - Parameter preferredMode: new obstacle avoidance preferred mode
    /// - Returns: true if the setting has been changed, false otherwise
    func update(preferredMode newPreferredMode: ObstacleAvoidanceMode) -> Bool {
        if updating || _preferredValue != newPreferredMode {
            _preferredValue = newPreferredMode
            timeout.cancel()
            return true
        }
        return false
    }

    /// Cancels any pending rollback.
    ///
    /// - Parameter completionClosure: block that will be called if a rollback was pending
    func cancelRollback(completionClosure: () -> Void) {
        if timeout.cancel() {
            completionClosure()
        }
    }

    /// Debug description.
    var debugDescription: String {
        return "\(preferredValue.description) \(supportedValues) [updating: \(updating)]"
    }

}

/// Internal obstacle avoidance peripheral implementation.
public class ObstacleAvoidanceCore: PeripheralCore, ObstacleAvoidance {

    public var mode: ObstacleAvoidanceSetting {
        return _mode
    }

    /// Internal storage for mode setting.
    private var _mode: ObstacleAvoidanceSettingCore!

    public private(set) var state = ObstacleAvoidanceState.inactive

    /// Implementation backend.
    private unowned let backend: ObstacleAvoidanceBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: obstacle avoidance backend
    public init(store: ComponentStoreCore, backend: ObstacleAvoidanceBackend) {
        self.backend = backend
        super.init(desc: Peripherals.obstacleAvoidance, store: store)
        _mode = ObstacleAvoidanceSettingCore(didChangeDelegate: self) { [unowned self] preferredMode in
            return self.backend.set(preferredMode: preferredMode)
        }

    }
}

/// Backend callback methods.
extension ObstacleAvoidanceCore {

    /// Updates obstacle avoidance state.
    ///
    /// - Parameter state: new state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(state newState: ObstacleAvoidanceState) -> ObstacleAvoidanceCore {
        if state != newState {
            state = newState
            markChanged()
        }
        return self
    }

    /// Updates obstacle avoidance preferred mode.
    ///
    /// - Parameter mode: new preferred mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(preferredMode newPreferredMode: ObstacleAvoidanceMode) -> ObstacleAvoidanceCore {
        if _mode.update(preferredMode: newPreferredMode) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func cancelSettingsRollback() -> ObstacleAvoidanceCore {
        _mode.cancelRollback { markChanged() }
        return self
    }
}
