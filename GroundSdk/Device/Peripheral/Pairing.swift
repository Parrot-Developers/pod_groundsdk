// Copyright (C) 2023 Parrot Drones SAS
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
import CoreLocation

/// The device paired to the remote control.
public struct PairedDevice: Equatable {
    /// Drone uid
    public let uid: String

    /// Drone model
    public let droneModel: Drone.Model

    /// Constructor.
    ///
    /// - Parameters:
    ///   - uid: uid of the drone
    ///   - droneModel: the drone model
    public init(uid: String, droneModel: Drone.Model) {
        self.uid = uid
        self.droneModel = droneModel
    }
}

/// Device pairing failure reason
public enum PairingFailureReason {

    /// Trying to pair but the controller radio is not ready.
    case radioNotReady

    /// Controller is in remote antenna mode without a remote antenna connected.
    case noRemoteAntenna
}

/// Pairing peripheral interface for remote controls.
///
/// This component reports pairing events.
///
/// This peripheral can be obtained from a remote control using:
/// ```
/// device.getPeripheral(Peripherals.pairing)
/// ```
public protocol Pairing: Peripheral {
    /// Latest paired device.
    ///
    /// This property is *transient*: it will be set once when pairing succeeds, and then immediately back to `nil`.
    var pairedDevice: PairedDevice? { get }

    /// Latest device pairing failure reason.
    ///
    /// This property is *transient*: it will be set once when pairing fails, and then immediately back to `nil`.
    var failureReason: PairingFailureReason? { get }
}

/// :nodoc:
/// Pairing periheral descriptor
public class PairingDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = Pairing
    public let uid = PeripheralUid.pairing.rawValue
    public let parent: ComponentDescriptor? = nil
}
