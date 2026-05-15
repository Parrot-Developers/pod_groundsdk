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

/// Color for thermal palette.
public struct ThermalColor: Equatable {

    /// Red component, in range [0, 1].
    public let red: Double

    /// Green component, in range [0, 1].
    public let green: Double

    /// Blue component, in range [0, 1].
    public let blue: Double

    /// Index in the palette where given color should be applied, in range [0, 1].
    public let position: Double

    /// Constructor.
    ///
    /// - Parameters:
    ///    - red: red component, in range [0, 1]
    ///    - green: green component, in range [0, 1]
    ///    - blue: blue component, in range [0, 1]
    ///    - position: index in the palette, in range [0, 1]
    public init(_ red: Double, _ green: Double, _ blue: Double, _ position: Double) {
        self.red = unsignedPercentIntervalDouble.clamp(red)
        self.green = unsignedPercentIntervalDouble.clamp(green)
        self.blue = unsignedPercentIntervalDouble.clamp(blue)
        self.position = unsignedPercentIntervalDouble.clamp(position)
    }

    /// Comparable concordance
    public static func == (lhs: ThermalColor, rhs: ThermalColor) -> Bool {
        return Float(lhs.red) == Float(rhs.red) && Float(lhs.green) == Float(rhs.green)
            && Float(lhs.blue) == Float(rhs.blue) && Float(lhs.position) == Float(rhs.position)
    }
}

/// Thermal camera calibration modes.
public enum ThermalCalibrationMode: Int, CustomStringConvertible, CaseIterable {
    /// Calibration triggered automatically.
    case automatic
    /// Calibration triggered manually.
    case manual

    /// Debug description.
    public var description: String {
        switch self {
        case .automatic: return "automatic"
        case .manual: return "manual"
        }
    }
}

/// Thermal camera calibration state
public enum CalibrationState: Int, CaseIterable {
    /// Thermal camera does nnot report its calibration state.
    case unknown

    /// Thermal camera requires calibration.
    case notCalibrated

    /// Calibration process starting.
    case calibrationStarting

    /// Waiting the user to put the gimbal cover.
    case waitGimbalCoverOn

    /// Camera is heating up.
    case heating

    /// Calibration is in progress.
    case calibrating

    /// Waiting for the user to remove the gimbal cover.
    case waintGimbalCoverOff

    /// Thermal camera is calibrated.
    case calibrated

    /// Debug description.
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .notCalibrated: return "notCalibrated"
        case .calibrationStarting: return "calibrationStarting"
        case .waitGimbalCoverOn: return "waitGimbalCoverOn"
        case .heating: return "heating"
        case .calibrating: return "calibrating"
        case .waintGimbalCoverOff: return "waintGimbalCoverOff"
        case .calibrated: return "calibrated"
        }
    }
}

/// Thermal power saving mode.
public enum ThermalPowerSavingMode: Int, CustomStringConvertible, CaseIterable {
    /// The thermal camera is always powered on even if not used.
    /// Allows fast thermal mode startup.
    case alwaysOn
    /// The thermal camera is shut down after a period of time when not used.
    /// Allows fast thermal mode startup if user performs thermal mode
    /// back and forth.
    case hold
    /// The thermal camera is shut down immediately after end of thermal mode.
    /// This allows the maximum energy saving but increases the thermal mode
    /// startup.
    case max

    /// Debug description.
    public var description: String {
        switch self {
        case .alwaysOn: return "alwaysOn"
        case .hold: return "hold"
        case .max: return "max"
        }
    }
}

/// Thermal camera calibration.
public protocol ThermalCalibration: AnyObject {
    /// Tells if the calibration mode value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported calibration modes.
    var supportedModes: Set<ThermalCalibrationMode> { get }

    /// Current calibration mode.
    var mode: ThermalCalibrationMode { get set }

    /// Checks whether a user-action is required for the current state.
    var userActionRequired: Bool { get }

    /// Thermal camera calibration state
    var calibrationState: CalibrationState { get }

    /// Triggers a calibration.
    ///
    /// - Returns: `true` if the calibration request has been sent to the drone, `false` otherwise
    func calibrate() -> Bool

    /// Abort thermal camera calibration.
    ///
    /// - Returns: `true` if the calibration abort was sent to the drone, `false` otherwise
    func abortCalibration() -> Bool

    /// Confirms that the user did the required action.
    ///
    /// - Returns: `true` if the confirmation was sent to the drone, `false` otherwise
    func confirmUserAction() -> Bool
}
