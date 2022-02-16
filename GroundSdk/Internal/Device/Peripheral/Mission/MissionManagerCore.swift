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

/// Mission message implementation.
public class MissionMessageCore: MissionMessage, Equatable {

    /// Unique mission id
    public var missionUid: String

    /// Service uid
    public var serviceUid: UInt

    /// Message uid.
    public var messageUid: UInt

    /// Actual content of the mission message.
    public var payload: Data

    /// Constructor
    ///
    /// - Parameters:
    ///   - missionUid: mission unique id
    ///   - serviceUid: service unique id
    ///   - messageUid: message unique id
    ///   - payload: actual content of the mission message
    public init(missionUid: String, serviceUid: UInt, messageUid: UInt, payload: Data) {
        self.missionUid = missionUid
        self.serviceUid = serviceUid
        self.messageUid = messageUid
        self.payload = payload
    }

    // Equatable Concordance
    public static func == (lhs: MissionMessageCore, rhs: MissionMessageCore) -> Bool {
        return lhs.serviceUid == rhs.serviceUid
            && lhs.messageUid == rhs.messageUid && lhs.payload == rhs.payload
            && lhs.missionUid == rhs.missionUid
    }
}

/// Mission manager backend protocol
public protocol MissionManagerBackend: AnyObject {
    /// Load the mission.
    ///
    /// - Parameter uid: mission unique identifier.
    func load(uid: String)

    /// Unload the mission.
    ///
    /// - Parameter uid: mission unique identifier.
    func unload(uid: String)

    /// Activate the mission.
    ///
    /// - Parameter uid: mission unique identifier.
    func activate(uid: String)

    /// Send a message to a mission
    ///
    /// - Parameter message: mission message
    func sendMessage(message: MissionMessage)
}

/// Internal mission manager implementation
public class MissionManagerCore: PeripheralCore, MissionManager {

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Array of mission by uid
    public var missions: [String: Mission] {
        return _missions
    }

    private(set) public var _missions: [String: MissionCore] = [:]

    /// Last mission message
    public var latestMessage: MissionMessage? {
        return _lastestMessage
    }
    private var _lastestMessage: MissionMessageCore?

    /// Uid of mission whose activation is suggested by the drone.
    public var suggestedActivation: String? {
        return _suggestedActivation
    }
    private var _suggestedActivation: String?

    /// Implementation backend
    private unowned let backend: MissionManagerBackend

    /// Constructor
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored.
    ///   - backend: mission backend.
    public init(store: ComponentStoreCore, backend: MissionManagerBackend) {
        self.backend = backend
        super.init(desc: Peripherals.missionManager, store: store)
    }

    /// Load the mission.
    ///
    /// - Parameter uid: mission unique identifier.
    public func load(uid: String) {
        if missions[uid] != nil && missions[uid]!.state == .unloaded {
            backend.load(uid: uid)
        }
    }

    /// Unload the mission.
    ///
    /// - Parameter uid: mission unique identifier.
    public func unload(uid: String) {
        if missions[uid] != nil && (missions[uid]!.state == .active || missions[uid]!.state == .idle) {
            backend.unload(uid: uid)
        }
    }

    /// Activate the mission.
    ///
    /// - Parameter uid: mission unique identifier.
    public func activate(uid: String) {
        if let mission = missions[uid], mission.state == .idle {
            // Mission is now activating.
            _missions[uid]?.state = .activating
            markChanged()
            self.notifyUpdated()

            backend.activate(uid: uid)
            timeout.schedule { [weak self] in
                if let `self` = self, self.reset(updatingMission: uid) {
                    // force update of peripheral in case updating was changed.
                    self.notifyUpdated()
                }
            }
        }
    }

    /// Called by the backend, change the setting data
    ///
    /// - Parameter updatingMission: the mission to update.
    /// - Returns: self to allow call chaining
    @discardableResult public func reset(updatingMission
        newUpdatingMission: String) -> Bool {
        if let mission = _missions[newUpdatingMission], mission.state == .activating {
            mission.state = .idle
            markChanged()
            return true
        }
        return false
    }

    /// Deactivate current mission. Default mission will be selected
    public func deactivate() {
        backend.activate(uid: "default")
    }

    /// Send a message to a mission
    ///
    /// - Parameter message: mission message
    public func send(message: MissionMessage) {
        backend.sendMessage(message: message)
    }

    /// Updates mission message.
    ///
    /// - Parameter message: new message
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(message newMessage: MissionMessageCore?)
    -> MissionManagerCore {
        if _lastestMessage != newMessage {
            _lastestMessage = newMessage
            markChanged()
        }
        return self
    }

    /// Updates the missions array.
    ///
    /// - Parameter missions: new mission array.
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(missions newMissions: [String: MissionCore])
    -> MissionManagerCore {
        if _missions != newMissions {
            _missions = newMissions
            markChanged()
        }
        return self
    }

    /// Updates the state and unavailability reason for a mission
    ///
    /// - Parameters:
    ///     - uid: string (name of the mission), defined during the development of the mission
    ///   and makes it possible to uniquely identify each mission.
    ///     - state: State of the mission.
    ///     - unavailabilityReason: Unavailability reason for the mission.
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(uid: String, state: MissionState,
                                          unavailabilityReason: MissionUnavailabilityReason) -> MissionManagerCore {
        if let mission = _missions[uid] {
            if mission.state != state {
                mission.state = state
                timeout.cancel()
                markChanged()
            }
            if mission.unavailabilityReason != unavailabilityReason {
                mission.unavailabilityReason = unavailabilityReason
                markChanged()
            }
        }
        return self
    }

    /// Updates the uid of mission whose activation is suggested by the drone.
    ///
    /// - Parameter suggestedActivation: new suggested activation.
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(suggestedActivation newSuggestedActivation: String?)
    -> MissionManagerCore {
        if _suggestedActivation != newSuggestedActivation {
            _suggestedActivation = newSuggestedActivation
            markChanged()
        }
        return self
    }

    /// Cancels all pending activation rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelActivationRollback() -> MissionManagerCore {
        for mission in _missions {
            self.reset(updatingMission: mission.key)
            markChanged()
        }
        return self
    }
}
