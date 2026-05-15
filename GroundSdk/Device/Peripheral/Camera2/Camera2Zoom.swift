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

/// Way of controlling the zoom.
public enum Camera2ZoomControlMode: String, CustomStringConvertible, CaseIterable {
    /// Control zoom giving level targets.
    case level
    /// Control zoom giving velocity targets.
    case velocity
    /// Control zoom giving horizontal field of view targets.
    case hfov

    /// Debug description.
    public var description: String { rawValue }
}

/// Zoom preset.
public enum Camera2ZoomPreset: String, CustomStringConvertible, CaseIterable {
    /// Wide preset.
    case wide
    /// Thermal preset.
    case thermal
    /// Tele preset.
    case tele
    /// Max preset.
    case max

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera subtype.
public enum Camera2Subtype: String, CustomStringConvertible, CaseIterable {
    /// Wide subtype.
    case wide
    /// Tele subtype.
    case tele

    /// Debug description.
    public var description: String { rawValue }
}

/// Zoom range of a camera module.
public struct Camera2ZoomRange: Equatable {

    /// Minimum zoom level available for the camera module.
    public var minLevel: Double

    /// Maximum zoom level available for the camera module.
    public var maxLevel: Double

    /// Maximum zoom level to keep image quality at its best.
    public var maxLosslessLevel: Double

    /// Minimum horizontal field of view available for the camera module, `nil` if unavailable.
    public var minHfov: Double?

    /// Maximum horizontal field of view available for the camera module, `nil` if unavailable.
    public var maxHfov: Double?

    /// Constructor
    ///
    /// - Parameters:
    ///   - minLevel: minimum zoom level available for the camera
    ///   - maxLevel: maximum zoom level available for the camera
    ///   - maxLosslessLevel: maximum zoom level to keep image quality at its best
    ///   - minHfov: minimum horizontal field of view available for the camera
    ///   - maxHfov: maximum horizontal field of view available for the camera
    public init(minLevel: Double, maxLevel: Double, maxLosslessLevel: Double, minHfov: Double?, maxHfov: Double?) {
        self.minLevel = minLevel
        self.maxLevel = maxLevel
        self.maxLosslessLevel = maxLosslessLevel
        self.minHfov = minHfov
        self.maxHfov = maxHfov
    }
}

/// Camera zoom component.
public protocol Camera2Zoom: Component {

    /// Current zoom level, in focal length factor, from 1 to `maxLevel`.
    ///
    /// 1 means no zoom.
    var level: Double { get }

    /// Maximum zoom level available on the device
    /// - Note: from `maxLossLessLevel` to this value, image quality is altered.
    var maxLevel: Double { get }

    /// Maximum zoom level to keep image quality at its best.
    /// - Note: If zoom level is greater than this value, image quality will be altered.
    var maxLossLessLevel: Double { get }

    /// Current horizontal field of view, in degrees, `nil` if not available
    var hfov: Double? { get }

    /// Horizontal field of view range of the camera, `nil` if not available
    var hfovRange: ClosedRange<Double>? { get }

    /// Whether zoom control is currently locked
    var isLocked: Bool { get }

    /// Zoom presets available on the device.
    var presets: [Camera2ZoomPreset: Double] { get }

    /// Zoom ranges by camera subtype.
    var ranges: [Camera2Subtype: Camera2ZoomRange] { get }

    /// Controls zoom.
    ///
    /// Unit of the `target` depends on `mode` parameter:
    ///    - `.level`: target is in zoom level. 1 means no zoom.
    ///               This value will be clamped to the `maxLevel` if it is greater than this value.
    ///    - `.velocity`: value is in signed ratio (from -1 to 1) of `Camera2Params.zoomMaxSpeed` setting value.
    ///                  Negative value will produce a zoom out, positive value will zoom in.
    ///    - `.hfov`: target is in horizontal field of view in degrees.
    ///
    /// - Parameters:
    ///   - mode: mode that should be used to control zoom
    ///   - target: either level or velocity zoom target
    func control(mode: Camera2ZoomControlMode, target: Double)

    /// Resets zoom level.
    func resetLevel()
}

/// :nodoc:
/// Camera2Zoom description.
public class Camera2ZoomDesc: NSObject, Camera2ComponentClassDesc {
    public typealias ApiProtocol = Camera2Zoom
    public let uid = Camera2ComponentUid.zoom.rawValue
    public let parent: ComponentDescriptor? = nil
}
