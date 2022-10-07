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

/// Log collector source.
public enum LogCollectorSource: Hashable, CustomStringConvertible {
    /// A drone source.
    case drone(Drone)
    /// A remote control source.
    case remoteControl(RemoteControl)
    /// An application source.
    case application(URL)

    /// Debug description.
    public var description: String {
        switch self {
        case let .drone(device):
            return "drone: \(device.name)"
        case let .remoteControl(device):
            return "remote control: \(device.name)"
        case .application:
            return "application"
        }
    }
}

/// Status of the log collection for all sources.
public enum LogCollectorGlobalStatus: CustomStringConvertible {
    /// Collection is in progress.
    case collecting
    /// Logs archiving is in progress.
    case archiving
    /// Collection process has completed successfully.
    case done
    /// Collection process has failed.
    case failed

    /// Debug description.
    public var description: String {
        switch self {
        case .collecting:
            return "collecting"
        case .archiving:
            return "archiving"
        case .done:
            return "done"
        case .failed:
            return "failed"
        }
    }
}

/// Status of the log collection for one source.
public enum LogCollectorStatus: CustomStringConvertible {
    /// Collection is pending.
    case pending
    /// Collection is in progress.
    case collecting
    /// Collection has completed successfully.
    case collected
    /// Collection has failed.
    case failed
    /// Collection has been canceled.
    case canceled

    /// Debug description.
    public var description: String {
        switch self {
        case .pending:
            return "pending"
        case .collecting:
            return "collecting"
        case .collected:
            return "collected"
        case .failed:
            return "failed"
        case .canceled:
            return "canceled"
        }
    }
}

/// State of the log collection for one source.
public class LogCollectorState: CustomStringConvertible {
    /// Status of the log collection.
    public internal(set) var status: LogCollectorStatus

    /// Overall size of the logs that should be collected, in bytes.
    public internal(set) var totalSize: UInt64?

    /// Size of the logs that have already been collected, in bytes.
    public internal(set) var collectedSize: UInt64?

    /// Constructor.
    ///
    /// - Parameters:
    ///   - status: the initial status
    ///   - totalSize: the initial overall size
    ///   - collectedSize: the initial collected size
    internal init(status: LogCollectorStatus = .pending, totalSize: UInt64? = nil, collectedSize: UInt64? = nil) {
        self.status = status
        self.totalSize = totalSize
        self.collectedSize = collectedSize
    }

    /// Debug description.
    public var description: String {
        return "\(status) \(String(describing: collectedSize))/\(String(describing: totalSize))"
    }
}

/// Latest logs collector interface.
public class LogCollector {
    /// Overall status of the log collection.
    public let globalStatus: LogCollectorGlobalStatus

    /// Collector states, by their associated source.
    public let states: [LogCollectorSource: LogCollectorState]

    /// URL of archive file containing latest logs when global status is `collected`, nil in other cases.
    public let destination: URL?

    /// Constructor.
    ///
    /// - Parameters:
    ///   - globalStatus: overall status
    ///   - states: states by sources
    ///   - destination: created archive file URL
    init(globalStatus: LogCollectorGlobalStatus, states: [LogCollectorSource: LogCollectorState], destination: URL?) {
        self.globalStatus = globalStatus
        self.states = states
        self.destination = destination
    }
}
