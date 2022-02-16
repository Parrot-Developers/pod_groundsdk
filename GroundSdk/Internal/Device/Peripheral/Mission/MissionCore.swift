// Copyright (C) 2020 Parrot Drones SAS
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

/// Mission implementation.
public class MissionCore: Mission, Equatable, Hashable {

    /// Unique id
    public var uid: String = ""

    /// Descriptor.
    public var description: String = ""

    /// Name of the mission
    public var name: String = ""

    /// Version of the mission.
    public var version: String = ""

    /// Id to use to exchange messages with the mission (given by the drone)
    public var recipientId: UInt?

    /// Model id of the supported target.
    public var targetModelId: Drone.Model?

    /// Minimum version of target supported.
    public var minTargetVersion: FirmwareVersion?

    /// Maximum version of target supported.
    public var maxTargetVersion: FirmwareVersion?

    /// State of activation of the mission.
    public var state: MissionState = .unavailable

    /// Unavailability reason(s) to load the mission.
    /// Empty if mission is activate.
    public var unavailabilityReason: MissionUnavailabilityReason = .none

    /// Tells if the setting value has been changed and is waiting for change confirmation
    public var updating: Bool = false

    /// Constructor
    ///
    /// - Parameters:
    ///   - uid: string (name of the mission), defined during the development of the mission
    ///   and makes it possible to uniquely identify each mission.
    ///   - description: description of the mission.
    ///   - name: name of the mission.
    ///   - version: version of the mission.
    ///   - recipientId: id to use to exchange messages with the mission
    ///   - targetModelId: name of the mission.
    ///   - minTargetVersion: Minimum version of target supported.
    ///   - maxTargetVersion: Maximum version of target supported.
    required public init(uid: String, description: String, name: String, version: String, recipientId: UInt?,
        targetModelId: Drone.Model?, minTargetVersion: FirmwareVersion?, maxTargetVersion: FirmwareVersion?) {
        self.uid = uid
        self.description = description
        self.name = name
        self.minTargetVersion = minTargetVersion
        self.maxTargetVersion = maxTargetVersion
        self.version = version
        self.recipientId = recipientId
        self.targetModelId = targetModelId
    }

    // Equatable Concordance
    public static func == (lhs: MissionCore, rhs: MissionCore) -> Bool {
        return lhs.uid == rhs.uid && lhs.description == rhs.description && lhs.name == rhs.name
            && lhs.minTargetVersion == rhs.minTargetVersion && lhs.maxTargetVersion == rhs.maxTargetVersion
            && lhs.version == rhs.version
            && lhs.state == rhs.state && lhs.unavailabilityReason == rhs.unavailabilityReason
            && lhs.recipientId == rhs.recipientId && lhs.targetModelId == rhs.targetModelId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
}
