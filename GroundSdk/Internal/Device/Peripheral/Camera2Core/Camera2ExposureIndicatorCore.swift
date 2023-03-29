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

/// Internal camera exposure indicator core implementation.
public class Camera2ExposureIndicatorCore: ComponentCore, Camera2ExposureIndicator {

    private(set) public var shutterSpeed = Camera2ShutterSpeed.oneOver10000

    private(set) public var isoSensitivity = Camera2Iso.iso50

    private(set) public var lockRegion: (centerX: Double, centerY: Double, width: Double, height: Double)?

    /// Constructor.
    ///
    /// - Parameter store: component store owning this component
    public init(store: ComponentStoreCore) {
        super.init(desc: Camera2Components.exposureIndicator, store: store)
    }
}

/// Backend callback methods.
extension Camera2ExposureIndicatorCore {
    /// Updates the shutter speed value.
    ///
    /// - Parameter shutterSpeed: new shutter speed value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(shutterSpeed newValue: Camera2ShutterSpeed) -> Camera2ExposureIndicatorCore {
        if shutterSpeed != newValue {
            markChanged()
            shutterSpeed = newValue
        }
        return self
    }

    /// Updates the iso sensitivity value.
    ///
    /// - Parameter isoSensitivity: new iso sensitivity value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(isoSensitivity newValue: Camera2Iso) -> Camera2ExposureIndicatorCore {
        if isoSensitivity != newValue {
            markChanged()
            isoSensitivity = newValue
        }
        return self
    }

    /// Updates the exposure lock region.
    ///
    /// - Parameter lockRegion: new exposure lock region
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(centerX: Double, centerY: Double, width: Double, height: Double)
        -> Camera2ExposureIndicatorCore {
        if lockRegion == nil
            || lockRegion!.centerX != centerX || lockRegion!.centerY != centerY
            || lockRegion!.width != width || lockRegion!.height != height {
            markChanged()
            lockRegion = (centerX: centerX, centerY: centerY, width: width, height: height)
        }
        return self
    }

    /// Resets the exposure lock region to `nil`.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func clearLockRegion() -> Camera2ExposureIndicatorCore {
        if lockRegion != nil {
            markChanged()
            lockRegion = nil
        }
        return self
    }
}
