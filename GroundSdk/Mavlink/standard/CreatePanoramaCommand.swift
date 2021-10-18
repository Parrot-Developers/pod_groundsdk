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

    /// MAVLink command which allows to create a panorama.
    public final class CreatePanoramaCommand: MavlinkStandard.MavlinkCommand {

        /// Horizontal rotation angle, in degrees.
        public var horizontalAngle: Double {
            parameters[0]
        }

        /// Horizontal rotation speed, in degrees/second.
        public var horizontalSpeed: Double {
            parameters[2]
        }

        /// Vertical rotation angle, in degrees.
        public var verticalAngle: Double {
            parameters[1]
        }

        /// Vertical rotation speed, in degrees/second.
        public var verticalSpeed: Double {
            parameters[3]
        }

        /// Constructor.
        ///
        /// - Parameters:
        ///   - horizontalAngle: horizontal rotation angle, in degrees
        ///   - horizontalSpeed: horizontal rotation speed, in degrees/second
        ///   - verticalAngle: vertical rotation angle, in degrees
        ///   - verticalSpeed: vertical rotation speed, in degrees/second
        public init(horizontalAngle: Double, horizontalSpeed: Double, verticalAngle: Double, verticalSpeed: Double) {
            super.init(type: .createPanorama,
                       param1: horizontalAngle, param2: verticalAngle, param3: horizontalSpeed, param4: verticalSpeed)
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
            let horizontalAngle = parameters[0]
            let verticalAngle = parameters[1]
            let horizontalSpeed = parameters[2]
            let verticalSpeed = parameters[3]
            self.init(horizontalAngle: horizontalAngle, horizontalSpeed: horizontalSpeed, verticalAngle: verticalAngle,
                      verticalSpeed: verticalSpeed)
        }
    }
}
