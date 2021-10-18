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

    /// MAVLink command which allows to change the drone speed.
    public final class ChangeSpeedCommand: MavlinkStandard.MavlinkCommand {

        /// Constants namespace related to `ChangeSpeedCommand`.
        enum Constants {
            /// Value indicating to keep the throttle unchanged.
            static let doNotChangeThrottle: Double = -1.0
            /// Value indicating to keep the speed unchanged.
            static let doNotChangeSpeed: Double = -1.0
        }

        /// Speed type.
        public enum SpeedType: Int, CustomStringConvertible {
            /// Air speed.
            case airSpeed = 0
            /// Ground speed.
            case groundSpeed = 1

            /// Debug description.
            public var description: String {
                switch self {
                case .airSpeed:    return "airSpeed"
                case .groundSpeed: return "groundSpeed"
                }
            }
        }

        /// Speed type.
        public var speedType: SpeedType {
            SpeedType(rawValue: Int(parameters[0]))!
        }

        /// Speed, in meters/second.
        public var speed: Double {
            parameters[1]
        }

        /// Relative speed change or absolute.
        ///
        /// A `false` value means the speed change is absolute where a `true` value means the speed
        /// change is a relative change from the current speed.
        public var relative: Bool {
            parameters[3] != 0
        }

        /// Constructor.
        ///
        /// - Parameters:
        ///   - speedType: speed type
        ///   - speed: speed, in meters/second
        ///   - relative: boolean indicate wether the speed change is absolute or relative
        public init(speedType: SpeedType,
                    speed: Double,
                    relative: Bool = false) {
            super.init(type: .changeSpeed,
                       param1: Double(speedType.rawValue),
                       param2: speed,
                       param3: Constants.doNotChangeThrottle,
                       param4: relative ? 1 : 0)
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
            let type = parameters[0]
            guard let speedType = SpeedType(rawValue: Int(type)) else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .invalidParameter("Parameter 1 (type) was out of range.")
            }
            let speed = parameters[1]
            let relative = parameters[3]
            self.init(speedType: speedType,
                      speed: speed,
                      relative: relative != 0)
        }
    }
}
