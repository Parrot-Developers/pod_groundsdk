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

/// Thermal control modes.
public enum ThermalControlMode: Int, CustomStringConvertible, CaseIterable {
    /// Thermal control is off.
    case disabled
    /// Thermal control is enabled, in standard mode, blending on device.
    case standard
    /// Thermal control is enabled, blending on drone.
    case blended

    /// Debug description.
    public var description: String {
        switch self {
        case .disabled: return "disabled"
        case .standard: return "standard"
        case .blended: return "blended"
        }
    }
}

/// Thermal rendering modes.
public enum ThermalRenderingMode: Int, CustomStringConvertible, CaseIterable {
    /// Visible image only.
    case visible
    /// Thermal image only.
    case thermal
    /// Blending between visible and thermal images.
    case blended
    /// Visible image is in black and white.
    case monochrome

    /// Debug description.
    public var description: String {
        switch self {
        case .visible: return "visible"
        case .thermal: return "thermal"
        case .blended: return "blended"
        case .monochrome: return "monochrome"
        }
    }
}

/// Thermal sensitivity ranges.
public enum ThermalSensitivityRange: Int, CustomStringConvertible, CaseIterable {
    /// Thermal sensitivity range is high (from -10 to 400°C).
    case high
    /// Thermal sensitivity range is low (from -10 to 140°C).
    case low

    /// Debug description.
    public var description: String {
        switch self {
        case .high: return "high"
        case .low: return "low"
        }
    }
}

/// Setting to change the thermal control mode.
public protocol ThermalControlSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported modes.
    var supportedModes: Set<ThermalControlMode> { get }

    /// Current thermal control mode setting.
    var mode: ThermalControlMode { get set }
}

/// Setting to change the thermal rendering mode.
public protocol ThermalRenderingSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported modes.
    var supportedModes: Set<ThermalRenderingMode> { get }

    /// Current thermal control mode setting.
    var rendering: ThermalRendering { get set }
}

/// Protocol for thermal palette setting
public protocol ThermalPaletteSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Current thermal palette.
    var palette: ThermalPalette { get set }
}

/// Thermal palette colorization modes.
public enum ThermalColorizationMode: Int, CustomStringConvertible, CaseIterable {
    /// Use black color if temperature is outside palette bounds.
    case limited
    /// Use boundaries colors if temperature is outside palette bounds.
    case extended

    /// Debug description.
    public var description: String {
        switch self {
        case .limited: return "limited"
        case .extended: return "extended"
        }
    }
}

/// Thermal spot palette types.
public enum ThermalSpotType: Int, CustomStringConvertible {
    /// Colorize only if temperature is below threshold.
    case cold
    /// Colorize only if temperature is above threshold.
    case hot

    /// Debug description.
    public var description: String {
        switch self {
        case .cold: return "cold"
        case .hot: return "hot"
        }
    }
}

/// Thermal rendering.
public struct ThermalRendering: Equatable {
    /// Rendering mode.
    public let mode: ThermalRenderingMode

    /// Blending rate, in range [0, 1], used only in blended mode.
    public let blendingRate: Double

    /// Constructor.
    ///
    /// - Parameters:
    ///    - mode: mode
    ///    - blendingRate: blending rate, in range [0, 1], used only in blended mode
    public init (mode: ThermalRenderingMode, blendingRate: Double) {
        self.mode = mode
        self.blendingRate = blendingRate
    }
}

/// Thermal palette
public struct ThermalPalette: Equatable {
    /// Palette colors.
    public var colors: [ThermalColor]

    /// Palette type
    public var type: ThermalPaletteType

    /// Constructor.
    ///
    /// - Parameters:
    ///    - colors: palette colors
    ///    - type: palette type
    public init(colors: [ThermalColor], type: ThermalPaletteType) {
        self.colors = colors
        self.type = type
    }
}

/// Enum for thermal palette.
public enum ThermalPaletteType: Equatable {
    /// Absolute palette type
    ///
    /// - Parameters:
    ///    - lowestTemp: temperature associated to the lower boundary of the palette, in Kelvin
    ///    - highestTemp: temperature associated to the higher boundary of the palette, in Kelvin
    ///    - outsideColorization: colorization mode outside palette bounds
    case absolute(lowestTemperature: Double, highestTemperature: Double, outsideColorization: ThermalColorizationMode)
    /// Relative palette type
    ///
    /// - Parameters:
    ///    - lowestTemp: temperature associated to the lower boundary of the palette, in Kelvin,
    ///                  used only when palette is `locked`
    ///    - highestTemp: temperature associated to the higher boundary of the palette, in Kelvin,
    ///                   used only when palette is `locked`
    ///    - locked: `true` if the palette is locked, otherwise `false`
    case relative(lowestTemperature: Double, highestTemperature: Double, locked: Bool)
    /// Spot palette type
    ///
    /// - Parameters:
    ///    - type: temperature type to highlight
    ///    - threshold: threshold palette index for highlighting, from 0 to 1
    case spot(type: ThermalSpotType, threshold: Double)
}

/// Setting to change the sensitivity range.
public protocol ThermalSensitivityRangeSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported ranges.
    var supportedSensitivityRanges: Set<ThermalSensitivityRange> { get }

    /// Current sensitivity range.
    var sensitivityRange: ThermalSensitivityRange { get set }
}

/// Peripheral managing thermal control.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.thermalControl)
/// ```
public protocol ThermalControl: Peripheral {
    /// Thermal camera calibration
    var calibration: ThermalCalibration? { get }

    /// Thermal power saving mode
    /// Allows user to configure the startup behavior of the Thermal camera.
    var powerSavingMode: EnumSetting<ThermalPowerSavingMode> { get }

    /// Thermal control mode setting
    var modeSetting: ThermalControlSetting { get }

    /// Sensitivity range setting
    var sensitivitySetting: ThermalSensitivityRangeSetting { get }

    /// Thermal emissivity setting
    var emissivitySetting: DoubleSetting { get }

    /// Thermal background temperature setting
    var backgroundTemperatureSetting: DoubleSetting { get }

    /// Thermal palette setting
    var paletteSetting: ThermalPaletteSetting { get }

    /// Thermal rendering setting
    var renderingSetting: ThermalRenderingSetting { get }
}

/// :nodoc:
/// ThermalControl description
public class ThermalControlDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = ThermalControl
    public let uid = PeripheralUid.thermalControl.rawValue
    public let parent: ComponentDescriptor? = nil
}
