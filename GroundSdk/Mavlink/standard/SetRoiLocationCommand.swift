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

    /// MAVLink command which allows to set a Region Of Interest location.
    ///
    /// Sets the region of interest (ROI) to a location.
    public final class SetRoiLocationCommand: MavlinkStandard.MavlinkCommand {

        /// Latitude of ROI location.
        public var latitude: Double {
            parameters[4]
        }

        /// Longitude of ROI location.
        public var longitude: Double {
            parameters[5]
        }

        /// Altitude of ROI location.
        public var altitude: Double {
            parameters[6]
        }

        /// Constructor.
        ///
        /// - Parameters:
        ///   - latitude: Latitude of ROI location.
        ///   - longitude: Longitude of ROI location.
        ///   - altitude: Altitude of ROI location.
        public init(latitude: Double, longitude: Double, altitude: Double) {
            super.init(type: .setRoiLocation,
                       latitude: latitude,
                       longitude: longitude,
                       altitude: altitude)
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
            self.init(latitude: latitude, longitude: longitude, altitude: altitude)
        }
    }
}
