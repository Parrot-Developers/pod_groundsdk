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

    /// MAVLink command which allows to set the still capture mode.
    public final class SetStillCaptureModeCommand: MavlinkStandard.MavlinkCommand {

        /// Still capture photo mode.
        public enum PhotoMode: Int, CustomStringConvertible {
            /// Default format (Jpeg / rectilinear)
            case snapshot = 0
            /// Rectilinear projection (de-wrapped), JPEG format.
            case rectilinear = 12
            /// Full sensor resolution (not de-wrapped), JPEG
            /// format.
            case fullFrame = 13
            /// Full sensor resolution (not de-wrapped), JPEG and DNG
            /// format.
            case fullFrameDng = 14
            /// JPEG optimized for photogrammetry.
            case photogrammetry = 15

            /// Debug description.
            public var description: String {
                switch self {
                case .snapshot: return "snapshot"
                case .rectilinear:  return "rectilinear"
                case .fullFrame: return "fullFrame"
                case .fullFrameDng:  return "fullFrameDng"
                case .photogrammetry:  return "photogrammetry"
                }
            }
        }

        /// Still capture mode.
        public var mode: PhotoMode {
            PhotoMode(rawValue: Int(parameters[2]))!
        }

        /// Constructor.
        ///
        /// - Parameters:
        ///   - mode: still capture photo mode
        public init(mode: PhotoMode) {
            super.init(type: .setStillCaptureMode, param3: Double(mode.rawValue))
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
            let rawMode = parameters[2]
            guard let mode = PhotoMode(rawValue: Int(rawMode)) else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .invalidParameter("Parameter 3 (mode) was out of range.")
            }
            self.init(mode: mode)
        }
    }
}
