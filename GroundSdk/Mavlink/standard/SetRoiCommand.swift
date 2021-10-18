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

    /// MAVLink command which allows to set a Region Of Interest.
    public final class SetRoiCommand: MavlinkStandard.MavlinkCommand {

        /// ROI mode.
        public enum Mode: Int, CustomStringConvertible {
            /// No region of interest.
            case none = 0
            /// Point toward next waypoint, with optional pitch/roll/yaw offset.
            case waypointNext = 1
            /// Point toward given waypoint.
            case waypointIndex = 2
            /// Point toward fixed location.
            case location = 3
            /// Point toward of given id.
            case target = 4

            /// Debug description
            public var description: String {
                switch self {
                case .none: return "none"
                case .waypointNext:  return "waypointNext"
                case .waypointIndex: return "waypointIndex"
                case .location:  return "location"
                case .target:  return "target"
                }
            }
        }

        /// ROI mode.
        public var mode: Mode {
            Mode(rawValue: Int(parameters[0]))!
        }

        /// Waypoint index or target ID.
        public var waypointIndex: Int {
            Int(parameters[1])
        }

        /// ROI index.
        public var roiIndex: Int {
            Int(parameters[2])
        }

        /// When mode is `.waypointNext` then it is the pitch offset from next waypoint, when
        /// `.location` then it is the latitude.
        public var pitchOrLatitude: Double {
            parameters[4]
        }

        /// When mode is `.waypointNext` it is ignored, when `.location` then it is the longitude.
        public var rollOrLongitude: Double {
            parameters[5]
        }

        /// When mode is `.waypointNext` then it is the yaw offset from next waypoint, when
        /// `.location` then it is the altitude.
        public var yawOrAltitude: Double {
            parameters[6]
        }

        /// Constructor.
        ///
        /// - Parameters:
        ///   - mode: Region of interest mode.
        ///   - waypointIndex: Waypoint index/ target ID (depends on param 1).
        ///   - roiIndex: Region of interest index. (allows a vehicle to manage multiple ROI's).
        ///   - pitchOrLatitude: when mode is `.waypointNext` functions as the pitch offset from next
        ///     waypoint, when `.location` functions as latitude.
        ///   - rollOrLongitude: when mode is `.waypointNext` it is ignored, when `.location`
        ///     functions as longitude. Roll is ignored by Anafi 2.
        ///   - yawOrAltitude: when mode is `.waypointNext` functions as the yaw offset from next
        ///     waypoint, when `.location` functions as altitude.
        public init(mode: Mode,
                    waypointIndex: Int,
                    roiIndex: Int,
                    pitchOrLatitude: Double,
                    rollOrLongitude: Double,
                    yawOrAltitude: Double) {
            assert(0 <= roiIndex && roiIndex <= 255)
            assert(0 <= waypointIndex)
            super.init(type: .setRoi,
                       param1: Double(mode.rawValue),
                       param2: Double(waypointIndex),
                       param3: Double(roiIndex),
                       latitude: pitchOrLatitude,
                       longitude: rollOrLongitude,
                       altitude: yawOrAltitude)
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
            let modeRaw = parameters[0]
            guard let mode = Mode(rawValue: Int(modeRaw)) else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .invalidParameter("Parameter 1 (mode) was out of range.")
            }
            let waypointIndex = Int(parameters[1])
            guard 0 <= waypointIndex, waypointIndex <= 255 else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .invalidParameter("Parameter 2 (waypointIndex) was out of range [0,255].")
            }
            let roiIndex = Int(parameters[2])
            guard 0 <= roiIndex else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .invalidParameter("Parameter 3 (roiIndex) was out of range [0,).")
            }
            let pitchOrLatitude = parameters[4]
            let rollOrLongitude = parameters[5]
            let yawOrAltitude = parameters[6]
            self.init(mode: mode,
                      waypointIndex: waypointIndex,
                      roiIndex: roiIndex,
                      pitchOrLatitude: pitchOrLatitude,
                      rollOrLongitude: rollOrLongitude,
                      yawOrAltitude: yawOrAltitude)
        }
    }
}
