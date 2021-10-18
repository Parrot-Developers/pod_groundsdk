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

    /// Any MAVLink command.
    public final class OtherMavlinkCommand: MavlinkCommand {

        /// The integer that describes the type of the MAVLink command.
        public var commandType: Int {
            self.rawType
        }

        /// Returns the parameter at the given index.
        ///
        /// - Parameters:
        ///   - index: The index of the parameter. It must be in the range [0,6]. Accessing outside
        ///     of this range will lead to a crash.
        public func parameter(at index: Int) -> Double {
            precondition(0 <= index && index <= 6, "Index out of bounds")
            return self.parameters[index]
        }

        /// Constructor from generic MAVLink parameters.
        ///
        /// - Parameters:
        ///   - rawType: the integer that describes the type of the MAVLink command.
        ///   - param1: the first parameter of the command.
        ///   - param2: the second parameter of the command.
        ///   - param3: the third parameter of the command.
        ///   - param4: the fourth parameter of the command.
        ///   - param5: the fifth parameter of the command.
        ///   - param6: the sixth parameter of the command.
        ///   - param7: the seventh parameter of the command.
        public init(rawType: Int, param1: Double = .nan, param2: Double = .nan,
                    param3: Double = .nan, param4: Double = .nan, param5: Double = .nan,
                    param6: Double = .nan, param7: Double = .nan) {
            super.init(type: .other,
                       rawType: rawType,
                       parameters: [param1, param2, param3, param4, param5, param6, param7])
        }

        /// Constructor from generic MAVLink parameters.
        ///
        /// - Parameters:
        ///   - rawType: the integer that describes the type of the MAVLink command.
        ///   - parameters: the parameters of the command.
        public init(rawType: Int, parameters: [Double]) throws {
            assert(parameters.count == 7)
            guard parameters.count == 7 else {
                throw MavlinkStandard.MavlinkCommand.ParseError
                .incorrectNumberOfParameters("Expected 7 parameters but instead got \(parameters.count).")
            }
            super.init(type: .other,
                       rawType: rawType,
                       parameters: parameters)
        }
    }
}
