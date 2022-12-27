// Copyright (C) 2022 Parrot Drones SAS
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

/// A plan file representation.
///
/// [Parrot Plan format documentation](https://developer.parrot.com/docs/mavlink-flightplan/plan_format.html)
public struct Plan: Equatable {
    /// The current Plan format version.
    public static let Version = "1"
    /// The current plan format type.
    public static let Filetype = "Plan"
    /// The Parrot version of the items.
    ///
    /// That is the version of the Mavlink commands that will be used. The current API uses
    /// `MavlinkStandard.MavlinkCommand` which implicitly means V2.
    ///
    /// cf https://developer.parrot.com/docs/mavlink-flightplan/messages_v2.html
    /// cf `Plan.generate(plan:atFilepath:groundStation:)` for more information on the
    /// `mission.items` field.
    public static let ItemsVersion = "2"

    /// The static configuration of the plan.
    public let staticConfig: StaticConfig?
    /// The list of items of the plan.
    public let items: [Item]

    /// Constructor
    ///
    /// - Parameters:
    ///   - staticConfig: the static config of the plan.
    ///   - items: the list of items of the plan.
    public init(staticConfig: Plan.StaticConfig? = nil, items: [Plan.Item]) {
        self.staticConfig = staticConfig
        self.items = items
    }

    /// - Parameters:
    ///   - index: the command index
    /// - returns: the command at `index` if any.
    public subscript(command index: Int) -> MavlinkStandard.MavlinkCommand? {
        self.command(at: index)
    }

    /// - Parameters:
    ///   - index: the config index
    /// - returns: the config at `index` if any.
    public subscript(config index: Int) -> Config? {
        self.config(at: index)
    }

    /// - Parameters:
    ///   - index: the config index
    /// - returns: the config at `index` if any.
    private func config(at index: Int) -> Config? {
        let configs = items.compactMap { (item: Item) -> Config? in
            switch item {
            case .config(let config):
                return config
            default:
                return nil
            }
        }
        guard configs.startIndex <= index, index < configs.endIndex else {
            return nil
        }
        return configs[index]
    }

    /// - Parameters:
    ///   - index: the command index
    /// - returns: the command at `index` if any.
    private func command(at index: Int) -> MavlinkStandard.MavlinkCommand? {
        let commands = items.compactMap {  (item: Item) -> MavlinkStandard.MavlinkCommand? in
            switch item {
            case .command(let command):
                return command
            default:
                return nil
            }
        }
        guard commands.startIndex <= index, index < commands.endIndex else {
            return nil
        }
        return commands[index]
    }

    /// Generates a plan file in the given filepath URL with the given
    /// items and configurations.
    ///
    /// The resulting file will contain the plan file which is a JSON based
    /// format. The principal sections of the plan format are:
    /// - mission: an object that contains the mavlink command "items"
    ///     array.
    /// - mission.items: an array of MavlinkCommand representations.
    ///   Enriched with the optional "config" key which is an index in the
    ///   config array (cf below)
    /// - configs: an object that contains the config "items" array.
    /// - configs.items: a dictionary of Config representations to string indices.
    ///
    /// - Parameters:
    ///   - plan: the plan representation to write out to `filepath`.
    ///   - fileUrl: a local file URL where the output will be written.
    ///   - groundStation: the ground station id that creates the plan.
    /// - throws:
    ///   - `Plan.Error.unavailable` if the service is not available.
    ///   - `Plan.Error.noItems` if `items` is empty.
    ///   - `Plan.Error.fileExists` if `filepath` points to an existing file.
    ///   - any JSON encoder errors that can occur during generation.
    ///   - any FileManager errors that can occur during path manipulations.
    public static func generate(plan: Plan, at fileUrl: URL,
                                groundStation: String = "GroundSdk") throws {
        guard let provider = GroundSdkCore.getInstance().utilities.getUtility(Utilities.planUtilityProvider) else {
            throw Error.unavailable
        }
        try provider.generate(plan: plan, at: fileUrl, groundStation: groundStation)
    }

    /// Generates plan file data.
    ///
    /// cf `Plan.generate(plan:atFilepath:groundStation:)` for more information.
    ///
    /// - Parameters:
    ///   - plan: the plan representation to write out to `filepath`.
    ///   - groundStation: the ground station id that creates the plan.
    /// - throws:
    ///   - `Plan.Error.unavailable` if the service is not available.
    ///   - `Plan.Error.noItems` if `items` is empty.
    ///   - any JSON encoder errors that can occur during generation.
    /// - returns: a plan file (in JSON format)
    public static func generate(plan: Plan, groundStation: String = "GroundSdk") throws -> Data {
        guard let provider = GroundSdkCore.getInstance().utilities.getUtility(Utilities.planUtilityProvider) else {
            throw Error.unavailable
        }
        return try provider.generate(plan: plan, groundStation: groundStation)
    }

    /// Parses a plan file in the given filepath URL.
    ///
    /// The resulting object will contain the plan file which is a JSON based
    /// format.
    /// - Parameters:
    ///   - fileUrl: a local file URL where an existing plan resides.
    /// - throws:
    ///   - `Plan.Error.unavailable` if the service is not available.
    ///   - `Plan.Error.fileDoesNotExist` if `filepath` does not exist.
    ///   - `Plan.Error.parseError` if during the parsing any content of the plan
    ///      file can not be converted.
    ///   - any JSON decoder errors that can occur during decoding.
    /// - returns: a plan representation instance.
    public static func parse(fileUrl: URL) throws -> Plan {
        guard let provider = GroundSdkCore.getInstance().utilities.getUtility(Utilities.planUtilityProvider) else {
            throw Error.unavailable
        }
        return try provider.parse(fileUrl: fileUrl)
    }

    /// Parses a plan file data.
    ///
    /// The resulting object will contain the plan file which is a JSON based
    /// format.
    /// - Parameters:
    ///   - filepath: a local file URL where an existing plan resides.
    /// - throws:
    ///   - `Plan.Error.unavailable` if the service is not available.
    ///   - `Plan.Error.parseError` if during the parsing any content of the plan
    ///      file can not be converted.
    ///   - any JSON decoder errors that can occur during decoding.
    /// - returns: a plan representation instance.
    public static func parse(planData: Data) throws -> Plan {
        guard let provider = GroundSdkCore.getInstance().utilities.getUtility(Utilities.planUtilityProvider) else {
            throw Error.unavailable
        }
        return try provider.parse(planData: planData)
    }

    /// A Plan generation/parsing error
    public enum Error: Swift.Error, Equatable {
        /// The provided `items` list is empty.
        case noItems
        /// The given local file URL already exists.
        case fileExists
        /// The given local file does not exist.
        case fileDoesNotExist
        /// Parse error occured.
        ///
        /// The associated argument contains a String explication of the error.
        case parseError(String)
        /// The generation of plan files is unavailable.
        case unavailable
    }
}

extension Plan {
    /// The item of a plan file. It can either be a command or a configuration.
    public enum Item: Equatable {
        /// A plan item that represents a MavlinkCommand.
        case command(MavlinkStandard.MavlinkCommand)
        /// A plan item that represents a Config.
        case config(Config)
    }

    /// The config of a particular plan item.
    public struct Config: Equatable {
        /// Whether to enable obstacle avoidance.
        public var obstacleAvoidance: Bool?
        /// The EV compensation of the camera.
        public var evCompensation: Camera2EvCompensation?
        /// The white balance mode of the camera.
        public var whiteBalance: Camera2WhiteBalanceMode?
        /// The photo resolution of the camera.
        public var photoResolution: Camera2PhotoResolution?
        /// The video resolution of the camera.
        public var videoResolution: Camera2RecordingResolution?
        /// The frame rate of the camera.
        public var frameRate: Camera2RecordingFramerate?

        /// Constructor.
        ///
        /// - Parameters:
        ///   - obstacleAvoidance: whether to enable obstacle avoidance.
        ///   - evCompensation: the EV compensation of the camera.
        ///   - whiteBalance: the white balance mode of the camera.
        ///   - photResolution: the photo resolution of the camera.
        ///   - videoResolution: the video resolution of the camera.
        ///   - frameRate: the frame rate of the camera.
        public init(obstacleAvoidance: Bool? = nil, evCompensation: Camera2EvCompensation? = nil,
                    whiteBalance: Camera2WhiteBalanceMode? = nil,
                    photoResolution: Camera2PhotoResolution? = nil,
                    videoResolution: Camera2RecordingResolution? = nil,
                    frameRate: Camera2RecordingFramerate? = nil) {
            self.obstacleAvoidance = obstacleAvoidance
            self.evCompensation = evCompensation
            self.whiteBalance = whiteBalance
            self.photoResolution = photoResolution
            self.videoResolution = videoResolution
            self.frameRate = frameRate
        }
    }

    /// The static config of a plan.
    public struct StaticConfig: Equatable {
        /// Whether the RTH is custom.
        public var customRth: Bool?
        /// The RTH type.
        public var rthType: ReturnHomeTarget?
        /// The RTH altitude (in meters).
        public var rthAltitude: Double?
        /// The RTH end altitude (in meters).
        public var rthEndAltitude: Double?
        /// Whether to perform an RTH on link disconnection.
        public var disconnectionPolicy: FlightPlanDisconnectionPolicy?
        /// Whether to land at the end of the RTH.
        public var rthEndingBehavior: ReturnHomeEndingBehavior?
        /// Whether to digitally sign the acquired photos or not.
        public var digitalSignature: Camera2DigitalSignature?
        /// The custom ID of the Plan.
        public var customId: String?
        /// The custom title of the Plan.
        public var customTitle: String?

        /// Constructor.
        ///
        /// - Parameters:
        ///   - customRth: whether the RTH is custom.
        ///   - rthType: the RTH type.
        ///   - rthAltitude: the RTH altitude (in meters).
        ///   - rthEndAltitude: the RTH end altitude (in meters).
        ///   - disconnectionPolicy: whether to perform an RTH on link disconnection.
        ///   - rthEndingBehavior: whether to land ot the end of the RTH.
        ///   - digitalSignature: whether to digitally sign the acquired photos or not.
        ///   - customId: The custom ID of the plan.
        ///   - customTitle: The custom title of the plan.
        public init(customRth: Bool? = nil, rthType: ReturnHomeTarget? = nil,
                    rthAltitude: Double? = nil, rthEndAltitude: Double? = nil,
                    disconnectionPolicy: FlightPlanDisconnectionPolicy? = nil,
                    rthEndingBehavior: ReturnHomeEndingBehavior? = nil,
                    digitalSignature: Camera2DigitalSignature? = .drone,
                    customId: String? = nil,
                    customTitle: String? = nil) {
            self.customRth = customRth
            self.rthType = rthType
            self.rthAltitude = rthAltitude
            self.rthEndAltitude = rthEndAltitude
            self.disconnectionPolicy = disconnectionPolicy
            self.rthEndingBehavior = rthEndingBehavior
            self.digitalSignature = digitalSignature
            self.customId = customId
            self.customTitle = customTitle
        }
    }
}
