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

/// Flight camera recorder backend part.
public protocol FlightCameraRecorderBackend: AnyObject {
    /// Sets flight camera recorder pipeline configuration identifier.
    ///
    /// - Parameter pipelineConfigId: the new flight camera recorder pipeline configuration identifier.
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(pipelineConfigId: UInt64) -> Bool
}

/// Core implementation of FlightCameraRecorderPipelinesSetting.
class FlightCameraRecorderPipelinesSettingCore: FlightCameraRecorderPipelinesSetting, CustomDebugStringConvertible {
    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    /// Flight camera recorder pipeline configuration identifier.
    var id: UInt64 {
        get {
            return _id
        }

        set {
            if _id != newValue {
                if backend(newValue) {
                    let oldValue = _id
                    // value sent to the backend, update setting value and mark it updating
                    _id = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(newId: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }

    /// Flight camera recorder pipeline configuration identifier.
    private var _id = UInt64(0)

    /// Closure to call to change the value
    private let backend: ((UInt64) -> Bool)

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (UInt64) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Changes flight camera recorder pipelines configuration identifier.
    ///
    /// - Parameter activePipelines: new set of active pipelines
    /// - Returns: true if the setting has been changed, false otherwise
    func update(newId: UInt64) -> Bool {
        if updating || _id != newId {
            _id = newId
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

    /// Debug description.
    var debugDescription: String {
        return "\(id) [updating: \(updating)]"
    }

}

/// Internal flight camera recorder peripheral implementation
public class FlightCameraRecorderCore: PeripheralCore, FlightCameraRecorder {
    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    public var pipelines: FlightCameraRecorderPipelinesSetting {
        return _pipelines
    }

    /// Internal storage for active pipelines setting.
    private var _pipelines: FlightCameraRecorderPipelinesSettingCore!

    /// Implementation backend
    private unowned let backend: FlightCameraRecorderBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: Flight camera recorder backend
    public init(store: ComponentStoreCore, backend: FlightCameraRecorderBackend) {
        self.backend = backend
        super.init(desc: Peripherals.flightCameraRecorder, store: store)
        _pipelines = FlightCameraRecorderPipelinesSettingCore(
        didChangeDelegate: self) { [unowned self] id in
            return self.backend.set(pipelineConfigId: id)
        }
    }
}

extension FlightCameraRecorderCore {

    /// Called by the backend, change the setting data
    ///
    /// - Parameter pipelineConfigId: new pipeline configuration identifier
    /// - Returns: self to allow call chaining
    @discardableResult public func update(pipelineConfigId: UInt64) -> FlightCameraRecorderCore {
        if _pipelines.update(newId: pipelineConfigId) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - note: changes are not notified until notifyUpdated() is called
    @discardableResult public func cancelSettingsRollback() -> FlightCameraRecorderCore {
        _pipelines.cancelRollback { markChanged() }
        return self
    }
}
