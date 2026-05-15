// Copyright (C) 2025 Parrot Drones SAS
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

/// Camera 2 alignment backend part.
public protocol Camera2AlignmentBackend: AnyObject {

    /// Sets the thermal alignment offset on a given axis.
    ///
    /// - Parameters:
    ///   - offset: the desired offset
    ///   - axis: the axis
    /// - Returns: true if the command has been sent.
    func setThermal(offset: Double, axis: AlignmentAxis) -> Bool
}

/// Camera 2 alignment core implementation.
public class Camera2AlignmentCore: ComponentCore, Camera2Alignment {

    public var thermalSettings: [AlignmentAxis: DoubleSetting] {
        return _thermalSettings
    }
    private var _thermalSettings: [AlignmentAxis: DoubleSettingCore] = [:]

    /// Implementation backend
    private unowned let backend: Camera2AlignmentBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: store where this component will be stored
    ///   - backend: camera 2 alignment backend
    init(store: ComponentStoreCore, backend: Camera2AlignmentBackend) {
        self.backend = backend
        super.init(desc: Camera2Components.alignment, store: store)
    }

    /// Updates the thermal alignment setting for a given axis.
    ///
    /// - Note:
    ///   - changes are not notified until notifyUpdated() is called
    ///
    /// - Parameters:
    ///   - newSetting: tuple containing new values. Only not nil values are updated
    ///   - axis: the axis
    /// - Returns: self to allow call chaining
    @discardableResult public func update(thermalSetting newSetting: (min: Double?, value: Double?, max: Double?),
        onAxis axis: AlignmentAxis) -> Camera2AlignmentCore {
        if _thermalSettings[axis] == nil {
            _thermalSettings[axis] = DoubleSettingCore(didChangeDelegate: self) { [unowned self] newValue in
                return self.backend.setThermal(offset: newValue, axis: axis)
            }
        }

        if _thermalSettings[axis]!.update(min: newSetting.min, value: newSetting.value, max: newSetting.max) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> Camera2AlignmentCore {
        AlignmentAxis.allCases.forEach { axis in
            _thermalSettings[axis]?.cancelRollback { markChanged() }
        }
        return self
    }
}
