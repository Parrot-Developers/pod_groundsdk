// Copyright (C) 2026 Parrot Drones SAS
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

/// Rendering mixing mode
public enum ThermalMixingMode: Int, CustomStringConvertible, CaseIterable {
    /// Full thermal mixing mode
    case fullThermal
    /// Blended mixing mode
    case blended

    /// Debug description.
    public var description: String {
        switch self {
        case .fullThermal: return "fullThermal"
        case .blended: return "blended"
        }
    }
}

/// Thermal palette 2
public struct ThermalPalette2: Equatable {
    /// Palette colors.
    public var colors: [ThermalColor]

    /// Constructor.
    ///
    /// - Parameters:
    ///    - colors: palette colors
    public init(colors: [ThermalColor]) {
        self.colors = colors
    }
}

/// Protocol for thermal palette 2 setting
public protocol ThermalPalette2Setting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Current thermal palette.
    var palette: ThermalPalette2 { get set }
}

/// Peripheral managing thermal control 2.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.thermalControl2)
/// ```
public protocol ThermalControl2: Peripheral {
    /// Thermal camera calibration
    var calibration: ThermalCalibration? { get }

    /// Thermal power saving mode
    /// Allows user to configure the startup behavior of the Thermal camera.
    var powerSavingMode: EnumSetting<ThermalPowerSavingMode> { get }

    /// Thermal palette colors setting
    var paletteSetting: ThermalPalette2Setting { get }

    /// Mixing mode setting.
    var mixingMode: EnumSetting<ThermalMixingMode> { get }

    /// Coefficient of visible edges setting. Normalized between 0 and 1.
    var edgeCoefficient: DoubleSetting { get }

    /// Thermal minimum colorization threshold setting. Normalized between 0 and 1.
    var minColorizationThreshold: DoubleSetting { get }

    /// Thermal maximum colorization threshold setting. Normalized between 0 and 1.
    var maxColorizationThreshold: DoubleSetting { get }

    /// Whether thermal dynamic is locked in its current state.
    var rangeLocked: BoolSetting { get }
}

/// :nodoc:
/// ThermalControl2 description
public class ThermalControl2Desc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = ThermalControl2
    public let uid = PeripheralUid.thermalControl2.rawValue
    public let parent: ComponentDescriptor? = nil
}
