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

    /// Utility class that provides methods to generate a MAVLink file from a list of `MavlinkCommand`,
    /// and conversely, parse a MAVLink file.
    ///
    /// A MAVLink file contains a list of commands in a plain-text format, which forms a mission
    /// script. Note that supported MAVLink commands differ from official
    /// [MAVLink common message set](https://mavlink.io/en/messages/common.html). For further
    /// information about supported MAVLink commands, please refer to
    /// [Parrot FlightPlan MAVLink documentation](https://developer.parrot.com/docs/mavlink-flightplan).
    public class MavlinkFiles {

        /// Generates a MAVLink file from the given list of commands.
        ///
        /// - Parameters:
        ///   - filepath: local path of the file to write
        ///   - commands: list of MAVLink commands
        ///   - version: the MAVLink version header
        /// - Throws:
        ///   - `MavlinkStandard.MavlinkCommand.ParseError.invalidVersion` if version is not in an
        ///      expected format like ^\w+ \w+ \d+$
        ///   - If a write error occured.
        public static func generate(filepath: String,
                                    commands: [MavlinkCommand],
                                    version: String = "QGC WPL 120") throws {
            guard !commands.isEmpty else {
                return
            }
            // Writing header creates the file and clears content if needed
            guard version.range(of: "^QGC WPL \\d+$", options: .regularExpression) != nil else {
                throw MavlinkStandard.MavlinkCommand.ParseError.invalidVersion
            }
            try (version + "\n").write(toFile: filepath, atomically: false, encoding: .utf8)

            if let fileHandle = FileHandle(forWritingAtPath: filepath) {
                fileHandle.seekToEndOfFile()
                for (index, command) in commands.enumerated() {
                    command.write(fileHandle: fileHandle, index: index)
                }
                fileHandle.closeFile()
            }
        }

        /// Parses a MAVLink file into a list of commands.
        ///
        /// Any malformed command is simply ignored and removed from the resulting array. If the
        /// given file is not properly formatted, this method returns an empty list.
        ///
        /// - Parameter filepath: local path of the file to read
        /// - Returns: the command list extracted from the file
        public static func parse(filepath: String) throws -> [MavlinkCommand] {
           let mavlinkString = try String(contentsOfFile: filepath, encoding: .utf8)
            return try self.parse(mavlinkString: mavlinkString)
        }

        /// Parses a MAVLink string into a list of commands.
        ///
        /// Any malformed command is simply ignored. If the given string is not
        /// properly formatted, this method returns an empty list.
        ///
        /// - Parameter mavlinkString: MAVLing string to convert
        /// - Returns: the command list extracted from the string
        public static func parse(mavlinkString: String) throws -> [MavlinkCommand] {
            guard !mavlinkString.isEmpty else {
                ULog.e(.mavlinkStandardTag, "Invalid input. The provided MAVLink string is empty.")
                throw MavlinkStandard.MavlinkCommand.ParseError.generic
            }
            let content = mavlinkString.components(separatedBy: .newlines)
            guard !content.isEmpty else {
                ULog.e(.mavlinkStandardTag,
                       "Invalid input. The provided MAVLink string does not contain any lines.")
                throw MavlinkStandard.MavlinkCommand.ParseError.generic
            }
            guard content[0].range(of: "QGC WPL \\d+", options: .regularExpression) != nil else {
                ULog.e(.mavlinkStandardTag,
                       "Unexpected MAVLink version.")
                throw MavlinkStandard.MavlinkCommand.ParseError.invalidVersion
            }
            return content[1...].compactMap({ line in
                let command = try? MavlinkCommand.parse(line: line)
                if command == nil {
                    ULog.d(.mavlinkStandardTag, "Ignoring '\(line)'.")
                }
                return command
            })
        }
    }
}
