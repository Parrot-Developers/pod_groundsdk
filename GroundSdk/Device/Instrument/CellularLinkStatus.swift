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

/// Cellular link status.
public enum CellularLinkStatusStatus: CustomStringConvertible, Equatable {
    /// Interface is down.
    case down
    /// Interface is up with IP connectivity.
    case up
    /// Session established on the link.
    case running
    /// Link is ready to connect or accept connections.
    case ready
    /// Connection in progress.
    case connecting
    /// Link error.
    /// - error: error type, if available
    case error(error: CellularLinkStatusError?)

    /// Debug description.
    public var description: String {
        switch self {
        case .down: return "down"
        case .up: return "up"
        case .running: return "running"
        case .ready: return "ready"
        case .connecting: return "connecting"
        case .error(let error): return "error \(error?.description ?? "unknown")"
        }
    }
}

/// Cellular link error.
public enum CellularLinkStatusError: String, CustomStringConvertible, CaseIterable {
    /// Failed to resolve DNS address.
    case dns
    /// Failed to connect to SIP server.
    case connect
    /// Failed to authenticate to server.
    case authentication
    /// Failed to publish drone status.
    case publish
    /// Failed to establish communication link.
    case communicationLink
    /// Lost connection with peer.
    case timeout
    /// Failed to invite drone.
    case invite

    /// Debug description.
    public var description: String { rawValue }
}

/// CellularLinkStatus instrument.
///
/// This instrument provides status of cellular link.
///
/// This instrument can be retrieved by:
/// ```
/// device.getInstrument(Instruments.cellularLinkStatus)
/// ```
public protocol CellularLinkStatus: Instrument {
    /// Celullar link status, or `nil` if not available.
    var status: CellularLinkStatusStatus? { get }
}

/// :nodoc:
/// Instrument descriptor.
public class CellularLinkStatusDesc: NSObject, InstrumentClassDesc {
    public typealias ApiProtocol = CellularLinkStatus
    public let uid = InstrumentUid.cellularLinkStatus.rawValue
    public let parent: ComponentDescriptor? = nil
}
