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

    /// MAVLink command which sets camera trigger distance.
    ///
    /// Mission command to set camera trigger distance for this flight. The camera is triggered each
    /// time this distance is exceeded. This command can also be used to set the shutter integration
    /// time for the camera.
    ///
    /// You can stop the capturing media by issuing a `MavlinkStandard.MavlinkCommand`.
    public final class CameraTriggerDistanceCommand: MavlinkCommand {

        /// Camera trigger distance (meters). Use 0 to ignore.
        ///
        /// The minimum value is 0.
        public var distance: Double {
            parameters[0]
        }

        /// Camera shutter integration time in milliseconds. Should be less than trigger cycle time.
        /// Use -1 or 0 to ignore.
        ///
        /// The minimum value is -1 and the increment is 1.
        ///
        /// - note: Ignored by Anafi.
        public var shutterIntegration: Int {
            Int(parameters[1])
        }

        /// Trigger camera once immediately.
        public var triggerOnceImmediately: Bool {
            parameters[2] != 0.0
        }

        /// Constructor.
        ///
        /// - Parameters:
        ///   - distance: Camera trigger distance in meters. Use 0 to stop triggering. The minimum
        ///     value is 0.
        ///   - shutterIntegration Camera shutter integration time in milliseconds. Should be less
        ///     than trigger cycle time. Use -1 or 0 to ignore. The minimum value is -1 and the
        ///     increment is 1. Ignored by Anafi.
        ///   - triggerOnceImmediately: Trigger camera once immediately. Ignored by Anafi.
        public init(distance: Double, shutterIntegration: Int = -1, triggerOnceImmediately: Bool) {
            super.init(type: .cameraTriggerDistance,
                       param1: distance,
                       param2: Double(shutterIntegration),
                       param3: triggerOnceImmediately ? 1.0 : 0.0)
        }

        /// Constructor from generic MAVLink parameters.
        ///
        /// - Parameter parameters: the raw parameters of the command.
        convenience init(parameters: [Double]) throws {
            assert(parameters.count == 7)
            guard parameters.count == 7 else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .incorrectNumberOfParameters("Expected 7 parameters but instead got \(parameters.count).")
            }
            let distance = parameters[0]
            let shutterIntegration = parameters[1]
            let triggerOnceImmediately = parameters[2]
            self.init(distance: distance,
                      shutterIntegration: Int(shutterIntegration),
                      triggerOnceImmediately: triggerOnceImmediately != 0.0)
        }
    }
}
