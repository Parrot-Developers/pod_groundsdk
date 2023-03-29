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

/// Zoom backend.
protocol Camera2ZoomBackend: AnyObject {
    /// Controls zoom.
    ///
    /// Unit of the `target` depends on `mode` parameter:
    ///    - `.level`: target is in zoom level.1 means no zoom.
    ///               This value will be clamped to the `maxLevel` if it is greater than this value.
    ///    - `.velocity`: value is in signed ratio (from -1 to 1) of `Camera2Params.zoomMaxSpeed` setting value.
    ///                   Negative values will produce a zoom out, positive value will zoom in.
    ///
    /// - Parameters:
    ///   - mode: mode that should be used to control zoom
    ///   - target: either level or velocity zoom target
    func control(mode: Camera2ZoomControlMode, target: Double)

    /// Resets zoom level.
    ///
    /// The camera will reset the zoom level to 1, as fast as it can.
    func resetLevel()
}

/// Camera zoom core implementation.
public class Camera2ZoomCore: ComponentCore, Camera2Zoom {

    /// Backend of this object.
    private unowned let backend: Camera2ZoomBackend

    public private(set) var level = 1.0

    public private(set) var maxLevel = 1.0

    public private(set) var maxLossLessLevel = 1.0

    /// Range of the level.
    /// Express that the level can go from 1.0 to `maxLevel`.
    private var levelRange: ClosedRange<Double> {
        if maxLevel > 1 {
            return 1...maxLevel
        } else {
            return 1...1
        }
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: store where this component will be stored
    ///   - backend: the backend (unowned)
    init(store: ComponentStoreCore, backend: Camera2ZoomBackend) {
        self.backend = backend
        super.init(desc: Camera2Components.zoom, store: store)
    }

    public func control(mode: Camera2ZoomControlMode, target: Double) {
        let clampedTarget: Double
        switch mode {
        case .level:
            clampedTarget = levelRange.clamp(target)
        case .velocity:
            clampedTarget = signedPercentIntervalDouble.clamp(target)
        }
        backend.control(mode: mode, target: clampedTarget)
    }

    public func resetLevel() {
        backend.resetLevel()
    }
}

/// Backend callback methods.
extension Camera2ZoomCore {
    /// Changes zoom level.
    ///
    /// - Parameter level: new zoom level
    /// - Returns: self, to allow call chaining
    public func update(level newValue: Double) -> Camera2ZoomCore {
        if level != newValue {
            level = newValue
            markChanged()
        }
        return self
    }

    /// Changes max zoom level.
    ///
    /// - Parameter maxLevel: new max zoom level
    /// - Returns: self, to allow call chaining
    public func update(maxLevel newValue: Double) -> Camera2ZoomCore {
        if maxLevel != newValue {
            maxLevel = newValue
            markChanged()
        }
        return self
    }

    /// Changes max loss less (i.e. without quality degradation) zoom level.
    ///
    /// - Parameter maxLossLessLevel: new max loss less zoom level
    /// - Returns: self, to allow call chaining
    public func update(maxLossLessLevel newValue: Double) -> Camera2ZoomCore {
        if maxLossLessLevel != newValue {
            maxLossLessLevel = newValue
            markChanged()
        }
        return self
    }
}
