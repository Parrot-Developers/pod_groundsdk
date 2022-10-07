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

/// Cellular session status.
public enum CellularSessionStatus: Hashable, Equatable, CaseIterable, CustomStringConvertible {
    /* Modem status. */
    public enum Modem: Hashable, Equatable, CaseIterable {
        case off
        case offline
        case updating
        case online
        case error
    }

    /* SIM status. */
    public enum Sim: Hashable, Equatable, CaseIterable {
        case locked
        case ready
        case absent
        case error
    }

    /* Network registration status. */
    public enum Network: Hashable, Equatable, CaseIterable {
        case searching
        case home
        case roaming
        case registrationDenied
        case activationDenied
    }

    /* Parrot server connection status. */
    public enum Server: Hashable, Equatable, CaseIterable {
        case waitApcToken
        case connecting
        case connected
        case unreachableDns
        case unreachableConnect
        case unreachableAuth
    }

    /* Drone/controller connection status. */
    public enum Connection: Hashable, Equatable, CaseIterable {
        case offline
        case connecting
        case established
        case error
        case errorCommLink
        case errorTimeout
        case errorMismatch
    }

    case unknown
    case modem(Modem)
    case sim(Sim)
    case network(Network)
    case server(Server)
    case connection(Connection)

    public static var allCases: [CellularSessionStatus] {
        [CellularSessionStatus.unknown]
        + Modem.allCases.map { CellularSessionStatus.modem($0) }
        + Sim.allCases.map { CellularSessionStatus.sim($0) }
        + Network.allCases.map { CellularSessionStatus.network($0) }
        + Server.allCases.map { CellularSessionStatus.server($0) }
        + Connection.allCases.map { CellularSessionStatus.connection($0) }
    }

    /// Debug description
    public var description: String {
        switch self {
        case .modem(let sub):
            switch sub {
            case .off: return "modemOff"
            case .offline: return "modemOffline"
            case .updating: return "modemUpdating"
            case .online: return "modemOnline"
            case .error: return "modemError"
            }
        case .sim(let sub):
            switch sub {
            case .locked: return "simLocked"
            case .ready: return "simReady"
            case .absent: return "simAbsent"
            case .error: return "simError"
            }
        case .network(let sub):
            switch sub {
            case .searching: return "networkSearching"
            case .home: return "networkHome"
            case .roaming: return "networkRoaming"
            case .registrationDenied: return "networkRegistrationDenied"
            case .activationDenied: return "networkActivationDenied"
            }
        case .server(let sub):
            switch sub {
            case .waitApcToken: return "serverWaitApcToken"
            case .connecting: return "serverConnecting"
            case .connected: return "serverConnected"
            case .unreachableDns: return "serverUnreachableDns"
            case .unreachableConnect: return "serverUnreachableConnect"
            case .unreachableAuth: return "serverUnreachableAuth"
            }
        case .connection(let sub):
            switch sub {
            case .offline: return "connectionOffline"
            case .connecting: return "connectionConnecting"
            case .established: return "connectionEstablished"
            case .error: return "connectionError"
            case .errorCommLink: return "connectionErrorCommLink"
            case .errorTimeout: return "connectionErrorTimeout"
            case .errorMismatch: return "connectionErrorMismatch"
            }
        case .unknown:
            return "unknown"
        }
    }

    /// States indicating a functioning cellular session.
    public static var nominalStates: Set<CellularSessionStatus> {
        [.modem(.online), .sim(.ready), .network(.home), .network(.roaming),
         .server(.connected), .connection(.established)]
    }

    /// States indicating a transition of the cellular session from a nominal state towards a new
    /// nominal state or an new error state.
    public static var transitoryStates: Set<CellularSessionStatus> {
        [.modem(.off), .modem(.offline), .modem(.updating),
         .sim(.locked), .sim(.absent),
         .network(.searching),
         .server(.waitApcToken), .server(.connecting),
         .connection(.offline), .connection(.connecting)]
    }

    /// States indicating an error on the cellular session.
    public static var errorStates: Set<CellularSessionStatus> {
        [.modem(.error), .sim(.error),
         .network(.registrationDenied), .network(.activationDenied),
         .server(.unreachableDns), .server(.unreachableConnect), .server(.unreachableAuth),
         .connection(.error), .connection(.errorCommLink), .connection(.errorTimeout),
         .connection(.errorMismatch)]
    }

    /// Whether the receiver is a nominal state.
    public var isNominal: Bool {
        CellularSessionStatus.nominalStates.contains(self)
    }

    /// Whether the receiver is an error state.
    public var isError: Bool {
        CellularSessionStatus.errorStates.contains(self)
    }

    /// Whether the receiver is a transitory state.
    public var isTransitory: Bool {
        CellularSessionStatus.transitoryStates.contains(self)
    }
}

/// CellularSession instrument.
///
/// This instrument provides status of cellular session.
///
/// This instrument can be retrieved by:
/// ```
/// device.getInstrument(Instruments.cellularSession)
/// ```
public protocol CellularSession: Instrument {
    /// Celullar link status, or `nil` if not available.
    var status: CellularSessionStatus? { get }
}

/// :nodoc:
/// Instrument descriptor.
public class CellularSessionDesc: NSObject, InstrumentClassDesc {
    public typealias ApiProtocol = CellularSession
    public let uid = InstrumentUid.cellularSession.rawValue
    public let parent: ComponentDescriptor? = nil
}
