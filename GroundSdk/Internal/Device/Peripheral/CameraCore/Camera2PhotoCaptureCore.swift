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

/// Photo capture backend.
protocol Camera2PhotoCaptureBackend: AnyObject {
    /// Starts recording.
    ///
    /// - Returns: true if the command has been sent, false otherwise
    func startPhotoCapture() -> Bool

    /// Stops recording.
    ///
    /// - Returns: true if the command has been sent, false otherwise
    func stopPhotoCapture() -> Bool
}

/// Camera photo capture core implementation.
public class Camera2PhotoCaptureCore: ComponentCore, Camera2PhotoCapture {

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Backend of this object.
    private unowned let backend: Camera2PhotoCaptureBackend

    /// Camera photo capture state.
    public var state = Camera2PhotoCaptureState.stopped(latestSavedMediaId: nil)

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored
    ///   - backend: the backend (unowned)
    init(store: ComponentStoreCore, backend: Camera2PhotoCaptureBackend) {
        self.backend = backend
        super.init(desc: Camera2Components.photoCapture, store: store)
    }

    public func start() {
        if state.canStart, backend.startPhotoCapture() {
            set(state: .starting)
        }
    }

    public func stop() {
        if state.canStop, backend.stopPhotoCapture() {
            set(state: .stopping(reason: .userRequest, savedMediaId: nil))
        }
    }

    /// Change the state from the api.
    ///
    /// - Parameter newMode: the new mode to set
    private func set(state newState: Camera2PhotoCaptureState) {
        if state != newState {
            let oldState = state
            state = newState
            timeout.schedule { [weak self] in
                if let `self` = self, self._update(state: oldState) {
                    self.userDidChangeSetting()
                }
            }
            userDidChangeSetting()
        }
    }

    /// Changes photo capture state.
    ///
    /// - Parameters:
    ///   - state: new state
    /// - Returns: true if the state has been changed, false otherwise
    public func _update(state newState: Camera2PhotoCaptureState) -> Bool {
        if state != newState {
            state = newState
            timeout.cancel()
            return true
        }
        return false
    }
}

/// Backend callback methods.
extension Camera2PhotoCaptureCore {
    /// Changes photo capture state.
    ///
    /// - Parameters:
    ///   - state: new state
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func update(state newState: Camera2PhotoCaptureState) -> Camera2PhotoCaptureCore {
        if _update(state: newState) {
            markChanged()
        }
        return self
    }

    /// Cancels any pending rollback.
    ///
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func cancelRollback() -> Camera2PhotoCaptureCore {
        if timeout.isScheduled {
            timeout.cancel()
        }
        return self
    }
}
