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

/// Routing policy.
public enum NetworkControlRoutingPolicy: String, CustomStringConvertible, CaseIterable {
    /// Broadcast to all links.
    case all
    /// Use wlan link if available, otherwise broadcast.
    case wlan
    /// Use cellular link if available, otherwise broadcast.
    case cellular
    /// Select best link.
    case automatic

    /// Debug description.
    public var description: String { rawValue }
}

/// Setting to control network routing.
public protocol NetworkControlRoutingSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported routing policies.
    var supportedPolicies: Set<NetworkControlRoutingPolicy> { get }

    /// Routing policy.
    var policy: NetworkControlRoutingPolicy { get set }
}

/// Network link type.
public enum NetworkControlLinkType: String, CustomStringConvertible, CaseIterable {
    /// Wi-Fi interface.
    case wlan
    /// Cellular interface.
    case cellular

    /// Debug description.
    public var description: String { rawValue }
}

/// Network link status.
public enum NetworkControlLinkStatus: String, CustomStringConvertible, CaseIterable {
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
    case error

    /// Debug description.
    public var description: String { rawValue }
}

/// Network link error.
public enum NetworkControlLinkError: String, CustomStringConvertible, CaseIterable {
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

/// Network link details.
public protocol NetworkControlLinkInfo: AnyObject {
    /// Network link type.
    var type: NetworkControlLinkType { get }

    /// Network link status.
    var status: NetworkControlLinkStatus { get }

    /// Network link error when `status` is `error`, `nil` otherwise.
    var error: NetworkControlLinkError? { get }

    /// Network link quality, in range [0, 4].
    ///
    /// `0` for lowest quality and `4` for highest quality.
    var quality: Int? { get }

    /// Debug description.
    var debugDescription: String { get }
}

/// Direct connection mode (Wifi or USB).
public enum NetworkDirectConnectionMode: String, CustomStringConvertible, CaseIterable {
    /// Legacy mode: secure connection is not mandatory, Wifi and USB connections can be established in any way.
    case legacy
    /// Only secure connections are authorized, a remote control should be used to establish the connection via Wifi,
    /// and a certificate is necessary to establish it via USB.
    case secure

    /// Debug description.
    public var description: String { rawValue }
}

/// Direct connection setting.
public protocol NetworkDirectConnectionSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported direct connection modes.
    var supportedModes: Set<NetworkDirectConnectionMode> { get }

    /// Direct connection mode.
    var mode: NetworkDirectConnectionMode { get set }
}

/// Network peripheral interface.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.networkControl)
/// ```
public protocol NetworkControl: Peripheral {
    /// Network routing policy setting.
    var routingPolicy: NetworkControlRoutingSetting { get }

    /// Links details.
    var links: [NetworkControlLinkInfo] { get }

    /// Current link, `nil` if `routingPolicy.policy` is `broadcast` or if unavailable.
    var currentLink: NetworkControlLinkType? { get }

    /// Global link quality, in range [0, 4].
    ///
    /// `0` for lowest quality and `4` for highest quality.
    var linkQuality: Int? { get }

    /// Maximum cellular bitrate, in kilobits per second.
    var maxCellularBitrate: IntSetting { get }

    /// Direct connection mode setting.
    var directConnection: NetworkDirectConnectionSetting { get }
}

/// :nodoc:
/// Network peripheral description.
public class NetworkControlDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = NetworkControl
    public let uid = PeripheralUid.networkControl.rawValue
    public let parent: ComponentDescriptor? = nil
}
