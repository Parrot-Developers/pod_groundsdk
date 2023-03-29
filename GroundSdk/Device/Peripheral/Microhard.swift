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

/// Microhard bandwidth.
public enum MicrohardBandwidth: String, CustomStringConvertible, CaseIterable {
    /// 1 MegaHertz bandwidth.
    case mHz1

    /// 2 MegaHertz bandwidth.
    case mHz2

    /// 4 MegaHertz bandwidth.
    case mHz4

    /// 8 MegaHertz bandwidth.
    case mHz8

    /// Debug description.
    public var description: String { rawValue }
}

/// Microhard encryption algorithm.
public enum MicrohardEncryption: String, CustomStringConvertible, CaseIterable {
    /// No encryption.
    case none

    /// 128-bit AES encryption.
    case aes128

    /// 256-bit AES encryption.
    case aes256

    /// Debug description.
    public var description: String { rawValue }
}

/// Reason why a Microhard device pairing failed.
public enum MicrohardPairingFailureReason: String, CustomStringConvertible, CaseIterable {
    /// Pairing failed due to some internal error.
    case internalError

    /// Microhard is not in a valid `state for pairing.
    case invalidState

    /// The device is already paired.
    case alreadyPaired

    /// Device could not be reached.
    case deviceNotReachable

    /// Debug description.
    public var description: String { rawValue }
}

/// Microhard state.
public enum MicrohardState: Equatable, CustomStringConvertible {
    /// Microhard is offline.
    case offline

    /// Microhard is booting.
    case booting

    /// Microhard is online and idle.
    case idle

    /// Currently pairing a device.
    /// - networkId: device network identifier
    /// - pairingParameters: device pairing parameters, if available
    /// - connectionParameters: device connection parameters, if available
    case pairing(networkId: String,
                 pairingParameters: MicrohardPairingParameters?,
                 connectionParameters: MicrohardConnectionParameters?)

    /// Currently connecting to a device.
    /// - deviceUid: device unique identifier
    case connecting(deviceUid: String)

    /// Currently connected to a device.
    /// - deviceUid: device unique identifier
    case connected(deviceUid: String)

    /// Whether the state allows pairing.
    public var canPair: Bool {
        switch self {
        case .offline, .booting, .pairing:
            return false
        default:
            return true
        }
    }

    /// Equatable concordance.
    public static func == (lhs: MicrohardState, rhs: MicrohardState) -> Bool {
        switch (lhs, rhs) {
        case (.offline, .offline), (.booting, .booting), (.idle, .idle):
            return true
        case let (.pairing(ln, lp, lc), .pairing(rn, rp, rc)):
            return ln == rn && lp == rp && lc == rc
        case let (.connecting(ld), .connecting(rd)),
             let (.connected(ld), .connected(rd)):
            return ld == rd
        default:
            return false
        }
    }

    /// Debug description.
    public var description: String {
        switch self {
        case .offline: return "offline"
        case .booting: return "booting"
        case .idle: return "idle"
        case .pairing(let networkId, _, _): return "pairing \(networkId)"
        case .connecting(let deviceUid): return "connecting \(deviceUid)"
        case .connected(let deviceUid): return "connected \(deviceUid)"
        }
    }
}

/// Microhard device pairting result.
public enum MicrohardPairingStatus: Equatable, CustomStringConvertible {
    /// Device pairing success.
    /// - networkId: device network identifier
    /// - deviceUid: device unique identifier
    case success(networkId: String, deviceUid: String)

    /// Device pairing failure.
    /// - networkId: device network identifier
    /// - reason: reason why the pairing failed
    case failure(networkId: String, reason: MicrohardPairingFailureReason)

    /// Equatable concordance.
    public static func == (lhs: MicrohardPairingStatus, rhs: MicrohardPairingStatus) -> Bool {
        switch (lhs, rhs) {
        case let (.success(ln, ld), .success(rn, rd)):
            return ln == rn && ld == rd
        case let (.failure(ln, lr), .failure(rn, rr)):
            return ln == rn && lr == rr
        default:
            return false
        }
    }

    /// Debug description.
    public var description: String {
        switch self {
        case .success(let networkId, let deviceUid):
            return "success \(networkId) \(deviceUid)"
        case .failure(let networkId, let reason):
            return "failure \(networkId) \(reason)"
        }
    }
}

/// Microhard device pairing parameters.
public struct MicrohardPairingParameters: Equatable {

    /// Pairing channel, in `Microhard.supportedChannelRange`.
    public var channel: UInt

    /// Pairing power in dBm, in `Microhard.supportedPowerRange`.
    public var power: UInt

    /// Pairing bandwidth, in `Microhard.supportedBandwidths`.
    public var bandwidth: MicrohardBandwidth

    /// Pairing encryption algorithm, in `Microhard.supportedEncryptions`.
    public var encryption: MicrohardEncryption

    /// Constructor.
    ///
    /// - Parameters:
    ///   - channel: pairing channel in MHz, in `Microhard.supportedChannelRange`
    ///   - power: pairing power in dBm, in `Microhard.supportedPowerRange`
    ///   - bandwidth: pairing bandwidth, in `Microhard.supportedBandwidths`
    ///   - encryption: pairing encryption algorithm, in `Microhard.supportedEncryptions`
    public init(channel: UInt, power: UInt, bandwidth: MicrohardBandwidth, encryption: MicrohardEncryption) {
        self.channel = channel
        self.power = power
        self.bandwidth = bandwidth
        self.encryption = encryption
    }
}

/// Microhard device connection parameters.
public struct MicrohardConnectionParameters: Equatable {

    /// Connection channel, in `Microhard.supportedChannelRange`.
    public var channel: UInt

    /// Connection power in dBm, in `Microhard.supportedPowerRange`.
    public var power: UInt

    /// Connection bandwidth, in `Microhard.supportedBandwidths`.
    public var bandwidth: MicrohardBandwidth

    /// Constructor.
    ///
    /// - Parameters:
    ///   - channel: connection channel in MHz, in `Microhard.supportedChannelRange`
    ///   - power: connection power in dBm, in `Microhard.supportedPowerRange`
    ///   - bandwidth: connection bandwidth, in `Microhard.supportedBandwidths`
    public init(channel: UInt, power: UInt, bandwidth: MicrohardBandwidth) {
        self.channel = channel
        self.power = power
        self.bandwidth = bandwidth
    }
}

/// Microhard peripheral.
///
/// This peripheral allows to pair drones supporting Microhard technology.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.microhard)
/// ```
public protocol Microhard: Peripheral {
    /// Current state.
    var state: MicrohardState { get }

    /// Pairing operation status.
    ///
    /// This property is transient: it will be set once when the pairing operation ends, and then
    /// immediately back to `nil`.
    var pairingStatus: MicrohardPairingStatus? { get }

    /// Supported operation channels.
    var supportedChannelRange: ClosedRange<UInt> { get }

    /// Supported operation power, in dBm.
    var supportedPowerRange: ClosedRange<UInt> { get }

    /// Supported operation bandwidths.
    var supportedBandwidths: Set<MicrohardBandwidth> { get }

    /// Supported encryption algorithms.
    var supportedEncryptions: Set<MicrohardEncryption> { get }

    /// Powers on the Microhard chip.
    ///
    /// - Returns: `true` if the command has been sent
    func powerOn() -> Bool

    /// Powers off the Microhard chip.
    ///
    /// - Returns: `true` if the command has been sent
    func shutdown() -> Bool

    /// Pairs a Microhard device.
    ///
    /// - Parameters:
    ///   - networkId: device network identifier
    ///   - encryptionKey: pairing encryption key
    ///   - pairingParameters: parameters for device pairing
    ///   - connectionParameters: parameters for device connection
    /// - Returns: `true` if the command has been sent. The command will not be sent, if the pairing or connection
    /// parameters are out of supported values, or if the current `state` does not allow pairing
    /// (see `MicrohardState.canPair`).
    func pairDevice(networkId: String, encryptionKey: String,
                    pairingParameters: MicrohardPairingParameters,
                    connectionParameters: MicrohardConnectionParameters) -> Bool
}

/// :nodoc:
/// Microhard description
public class MicrohardDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = Microhard
    public let uid = PeripheralUid.microhard.rawValue
    public let parent: ComponentDescriptor? = nil
}
