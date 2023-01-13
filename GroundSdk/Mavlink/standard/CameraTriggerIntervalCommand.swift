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

    /// MAVLink command which sets camera trigger interval.
    ///
    /// If triggering is enabled, the camera is triggered each time this
    /// interval expires. This command can also be used to set the shutter
    /// integration time for the camera.
    ///
    /// You can stop the capturing media by issuing a `MavlinkStandard.MavlinkCommand`.
    public final class CameraTriggerIntervalCommand: MavlinkCommand {

        /// Camera trigger cycle time in milliseconds. Use -1 or 0 to ignore.
        ///
        /// The minimum value is -1 and the increment is 1.
        public var triggerCycle: Int {
            Int(parameters[0])
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

        /// Constructor.
        ///
        /// - Parameters:
        ///   - triggerCycle: camera trigger cycle time in milliseconds. Use -1 or 0 to ignore.
        ///   - shutterIntegration: camera shutter integration time in milliseconds. Use -1 or 0 to
        ///     ignore. Should be less than trigger cycle time. Always ignored by Anafi.
        ///   - frame: the reference frame of the coordinates
        public init(triggerCycle: Int, shutterIntegration: Int = -1, frame: Frame = .command) {
            assert(shutterIntegration < triggerCycle)
            super.init(type: .cameraTriggerInterval,
                       frame: frame,
                       param1: Double(triggerCycle),
                       param2: Double(shutterIntegration))
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
            let triggerCycle = parameters[0]
            let shutterIntegration = parameters[1]
            self.init(triggerCycle: Int(triggerCycle),
                      shutterIntegration: Int(shutterIntegration),
                      frame: frame)
        }
    }
}
