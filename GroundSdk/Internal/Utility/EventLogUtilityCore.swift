//    Copyright (C) 2020 Parrot Drones SAS
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

/// Utility protocol managing event log files.
///
/// This utility may be unavailable if flight logs support is disabled in GroundSdk configuration.
public protocol EventLogUtilityCore: UtilityCore {

    /// Updates drone boot id in event log file.
    ///
    /// - Parameter bootId: new drone boot id
    func update(bootId: String)

    /// Logs an event.
    ///
    /// - Parameter message: log message
    func log(_ message: String)

    /// Closes current event log session and starts a new one, creating a new log file.
    func newSession()
}

/// Implementation of the `EventLogUtilityCore` utility.
class EventLogUtilityCoreImpl: EventLogUtilityCore {

    let desc: UtilityCoreDescriptor = Utilities.eventLogger

    /// Engine that acts as a backend for this utility.
    unowned let engine: EventLogEngine

    /// Constructor.
    ///
    /// - Parameter engine: the engine acting as a backend for this utility
    init(engine: EventLogEngine) {
        self.engine = engine
    }

    func update(bootId: String) {
        engine.update(bootId: bootId)
    }

    func log(_ message: String) {
        engine.log(message)
    }

    func newSession() {
        engine.newSession()
    }
}

/// Event logger utility description
public class EventLogUtilityCoreDesc: NSObject, UtilityCoreApiDescriptor {
    public typealias ApiProtocol = EventLogUtilityCore
    public let uid = UtilityUid.eventLogger.rawValue
}
