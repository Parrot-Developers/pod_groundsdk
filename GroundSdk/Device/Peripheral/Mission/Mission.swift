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

/// Mission state.
public enum MissionState: Int, CustomStringConvertible {
    /// Mission is not available.
    case unavailable

    /// Mission is not loaded
    case unloaded

    /// Mission can be activated.
    case idle

    /// Mission is activating.
    case activating

    /// Mission is active.
    case active

    /// Debug description.
    public var description: String {
        switch self {
        case .unavailable: return "unavailable"
        case .unloaded:    return "unloaded"
        case .idle:        return "idle"
        case .activating:  return "activating"
        case .active:      return "active"
        }
    }
}

/// Mission unavailability reason
public enum MissionUnavailabilityReason: Int, CustomStringConvertible {

    /// No reason.
    /// The mission is actually available.
    case none

    /// Broken. Version is not supported.
    /// The mission will never be able to load or start.
    case broken

    /// Mission is not loaded.
    case loadFailed

    /// Debug description.
    public var description: String {
        switch self {
        case .none:   return "none"
        case .broken:   return "broken"
        case .loadFailed: return "loadFailed"
        }
    }
}

/// Mission object.
public protocol Mission {
    /// String identifier defined during the development of the mission, allowing to uniquely identify each mission.
    var uid: String { get }

    /// Descriptor.
    var description: String { get }

    /// Name of the mission
    var name: String { get }

    /// Minimum version of target supported.
    var minTargetVersion: FirmwareVersion? { get }

    /// Maximum version of target supported.
    var maxTargetVersion: FirmwareVersion? { get }

    /// State of activation of the mission.
    var state: MissionState { get }

    /// Unavailability reason(s) to load the mission.
    /// Empty if mission is activate.
    var unavailabilityReason: MissionUnavailabilityReason { get }

    /// Version of the mission.
    var version: String { get }

    /// Model id of the supported target.
    var targetModelId: Drone.Model? { get }
}
