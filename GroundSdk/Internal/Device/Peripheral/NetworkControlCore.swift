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

/// NetworkControl backend part.
public protocol NetworkControlBackend: AnyObject {
    /// Sets routing policy.
    ///
    /// - Parameter policy: the new policy
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(policy: NetworkControlRoutingPolicy) -> Bool

    /// Sets maximum cellular bitrate.
    ///
    /// - Parameter maxCellularBitrate: the new maximum cellular bitrate, in kilobits per second
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(maxCellularBitrate: Int) -> Bool

    /// Sets direct connection mode.
    ///
    /// - Parameter directConnectionMode: the new mode
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(directConnectionMode: NetworkDirectConnectionMode) -> Bool
}

/// Network link details implementation.
public class NetworkControlLinkInfoCore: NetworkControlLinkInfo, Equatable, CustomDebugStringConvertible {

    /// Link type.
    private(set) public var type: NetworkControlLinkType

    /// Link status.
    private(set) public var status: NetworkControlLinkStatus

    /// Link error or `nil`.
    private(set) public var error: NetworkControlLinkError?

    /// Link quality.
    private(set) public var quality: Int?

    /// Constructor.
    ///
    /// - Parameters:
    ///   - type: link type
    ///   - status: link status
    ///   - error: link error
    ///   - quality: link quality
    public init(type: NetworkControlLinkType, status: NetworkControlLinkStatus,
                error: NetworkControlLinkError?, quality: Int?) {
        self.type = type
        self.status = status
        self.error = error
        self.quality = quality
    }

    /// Equatable concordance.
    public static func == (lhs: NetworkControlLinkInfoCore, rhs: NetworkControlLinkInfoCore) -> Bool {
        return lhs.type == rhs.type &&
            lhs.status == rhs.status &&
            lhs.error == rhs.error &&
            lhs.quality == rhs.quality
    }

    /// Debug description.
    public var debugDescription: String {
        "\(type) \(status) \(String(describing: error)) \(quality ?? -1)"
    }
}

/// Internal NetworkControl peripheral implementation.
public class NetworkControlCore: PeripheralCore, NetworkControl {

    /// Network routing policy setting.
    public var routingPolicy: EnumSetting<NetworkControlRoutingPolicy> { _routingPolicy }

    /// Network routing policy setting.
    private var _routingPolicy: EnumSettingCore<NetworkControlRoutingPolicy>!

    /// Current link.
    private(set) public var currentLink: NetworkControlLinkType?

    /// Available links.
    public var links: [NetworkControlLinkInfo] { _links }

    /// Available links.
    private var _links: [NetworkControlLinkInfoCore] = []

    /// Global link quality, in range [0, 4].
    public var linkQuality: Int?

    /// Maximum cellular bitrate, in kilobits per second.
    public var maxCellularBitrate: IntSetting { _maxCellularBitrate }

    /// Maximum cellular bitrate, in kilobits per second.
    private var _maxCellularBitrate: IntSettingCore!

    /// Direct connection mode setting.
    public var directConnection: EnumSetting<NetworkDirectConnectionMode> { _directConnection }

    /// Direct connection mode setting.
    private var _directConnection: EnumSettingCore<NetworkDirectConnectionMode>!

    /// Implementation backend.
    private unowned let backend: NetworkControlBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: network backend
    public init(store: ComponentStoreCore, backend: NetworkControlBackend) {
        self.backend = backend
        super.init(desc: Peripherals.networkControl, store: store)

        _routingPolicy = EnumSettingCore(defaultValue: .automatic, didChangeDelegate: self) { [unowned self] policy in
            self.backend.set(policy: policy)
        }

        _maxCellularBitrate = IntSettingCore(didChangeDelegate: self) { [unowned self] bitrate in
            self.backend.set(maxCellularBitrate: bitrate)
        }

        _directConnection = EnumSettingCore(defaultValue: .legacy, didChangeDelegate: self) { [unowned self] mode in
            self.backend.set(directConnectionMode: mode)
        }
    }
}

/// Backend callback methods.
extension NetworkControlCore {
    /// Updates supported routing policies.
    ///
    /// - Parameter supportedPolicies: new supported routing policies
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(supportedPolicies newSupportedPolicies: Set<NetworkControlRoutingPolicy>) -> NetworkControlCore {
        if _routingPolicy.update(supportedValues: newSupportedPolicies) {
            markChanged()
        }
        return self
    }

    /// Updates routing policy.
    ///
    /// - Parameter policy: new routing policy
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(policy newPolicy: NetworkControlRoutingPolicy) -> NetworkControlCore {
        if _routingPolicy.update(value: newPolicy) {
            markChanged()
        }
        return self
    }

    /// Updates current link.
    ///
    /// - Parameter link: new current link
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(link newLink: NetworkControlLinkType?) -> NetworkControlCore {
        if currentLink != newLink {
            currentLink = newLink
            markChanged()
        }
        return self
    }

    /// Updates available links details.
    ///
    /// - Parameter links: new available links details
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(links newLinks: [NetworkControlLinkInfoCore]) -> NetworkControlCore {
        if _links != newLinks {
            _links = newLinks
            markChanged()
        }
        return self
    }

    /// Updates link quality.
    ///
    /// - Parameter quality: new link quality, in range [0, ']
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(quality newQuality: Int?) -> NetworkControlCore {
        if let newQuality = newQuality {
            let clampedQuality = (0...4).clamp(newQuality)
            if linkQuality != clampedQuality {
                linkQuality = clampedQuality
                markChanged()
            }
        } else if linkQuality != nil {
            linkQuality = nil
            markChanged()
        }
        return self
    }

    /// Updates maximum cellular bitrate, in kilobits per second.
    ///
    /// - Parameter maxCellularBitrate: tuple containing new values, only not nil values are updated
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(maxCellularBitrate newSetting: (min: Int?, value: Int?, max: Int?)) -> NetworkControlCore {
        if _maxCellularBitrate!.update(min: newSetting.min, value: newSetting.value, max: newSetting.max) {
            markChanged()
        }
        return self
    }

    /// Updates supported direct connection modes.
    ///
    /// - Parameter supportedDirectConnectionModes: new supported modes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(supportedDirectConnectionModes newSupportedModes: Set<NetworkDirectConnectionMode>)
    -> NetworkControlCore {
        if _directConnection.update(supportedValues: newSupportedModes) {
            markChanged()
        }
        return self
    }

    /// Updates direct connection mode.
    ///
    /// - Parameter directConnectionMode: new direct connection mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(directConnectionMode newMode: NetworkDirectConnectionMode) -> NetworkControlCore {
        if _directConnection.update(value: newMode) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func cancelSettingsRollback() -> NetworkControlCore {
        _routingPolicy.cancelRollback { markChanged() }
        _maxCellularBitrate.cancelRollback { markChanged() }
        _directConnection.cancelRollback { markChanged() }
        return self
    }
}
