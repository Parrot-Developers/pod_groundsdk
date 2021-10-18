// Copyright (C) 2021 Parrot Drones SAS
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

// swiftlint:disable nesting

import Foundation

extension MavlinkStandard {

    /// MAVLink command which allows to control the camera tilt and yaw.
    public final class MountControlCommand: MavlinkStandard.MavlinkCommand {

        /// Mount control mode.
        public enum Mode: Int, CustomStringConvertible {
            /// Load and keep safe position (Roll,Pitch,Yaw) from permant memory and stop stabilization.
            case retract = 0

            /// Load and keep neutral position (Roll,Pitch,Yaw) from permanent memory.
            case neutral = 1

            /// Load neutral position and start MAVLink Roll,Pitch,Yaw control with stabilization.
            case targeting = 2

            /// Load neutral position and start RC Roll,Pitch,Yaw control with stabilization.
            case rcTargeting = 3

            /// Load neutral position and start to point to Lat,Lon,Alt.
            case gpsPoint = 4

            /// Gimbal tracks system with specified system ID.
            case sysidTarget = 5

            /// Gimbal tracks home location.
            case homeLocation = 6

            /// Debug description.
            public var description: String {
                switch self {
                case .retract: return "retract"
                case .neutral:  return "neutral"
                case .targeting: return "targeting"
                case .rcTargeting:  return "rcTargeting"
                case .gpsPoint:  return "gpsPoint"
                case .sysidTarget:  return "sysidTarget"
                case .homeLocation:  return "homeLocation"
                }
            }
        }

        /// Camera tilt angle, in degrees.
        public var tiltAngle: Double {
            parameters[0]
        }

        /// Yaw angle value, in degrees.
        public var yaw: Double {
            parameters[2]
        }

        /// Mount mode.
        public var mode: Mode {
            Mode(rawValue: Int(parameters[6]))!
        }

        /// Constructor.
        ///
        /// Only tilt and yaw are supported by Anafi.
        ///
        /// - Parameters:
        ///   - tiltAngle: the tilt angle value, in degrees.
        ///   - yaw: the yaw angle value, in degrees. Yaw is interpreted as relative to the drone's
        ///          orientation.
        ///   - mode: the mount mode. Only `.targeting` and `.neutral` are supported. When
        ///           `.neutral` is used then *all* other parameters are *ignored* and the gimbal
        ///           resets to its default position.
        public init(tiltAngle: Double, yaw: Double, mode: Mode = .targeting) {
            assert(mode == .neutral || mode == .targeting)
            super.init(type: .mountControl,
                       param1: tiltAngle,
                       param3: yaw,
                       altitude: Double(mode.rawValue))
        }

        /// Constructor from generic MAVLink parameters.
        ///
        /// - Parameter parameters: generic command parameters
        convenience init(parameters: [Double]) throws {
            assert(parameters.count == 7)
            guard parameters.count == 7 else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .incorrectNumberOfParameters("Expected 7 parameters but instead got \(parameters.count).")
            }
            let tiltAngle = parameters[0]
            let yaw = parameters[2]
            let modeRaw = parameters[6]
            guard let mode = Mode(rawValue: Int(modeRaw)) else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .invalidParameter("Parameter 7 (mode) was out of range.")
            }
            self.init(tiltAngle: tiltAngle, yaw: yaw, mode: mode)
        }
    }
}
