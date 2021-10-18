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

    /// A MAVLink command.
    ///
    /// Clients of this API cannot instantiate this class directly, and must use
    /// one of the subclasses defining a specific MAVLink command. If a subclass
    /// does not describe the command you want to use use `OtherMavlinkCommand`.
    public class MavlinkCommand: Equatable {

        /// Parse related errors when creating or parsing `MavlinkCommand`s.
        enum ParseError: Error, Equatable {
            /// A generic parse error indicating an unspecific parse or creation failure.
            case generic
            /// An error indicating that a provided parameter to the `MavlinkCommand` was either not
            /// provided or was invalid (out of range or unexpected value). The associated value
            /// should pinpoint to the exact problem.
            ///
            /// - Parameters:
            ///   - explanation: A human readable string that  should describe what actually was the
            ///     encountered issue.
            case invalidParameter(_ explanation: String)
            /// An error indicating that a Mavlink line, that could be used to represent a
            /// MavlinkCommand, was ill-formed.
            ///
            /// The line could have an incorrect number of tokens or the token separator used was
            /// not the tab character (\t). The associated value should pinpoint to the exact
            /// problem.
            ///
            /// - Parameters:
            ///   - explanation: A human readable string that  should describe what actually was the
            ///     encountered issue.
            case invalidLine(_ explanation: String)
            /// An error indicating that the creation of `MavlinkCommand` through
            /// `MavlinkCommand.create(rawType:parameters:)` or `OtherMavlinkCommand` did not
            /// include all required parameters.
            ///
            /// - Parameters:
            ///   - explanation: A human readable string that  should describe what actually was the
            ///     encountered issue.
            case incorrectNumberOfParameters(_ explanation: String)
            /// An error indicating the `MavlinkComamnd` version header is in an unexpected format.
            case invalidVersion

            static func == (lhs: ParseError, rhs: ParseError) -> Bool {
                switch (lhs, rhs) {
                case (.generic, .generic),
                     (.invalidParameter, invalidParameter),
                     (.invalidLine, invalidLine),
                     (.incorrectNumberOfParameters, .incorrectNumberOfParameters),
                     (.invalidVersion, .invalidVersion):
                    return true
                default:
                    return false
                }
            }
        }

        /// MAVLink command type.
        enum CommandType: Int, CustomStringConvertible {
            /// Navigate to waypoint.
            case navigateToWaypoint = 16
            /// Return to home.
            case returnToLaunch = 20
            /// Land.
            case land = 21
            /// Take off.
            case takeOff = 22
            /// Delay the next command.
            case delay = 112
            /// Change speed.
            case changeSpeed = 178
            /// Sets the region of interest (ROI) to a location.
            case setRoiLocation = 195
            /// Cancels any previous ROI command.
            case setRoiNone = 197
            /// Set Region Of Interest.
            case setRoi = 201
            /// Control the camera tilt.
            case mountControl = 205
            /// Set Camera trigger distance.
            case cameraTriggerDistance = 206
            /// Set camera trigger interval.
            case cameraTriggerInterval = 214
            /// Start photo capture.
            case startPhotoCapture = 2000
            /// Stop photo capture.
            case stopPhotoCapture = 2001
            /// Start video recording.
            case startVideoCapture = 2500
            /// Stop video recording.
            case stopVideoCapture = 2501
            /// Create a panorama.
            case createPanorama = 2800
            /// Set view mode.
            case setViewMode = 50000
            /// Set still capture mode.
            case setStillCaptureMode = 50001
            /// Other mavlink command.
            case other = -1

            /// Debug description.
            var description: String {
                switch self {
                case .navigateToWaypoint:  return "navigateToWaypoint"
                case .returnToLaunch:      return "returnToLaunch"
                case .land:                return "land"
                case .takeOff:             return "takeOff"
                case .delay:               return "delay"
                case .changeSpeed:         return "changeSpeed"
                case .setRoiLocation:      return "setRoiLocation"
                case .setRoiNone:          return "setRoiNone"
                case .setRoi:              return "setRoi"
                case .mountControl:        return "mountControl"
                case .cameraTriggerDistance: return "cameraTriggerDistance"
                case .cameraTriggerInterval: return "cameraTriggerInterval"
                case .startPhotoCapture:   return "startPhotoCapture"
                case .stopPhotoCapture:    return "stopPhotoCapture"
                case .startVideoCapture:   return "startVideoCapture"
                case .stopVideoCapture:    return "stopVideoCapture"
                case .createPanorama:      return "createPanorama"
                case .setViewMode:         return "setViewMode"
                case .setStillCaptureMode: return "setStillCaptureMode"
                case .other: return "otherCommand"
                }
            }
        }

        /// Value always used for current waypoint; set to false.
        private static let currentWaypoint = 0

        /// Value always used for coordinate frame; set to global coordinate frame, relative altitude over ground.
        private static let frame = 3

        /// Value always used for auto-continue; set to true.
        private static let autoContinue = 1

        /// The MAVLink type command type.
        internal var type: CommandType {
            return CommandType(rawValue: rawType)!
        }

        /// The MAVLink command type.
        internal let rawType: Int

        /// The raw parameters of the command.
        internal let parameters: [Double]

        /// Constructor.
        ///
        /// - Parameters
        ///   - type: the MAVLink command type. If the type is `.other` then
        ///     `rawType` must be greater than 0.
        ///   - rawType: the MAVLink raw type. If greater than zero then `type`
        ///     must be `.other`.
        ///   - parameters: the raw parameters of the command.
        internal init(type: CommandType,
                      rawType: Int = -1,
                      parameters: [Double] = [.nan, .nan, .nan, .nan, .nan, .nan, .nan]) {
            assert((type == .other && rawType > 0)
                    || (type != .other && rawType == -1))
            assert(parameters.count == 7)
            self.rawType = type == .other ? rawType : type.rawValue
            self.parameters = parameters
        }

        /// Constructor.
        ///
        /// - Parameters:
        ///   - type: the MAVLink command type. If the type is `.other` then
        ///           `rawType` must be greater than 0.
        ///   - rawType: the MAVLink raw type. If greater than zero then `type`
        ///   - param1: the first parameter of the command.
        ///   - param2: the second parameter of the command.
        ///   - param3: the third parameter of the command.
        ///   - param4: the fourth parameter of the command.
        ///   - latitude: the latitude of the command
        ///   - longitude: the longitude of the command
        ///   - altitude: the altitude of the command
        internal init(type: CommandType,
                      rawType: Int = -1,
                      param1: Double = .nan,
                      param2: Double = .nan,
                      param3: Double = .nan,
                      param4: Double = .nan,
                      latitude: Double = .nan,
                      longitude: Double = .nan,
                      altitude: Double = .nan) {
            assert((type == .other && rawType > 0)
                    || (type != .other && rawType == -1))
            self.rawType = type == .other ? rawType : type.rawValue
            self.parameters = [param1, param2, param3, param4,
                               latitude, longitude, altitude]
        }

        public static func == (lhs: MavlinkCommand, rhs: MavlinkCommand) -> Bool {
            func equal(_ a: Double, _ b: Double) -> Bool {
                if a.isNaN || b.isNaN {
                    return a.isNaN && b.isNaN
                }
                let affinity = 1e-6
                return abs(a - b) < affinity
            }
            return lhs.rawType == rhs.rawType
                && equal(lhs.parameters[0], rhs.parameters[0])
                && equal(lhs.parameters[1], rhs.parameters[1])
                && equal(lhs.parameters[2], rhs.parameters[2])
                && equal(lhs.parameters[3], rhs.parameters[3])
                && equal(lhs.parameters[4], rhs.parameters[4])
                && equal(lhs.parameters[5], rhs.parameters[5])
                && equal(lhs.parameters[6], rhs.parameters[6])
        }

        /// Writes the MAVLink command to the specified file.
        ///
        /// - Parameters:
        ///   - fileHandle: handle on the file the command is written to
        ///   - index: the index of the command
        func write(fileHandle: FileHandle, index: Int) {
            doWrite(fileHandle: fileHandle,
                    index: index,
                    rawType: rawType,
                    param1: parameters[0],
                    param2: parameters[1],
                    param3: parameters[2],
                    param4: parameters[3],
                    latitude: parameters[4],
                    longitude: parameters[5],
                    altitude: parameters[6])
        }

        /// Writes the MAVLink command to the specified file.
        ///
        /// - Parameters:
        ///   - fileHandle: handle on the file the command is written to
        ///   - index: the index of the command
        ///   - rawType: the raw type of the command
        ///   - param1: first parameter of the command, type dependant
        ///   - param2: second parameter of the command, type dependant
        ///   - param3: third parameter of the command, type dependant
        ///   - param4: fourth parameter of the command, type dependant
        ///   - latitude: the latitude of the command
        ///   - longitude: the longitude of the command
        ///   - altitude: the altitude of the command
        private func doWrite(fileHandle: FileHandle, index: Int, rawType: Int, param1: Double = .nan,
                             param2: Double = .nan, param3: Double = .nan, param4: Double = .nan,
                             latitude: Double = .nan, longitude: Double = .nan, altitude: Double = .nan) {
            let line = String(format: "%d\t%d\t%d\t%d\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%d\n",
                              index, MavlinkCommand.currentWaypoint, MavlinkCommand.frame, rawType,
                              param1, param2, param3, param4,
                              latitude, longitude, altitude, MavlinkCommand.autoContinue)
            if let data = line.data(using: .utf8) {
                fileHandle.write(data)
            }
        }
    }
}

// MARK: - Factory methods

extension MavlinkStandard.MavlinkCommand {

    /// Parses a line of a MAVLink file.
    ///
    /// - Parameter line: line of MAVLink file
    /// - Returns: MAVLink command, or `nil` if the line could not be parsed
    /// - Throws:
    ///   - `MavlinkStandard.MavlinkCommand.ParseError.invalidLine` if a line has an incorrect of tokens or
    ///     the token separator is not the tab character (\t).
    ///   - `MavlinkStandard.MavlinkCommand.ParseError.invalidParameter` if a token can not be converted to a
    ///     a Double.
    static func parse(line: String) throws -> MavlinkStandard.MavlinkCommand {
        let tokens = line.split(separator: "\t")
        guard tokens.count == 12, let rawType = Int(tokens[3]) else {
            throw ParseError
            .invalidLine("The mavlink line had \(tokens.count) parts separated by a tab character (\t) instead of 12.")
        }
        let parameters = try tokens[4...10].map { (token: Substring) throws -> Double in
            guard let value = Double(token) else {
                throw ParseError.invalidParameter("Argument \(token) can not be converted to Double.")
            }
            return value
        }
        guard let type = CommandType(rawValue: rawType) else {
            return try MavlinkStandard.OtherMavlinkCommand(rawType: rawType, parameters: parameters)
        }
        return try command(forType: type, parameters: parameters)
    }

    /// Create a MAVLink command.
    ///
    /// - Parameters:
    ///   - rawType: the integer that describes the type of the MAVLink command.
    ///   - parameters: the raw parameters of the command.
    /// - Throws: MavlinkStandard.MavlinkCommand.ParseError if the parameters are wrong.
    /// - Returns: A MAVLink command.
    static func create(rawType: Int, parameters: [Double]) throws -> MavlinkStandard.MavlinkCommand {
        guard parameters.count == 7 else {
            throw MavlinkStandard.MavlinkCommand.ParseError
            .incorrectNumberOfParameters("Expected 7 parameters but instead got \(parameters.count).")
        }
        if let type = CommandType(rawValue: rawType) {
            return try command(forType: type, parameters: parameters)
        }
        return try MavlinkStandard.OtherMavlinkCommand(rawType: rawType, parameters: parameters)
    }

    /// Create a MAVLink command.
    ///
    /// - Parameters:
    ///   - rawType: the integer that describes the type of the MAVLink command.
    ///   - param1: first parameter of the command, type dependant
    ///   - param2: second parameter of the command, type dependant
    ///   - param3: third parameter of the command, type dependant
    ///   - param4: fourth parameter of the command, type dependant
    ///   - latitude: the latitude of the command
    ///   - longitude: the longitude of the command
    ///   - altitude: the altitude of the command
    /// - Throws: MavlinkStandard.MavlinkCommand.ParseError if the parameters are wrong.
    /// - Returns: A MAVLink command.
    static func create(rawType: Int, param1: Double = .nan,
                       param2: Double = .nan,
                       param3: Double = .nan,
                       param4: Double = .nan,
                       latitude: Double = .nan,
                       longitude: Double = .nan,
                       altitude: Double = .nan) throws -> MavlinkStandard.MavlinkCommand {
        return try create(rawType: rawType,
                          parameters: [param1, param2, param3, param4,
                                       latitude, longitude, altitude])
    }
}

// MARK: - Private Factory methods

extension MavlinkStandard.MavlinkCommand {

    /// Create a known MAVLink command.
    ///
    /// - Parameters:
    ///   - type: the command type.
    ///   - param1: first parameter of the command, type dependant
    ///   - param2: second parameter of the command, type dependant
    ///   - param3: third parameter of the command, type dependant
    ///   - param4: fourth parameter of the command, type dependant
    ///   - latitude: the latitude of the command
    ///   - longitude: the longitude of the command
    ///   - altitude: the altitude of the command
    /// - Throws: MavlinkStandard.MavlinkCommand.ParseError if the parameters are wrong.
    /// - Returns: A MAVLink command.
    static private func command(forType type: CommandType,
                                param1: Double = .nan,
                                param2: Double = .nan,
                                param3: Double = .nan,
                                param4: Double = .nan,
                                latitude: Double = .nan,
                                longitude: Double = .nan,
                                altitude: Double = .nan) throws -> MavlinkStandard.MavlinkCommand {
        return try command(forType: type,
                           parameters: [param1, param2, param3, param4,
                                        latitude, longitude, altitude])
    }

    /// Create a known MAVLink command.
    ///
    /// - Parameters:
    ///   - type: the command type.
    ///   - parameters: the raw parameters.
    /// - Throws: MavlinkStandard.MavlinkCommand.ParseError if the parameters are wrong.
    /// - Returns: A MAVLink command.
    static private func command(forType type: CommandType,
                                parameters: [Double]) throws -> MavlinkStandard.MavlinkCommand {
        switch type {
        case .navigateToWaypoint:
            return try MavlinkStandard.NavigateToWaypointCommand(parameters: parameters)
        case .returnToLaunch:
            return MavlinkStandard.ReturnToLaunchCommand()
        case .land:
            return try MavlinkStandard.LandCommand(parameters: parameters)
        case .takeOff:
            return try MavlinkStandard.TakeOffCommand(parameters: parameters)
        case .delay:
            return try MavlinkStandard.DelayCommand(parameters: parameters)
        case .changeSpeed:
            return try MavlinkStandard.ChangeSpeedCommand(parameters: parameters)
        case .setRoiLocation:
            return try MavlinkStandard.SetRoiLocationCommand(parameters: parameters)
        case .setRoi:
            return try MavlinkStandard.SetRoiCommand(parameters: parameters)
        case .mountControl:
            return try MavlinkStandard.MountControlCommand(parameters: parameters)
        case .cameraTriggerDistance:
            return try MavlinkStandard.CameraTriggerDistanceCommand(parameters: parameters)
        case .cameraTriggerInterval:
            return try MavlinkStandard.CameraTriggerIntervalCommand(parameters: parameters)
        case .startPhotoCapture:
            return try MavlinkStandard.StartPhotoCaptureCommand(parameters: parameters)
        case .stopPhotoCapture:
            return MavlinkStandard.StopPhotoCaptureCommand()
        case .startVideoCapture:
            return MavlinkStandard.StartVideoCaptureCommand()
        case .stopVideoCapture:
            return MavlinkStandard.StopVideoCaptureCommand()
        case .createPanorama:
            return try MavlinkStandard.CreatePanoramaCommand(parameters: parameters)
        case .setViewMode:
            return try MavlinkStandard.SetViewModeCommand(parameters: parameters)
        case .setStillCaptureMode:
            return try MavlinkStandard.SetStillCaptureModeCommand(parameters: parameters)
        case .setRoiNone:
            return MavlinkStandard.SetRoiNoneCommand()
        default:
            assert(false) // should not get to this point.
            throw ParseError.generic
        }
    }
}
