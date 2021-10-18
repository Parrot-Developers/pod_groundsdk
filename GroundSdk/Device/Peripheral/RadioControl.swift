// Copyright (C) 2019 Parrot Drones SAS
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

/// Transport used by the remote control - drone link.
@objc(GSLinkTransport)
public enum LinkTransport: Int, CustomStringConvertible {

    /// Remote control - drone link uses WiFi transport.
    case wifi

    /// Remote control - drone link uses radio transport.
    case radio

    /// Debug description.
    public var description: String {
        switch self {
        case .wifi:
            return "wifi"
        case .radio:
            return "radio"
        }
    }

    /// Set containing all possible transports.
    public static let allCases: Set<LinkTransport> = [.wifi, .radio]
}

/// Peripheral managing the transport used between the remote control and the drone.
///
/// This peripheral can be obtained from a remote control using:
/// ```
/// remoteControl.getPeripheral(Peripherals.radioControl)
/// ```
public protocol RadioControl: Peripheral {
    /// Transport setting.
    var transportSetting: TransportSetting { get }
}

/// Peripheral managing the transport used between the remote control and the drone.
///
/// - Note: this protocol is for Objective-C compatibility only.
@objc public protocol GSRadioControl: Peripheral {
    /// Transport setting.
    @objc(transportSetting)
    var gsTransportSetting: GSTransportSetting { get }
}

/// Setting to change the transport used by the remote control - drone link.
public protocol TransportSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Current transport.
    var value: LinkTransport { get set }

    /// Supported transports.
    var supportedTransports: Set<LinkTransport> { get }
}

/// Setting to change the transport used by the remote control - drone link.
///
/// - Note: this protocol is for Objective-C compatibility only.
@objc public protocol GSTransportSetting {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Current transport setting.
    var value: LinkTransport { get set }

    /// Tells whether a given transport is supported.
    ///
    /// - Parameter transport: the transport to query
    /// - Returns: `true` if the transport is supported, `false` otherwise
    func isTransportSupported(_ transport: LinkTransport) -> Bool
}

/// :nodoc:
/// RadioControl description.
@objc(GSRadioControlDesc)
public class RadioControlDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = RadioControl
    public let uid = PeripheralUid.radioControl.rawValue
    public let parent: ComponentDescriptor? = nil
}
