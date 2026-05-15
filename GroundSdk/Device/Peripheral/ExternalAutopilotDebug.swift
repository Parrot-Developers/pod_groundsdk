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

/// External autopilot debug message level
public enum ExternalAutopilotDebugMessageLevel {

    /// Debug message is info.
    case info

    /// Debug message is warning.
    case warning

    /// Debug message is error.
    case error
}

/// External autopilot debug message source
public enum ExternalAutopilotDebugMessageSource {

    /// Debug message is coming from configuration.
    case configuration

    /// Debug message is coming from autopilot.
    case autopilot
}

/// External Flight mode.
public enum ExternalFlightMode: Int, CaseIterable, Equatable {
    /// In an unknown mode.
    case unknown

    /// Self-leveling.
    case stabilize

    /// In auto-takeoff mode.
    case takeOff

    /// Flying towards a target waypoint (may be taking off).
    case guided

    /// Loitering.
    case loiter

    /// Manual piloting as a copter, receives raw piloting.
    case manualCopter

    /// Manual piloting as a plane, receives raw piloting commands.
    case manualPlane

    /// Executing a mission.
    case mission

    /// Returning to its home location.
    case rth

    /// Landing.
    case landing

    /// Debug description.
    public var description: String {
        switch self {
        case .unknown:      return "unknown"
        case .stabilize:    return "stabilize"
        case .takeOff:      return "takeOff"
        case .guided:       return "guided"
        case .loiter:       return "loiter"
        case .manualCopter: return "manualCopter"
        case .manualPlane:  return "manualPlane"
        case .mission:      return "mission"
        case .rth:          return "rth"
        case .landing:      return "landing"
        }
    }
}

/// External autopilot debug message
public struct ExternalAutopilotDebugMessage: Hashable {

    /// Debug message level.
    public var level: ExternalAutopilotDebugMessageLevel

    /// Debug message source.
    public var source: ExternalAutopilotDebugMessageSource

    /// Debug message content.
    public var message: String

    /// Constructor
    ///
    /// - Parameters:
    ///   - level: external autopilot debug message type
    ///   - source: external autopilot debug message source
    ///   - message: debug message content
    public init(level: ExternalAutopilotDebugMessageLevel, source: ExternalAutopilotDebugMessageSource,
                message: String) {
        self.level = level
        self.source = source
        self.message = message
    }
}

/// External autopilot debug peripheral interface.
///
/// This peripheral allows to get the drone external autopilot debug messages.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.externalAutopilotDebug)
/// ```
public protocol ExternalAutopilotDebug: Peripheral {

    /// List of external autopilot debug message
    var debugMessages: [ExternalAutopilotDebugMessage] { get }

    /// Current flying mode defined in external autopilot.
    var flightMode: ExternalFlightMode? { get }
}

/// :nodoc:
/// External autopilot debug description
public class ExternalAutopilotDebugDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = ExternalAutopilotDebug
    public let uid = PeripheralUid.externalAutopilotDebug.rawValue
    public let parent: ComponentDescriptor? = nil
}
