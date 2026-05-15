// Copyright (C) 2024 Parrot Drones SAS
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

/// Camera user location from image coordinates core implementation.
public class Camera2UserLficCore: ComponentCore, Camera2UserLfic {

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    public var updating: Bool { return timeout.isScheduled }

    public var coordinates: CGPoint? {
        get {
            return _coordinates
        }
        set {
            var clampedValue: CGPoint?
            if let newValue {
                clampedValue = CGPoint()
                clampedValue?.x = range.clamp(newValue.x)
                clampedValue?.y = range.clamp(newValue.y)
            }
            if _coordinates != clampedValue && backend(clampedValue) {
                let oldValue = _coordinates
                // value sent to the backend, update setting value and mark it updating
                _coordinates = clampedValue
                timeout.schedule { [weak self] in
                    if let `self` = self, self.update(value: oldValue) {
                        self.userDidChangeSetting()
                    }
                }
                userDidChangeSetting()
            }
        }
    }

    /// Range of the coordinates
    private let range = 0.0...1.0

    /// Closure to call to change the mode.
    private let backend: ((CGPoint?) -> Bool)

    /// Coordinates
    private var _coordinates: CGPoint?

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: store where this component will be stored
    ///   - backend: UserLfic backend
    init(store: ComponentStoreCore, backend: @escaping (CGPoint?) -> Bool) {
        self.backend = backend
        super.init(desc: Camera2Components.userLfic, store: store)
    }

    /// Called by the backend, change the current value
    ///
    /// - Parameter value: the new value
    /// - Returns: true if the setting has been changed, false else
    func update(value newValue: CGPoint?) -> Bool {
        // clamp value if necessary
        var clampedValue: CGPoint?
        if let newValue {
            clampedValue = CGPoint()
            clampedValue?.x = range.clamp(newValue.x)
            clampedValue?.y = range.clamp(newValue.y)
        }
        if updating || _coordinates != clampedValue {
            _coordinates = clampedValue
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

    /// Debug description
    override public var debugDescription: String {
        return "value: \(String(describing: _coordinates)) updating: [\(updating)]"
    }
}

extension Camera2UserLficCore {
    /// Changes user location from image coordinates.
    ///
    /// - Parameter current: new user lfic
    /// - Returns: self, to allow call chaining
    public func update(current newValue: CGPoint?) -> Camera2UserLficCore {
        if self.update(value: newValue) {
            markChanged()
        }
        return self
    }
}
