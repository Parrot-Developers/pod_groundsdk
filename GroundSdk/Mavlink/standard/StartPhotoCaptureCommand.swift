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

    /// MAVLink command which allows to start photo capture.
    ///
    /// Image format is not specified by this command. Use `SetStillCaptureModeCommand` for setting
    /// the photo format.
    public final class StartPhotoCaptureCommand: MavlinkStandard.MavlinkCommand {

        /// Elapsed time between two consecutive pictures, in seconds.
        public var interval: Double {
            parameters[1]
        }

        /// Total number of photos to capture.
        public var count: Int {
            Int(parameters[2])
        }

        /// Photo capture format.
        public var sequenceNumber: Int {
            Int(parameters[3])
        }

        /// Constructor.
        ///
        /// - Parameters:
        ///   - interval: desired elapsed time between two consecutive pictures, in seconds.
        ///   - count: total number of photos to capture; 0 to capture until
        ///            `StopPhotoCaptureCommand` is sent.
        ///   - sequenceNumber: Capture sequence number starting from 1. This is
        ///                     only valid for single-capture (count == 1), otherwise set to 0.
        ///                     Increment the capture ID for each capture command to prevent double
        ///                     captures when a command is re-transmitted.
        /// - note: Implicitly starts a timelapse if an interval is specified with a count greater than 0.
        public init(interval: Double, count: Int, sequenceNumber: Int) {
            if count == 1 {
                assert(sequenceNumber >= 1)
            } else {
                assert(sequenceNumber == 0)
            }
            super.init(type: .startPhotoCapture, param2: interval, param3: Double(count),
                       param4: Double(sequenceNumber))
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
            let interval = parameters[1]
            let count = parameters[2]
            let sequenceNumber = parameters[3]
            self.init(interval: interval, count: Int(count), sequenceNumber: Int(sequenceNumber))
        }
    }
}
