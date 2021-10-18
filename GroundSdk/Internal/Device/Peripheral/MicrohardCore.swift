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

/// Microhard backend part.
public protocol MicrohardBackend: AnyObject {
    /// Powers on the Microhard chip.
    ///
    /// - Returns: `true` if the command has been sent
    func powerOn() -> Bool

    /// Powers off the Microhard chip.
    ///
    /// - Returns: `true` if the command has been sent
    func shutdown() -> Bool

    /// Sends command to pair a device.
    ///
    /// - Parameters:
    ///   - networkId: network identifier
    ///   - encryptionKey: encryption key
    ///   - pairingParameters: parameters for device pairing
    ///   - connectionParameters: parameters for device connection
    /// - Returns: `true` if the command has been sent
    func pairDevice(networkId: String, encryptionKey: String,
                    pairingParameters: MicrohardPairingParameters,
                    connectionParameters: MicrohardConnectionParameters) -> Bool
}

/// Internal Microhard peripheral implementation.
public class MicrohardCore: PeripheralCore, Microhard {

    private(set) public var state = MicrohardState.offline

    private(set) public var pairingStatus: MicrohardPairingStatus?

    private(set) public var supportedChannelRange: ClosedRange<UInt> = 0...0

    private(set) public var supportedPowerRange: ClosedRange<UInt> = 0...0

    private(set) public var supportedBandwidths = Set<MicrohardBandwidth>()

    private(set) public var supportedEncryptions = Set<MicrohardEncryption>()

    /// Implementation backend.
    private unowned let backend: MicrohardBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: Microhard backend
    public init(store: ComponentStoreCore, backend: MicrohardBackend) {
        self.backend = backend
        super.init(desc: Peripherals.microhard, store: store)
    }

    public func powerOn() -> Bool {
        state == .offline && backend.powerOn()
    }

    public func shutdown() -> Bool {
        state != .offline && backend.shutdown()
    }

    public func pairDevice(networkId: String, encryptionKey: String,
                           pairingParameters: MicrohardPairingParameters,
                           connectionParameters: MicrohardConnectionParameters) -> Bool {
        if supportedChannelRange.contains(pairingParameters.channel)
            && supportedPowerRange.contains(pairingParameters.power)
            && supportedBandwidths.contains(pairingParameters.bandwidth)
            && supportedEncryptions.contains(pairingParameters.encryption)
            && supportedChannelRange.contains(connectionParameters.channel)
            && supportedPowerRange.contains(connectionParameters.power)
            && supportedBandwidths.contains(connectionParameters.bandwidth) {
            return backend.pairDevice(networkId: networkId, encryptionKey: encryptionKey,
                                      pairingParameters: pairingParameters,
                                      connectionParameters: connectionParameters)
        } else {
            // invalid parameters
            return false
        }
    }
}

/// Extension for functions called by backend.
extension MicrohardCore {
    /// Updates Microhard sate.
    ///
    /// - Parameter state: new state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(state newState: MicrohardState) -> MicrohardCore {
        if state != newState {
            state = newState
            markChanged()
        }
        return self
    }

    /// Updates pairing status.
    ///
    /// - Parameter pairingStatus: new pairing status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(pairingStatus newPairingState: MicrohardPairingStatus?) -> MicrohardCore {
        if pairingStatus != newPairingState {
            pairingStatus = newPairingState
            markChanged()
        }
        return self
    }

    /// Updates supported channel range.
    ///
    /// - Parameter supportedChannelRange: new supported channel range
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(supportedChannelRange newSupportedChannelRange: ClosedRange<UInt>) -> MicrohardCore {
        if supportedChannelRange != newSupportedChannelRange {
            supportedChannelRange = newSupportedChannelRange
            markChanged()
        }
        return self
    }

    /// Updates supported power range.
    ///
    /// - Parameter supportedPowerRange: new supported power range, in dBm
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(supportedPowerRange newSupportedPowerRange: ClosedRange<UInt>) -> MicrohardCore {
        if supportedPowerRange != newSupportedPowerRange {
            supportedPowerRange = newSupportedPowerRange
            markChanged()
        }
        return self
    }

    /// Updates supported bandwidths.
    ///
    /// - Parameter supportedBandwidths: new supported bandwidths
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(supportedBandwidths newSupportedBandwidths: Set<MicrohardBandwidth>) -> MicrohardCore {
        if supportedBandwidths != newSupportedBandwidths {
            supportedBandwidths = newSupportedBandwidths
            markChanged()
        }
        return self
    }

    /// Updates supported encryptions.
    ///
    /// - Parameter supportedEncryptions: new supported encryptions
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(supportedEncryptions newSupportedEncryptions: Set<MicrohardEncryption>) -> MicrohardCore {
        if supportedEncryptions != newSupportedEncryptions {
            supportedEncryptions = newSupportedEncryptions
            markChanged()
        }
        return self
    }
}
