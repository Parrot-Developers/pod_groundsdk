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

    /// MAVLink command which allows to set the view mode.
    public final class SetViewModeCommand: MavlinkStandard.MavlinkCommand {

        /// View mode.
        public enum Mode: Int, CustomStringConvertible {
            /// Drone orientation is fixed between two waypoints. Orientation changes when the waypoint is reached.
            case absolute
            /// Drone orientation changes linearly between two waypoints.
            case `continue`
            /// Drone orientation is given by a Region Of Interest.
            case roi

            /// Debug description.
            public var description: String {
                switch self {
                case .absolute: return "absolute"
                case .continue: return "continue"
                case .roi:      return "roi"
                }
            }
        }

        /// Pitch view mode.
        public enum PitchMode: Int, CustomStringConvertible {
            /// Camera orientation is fixed between two waypoints. Orientation changes when the waypoint is reached.
            case absolute
            /// Camera orientation changes linearly between two waypoints.
            case continuous

            /// Debug description.
            public var description: String {
                switch self {
                case .absolute: return "absolute"
                case .continuous: return "continuous"
                }
            }
        }

        /// View mode.
        public var mode: Mode {
            Mode(rawValue: Int(parameters[0]))!
        }

        /// Index of the Region Of Interest.
        ///
        /// Value is meaningless if `mode` is not `.roi`.
        public var roiIndex: Int {
            Int(parameters[1])
        }

        /// Pich view mode
        public var pitchMode: PitchMode {
            PitchMode(rawValue: Int(parameters[2]))!
        }

        /// Constructor.
        ///
        /// - Parameters:
        ///   - mode: view mode
        ///   - roiIndex: index of the Region Of Interest if mode is `.roi` (if index is invalid,
        ///               `.absolute` mode is used instead); value is ignored for any other mode
        ///   - frame: the reference frame of the coordinates.
        public init(mode: Mode, roiIndex: Int = 0, pitchMode: PitchMode = .absolute, frame: Frame = .command) {
            super.init(type: .setViewMode, frame: frame, param1: Double(mode.rawValue),
                       param2: Double(roiIndex), param3: Double(pitchMode.rawValue))
        }

        /// Constructor from generic MAVLink parameters.
        ///
        /// - Parameters:
        ///   - frame: the reference frame of the coordinates
        ///   - parameters: generic command parameters
        convenience init(frame: Frame = .command, parameters: [Double]) throws {
            assert(parameters.count == 7)
            guard parameters.count == 7 else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .incorrectNumberOfParameters("Expected 7 parameters but instead got \(parameters.count).")
            }
            let rawMode = parameters[0]
            guard let mode = Mode(rawValue: Int(rawMode)) else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .invalidParameter("Parameter 1 (mode) was out of range.")
            }
            let rawPitchMode = parameters[2]
            guard let pitchMode = PitchMode(rawValue: Int(rawPitchMode.isNaN ? 0 : rawPitchMode)) else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .invalidParameter("Parameter 3 (pitch mode) was out of range.")
            }
            let roiIndex = parameters[1]
            self.init(mode: mode, roiIndex: Int(roiIndex), pitchMode: pitchMode, frame: frame)
        }
    }
}
