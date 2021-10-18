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

/// Mission message.
public protocol MissionMessage {
    /// String identifier defined during the development of the mission, allowing to uniquely identify each mission.
    var missionUid: String { get }

    /// Message uid..
    var messageUid: UInt { get }

    /// Service uid.
    var serviceUid: UInt { get }

    /// Actual content of the mission message.
    var payload: Data { get }
}

/// Peripheral managing mission.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.missionManager)
/// ```
public protocol MissionManager: Peripheral {

    /// Array of mission by uid
    var missions: [String: Mission] { get }

    /// Load the mission.
    /// If all goes well, state will change to .idle
    ///
    /// - Parameter uid: mission unique identifier.
    func load(uid: String)

    /// Unload the mission.
    /// If all goes well, state will change to .unloaded
    ///
    /// - Parameter uid: mission unique identifier.
    func unload(uid: String)

    /// Activate the mission.
    /// If all goes well, state will change to .active
    ///
    /// - Parameter uid: mission unique identifier.
    func activate(uid: String)

    /// Deactivate current mission. Default mission will be selected.
    func deactivate()

    /// Send a message to a mission.
    ///
    /// - Parameter message: mission message
    func send(message: MissionMessage)

    /// Last mission message coming from the drone.
    ///
    /// - Note: Message is transient, once it is notified it will be then put to nil.
    var latestMessage: MissionMessage? { get }

    /// Uid of mission whose activation is suggested by the drone.
    /// Transient state.
    var suggestedActivation: String? { get }
}

/// :nodoc:
/// Mission manager description.
public class MissionManagerDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = MissionManager
    public let uid = PeripheralUid.missionManager.rawValue
    public let parent: ComponentDescriptor? = nil
}
