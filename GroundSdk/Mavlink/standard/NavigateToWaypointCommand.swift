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

import Foundation

extension MavlinkStandard {

    /// MAVLink command which allows to navigate to a waypoint.
    public final class NavigateToWaypointCommand: MavlinkStandard.MavlinkCommand {

        /// Latitude of the waypoint, in degrees.
        public var latitude: Double {
            parameters[4]
        }

        /// Longitude of the waypoint, in degrees.
        public var longitude: Double {
            parameters[5]
        }

        /// Altitude of the waypoint above take off point, in meters.
        public var altitude: Double {
            parameters[6]
        }

        /// Desired yaw angle at waypoint, relative to the North in degrees (clockwise).
        public var yaw: Double {
            parameters[3]
        }

        /// Hold time: time to stay at waypoint, in seconds.
        public var holdTime: Double {
            parameters[0]
        }

        /// Acceptance radius: if the sphere with this radius is hit, the waypoint counts as reached, in meters.
        public var acceptanceRadius: Double {
            parameters[1]
        }

        /// Constuctor.
        ///
        /// - Parameters:
        ///   - latitude: latitude of the waypoint, in degrees
        ///   - longitude: longitude of the waypoint, in degrees
        ///   - altitude: altitude of the waypoint above take off point, in meters
        ///   - yaw: desired yaw angle at waypoint, relative to the North in degrees (clockwise).
        ///     Use NaN to use the current system yaw heading mode (e.g. yaw towards next waypoint,
        ///     yaw to home, etc.).
        ///   - holdTime: time to stay at waypoint, in seconds
        ///   - acceptanceRadius: acceptance radius, in meters
        public init(latitude: Double, longitude: Double, altitude: Double, yaw: Double, holdTime: Double = 0,
                    acceptanceRadius: Double = 5) {
            super.init(type: .navigateToWaypoint, param1: holdTime, param2: acceptanceRadius,
                       param4: yaw, latitude: latitude, longitude: longitude, altitude: altitude)
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
            let latitude = parameters[4]
            let longitude = parameters[5]
            let altitude = parameters[6]
            let yaw = parameters[3]
            let holdTime = parameters[0]
            let acceptanceRadius = parameters[1]
            self.init(latitude: latitude, longitude: longitude, altitude: altitude, yaw: yaw, holdTime: holdTime,
                      acceptanceRadius: acceptanceRadius)
        }
    }
}
