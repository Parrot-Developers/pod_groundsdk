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

    /// MAVLink command which allows to land.
    public final class LandCommand: MavlinkStandard.MavlinkCommand {

        /// Latitude of the implicitly added waypoint, in degrees.
        public var latitude: Double {
            parameters[4]
        }

        /// Longitude of the implicitly added waypoint, in degrees.
        public var longitude: Double {
            parameters[5]
        }

        /// Altitude of the implicitly added waypoint above take off point, in meters.
        public var altitude: Double {
            parameters[6]
        }

        /// Desired yaw angle at waypoint, relative to the North in degrees (clockwise). Use NaN to
        /// use the current system yaw heading mode (e.g. yaw towards next waypoint, yaw to home,
        /// etc.).
        public var yaw: Double {
            parameters[3]
        }

        /// Constuctor.
        ///
        /// If a 0/0/0 (latituted/longitude/altitude) value is passed in no implicit waypoint is
        /// added.
        ///
        /// - Parameters:
        ///   - yaw: desired yaw angle at waypoint, relative to the North in degrees (clockwise). A
        ///     NaN value uses the current system yaw heading mode (e.g. yaw towards next waypoint,
        ///     yaw to home, etc.).
        ///   - latitude: latitude of the implicitly added waypoint, in degrees.
        ///   - longitude: longitude of the implicitly added waypoint, in degrees.
        ///   - altitude: altitude of the implicitly added waypoint above take off point, in meters.
        public init(yaw: Double = .nan,
                    latitude: Double = 0.0,
                    longitude: Double = 0.0,
                    altitude: Double = 0.0) {
            super.init(type: .land,
                       param4: yaw,
                       latitude: latitude,
                       longitude: longitude,
                       altitude: altitude)
        }

        /// Constructor from generic MAVLink parameters.
        ///
        /// - Parameters:
        ///   - parameters: generic command parameters.
        convenience init(parameters: [Double]) throws {
            assert(parameters.count == 7)
            guard parameters.count == 7 else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .incorrectNumberOfParameters("Expected 7 parameters but instead got \(parameters.count).")
            }
            let yaw = parameters[3]
            let latitude = parameters[4]
            let longitude = parameters[5]
            let altitude = parameters[6]
            self.init(yaw: yaw,
                      latitude: latitude,
                      longitude: longitude,
                      altitude: altitude)
        }
    }
}
