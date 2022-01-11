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

/// Network routing policy setting implementation.
class NetworkControlRoutingSettingCore: NetworkControlRoutingSetting, CustomDebugStringConvertible {

    /// Delegate called when the setting value is changed by setting properties.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes.
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { return timeout.isScheduled }

    /// Supported policies.
    private(set) var supportedPolicies: Set<NetworkControlRoutingPolicy> = []

    /// Routing policy.
    var policy: NetworkControlRoutingPolicy {
        get {
            return _policy
        }
        set {
            if _policy != newValue && supportedPolicies.contains(newValue) {
                if backend(newValue) {
                    let oldValue = _policy
                    // value sent to the backend, update setting value and mark it updating
                    _policy = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(policy: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }
    /// Routing policy.
    private var _policy: NetworkControlRoutingPolicy = .automatic

    /// Closure to call to change the value.
    private let backend: ((NetworkControlRoutingPolicy) -> Bool)

    /// Constructor.
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (NetworkControlRoutingPolicy) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Updates supported policies.
    ///
    /// - Parameter supportedPolicies: new supported policies
    /// - Returns: true if supported policies changed, false otherwise
    func update(supportedPolicies newSupportedPolicies: Set<NetworkControlRoutingPolicy>) -> Bool {
        if supportedPolicies != newSupportedPolicies {
            supportedPolicies = newSupportedPolicies
            return true
        }
        return false
    }

    /// Updates routing policy.
    ///
    /// - Parameter policy: new routing policy
    /// - Returns: true if the setting has been changed, false otherwise
    func update(policy newPolicy: NetworkControlRoutingPolicy) -> Bool {
        if updating || _policy != newPolicy {
            _policy = newPolicy
            timeout.cancel()
            return true
        }
        return false
    }

    /// Cancels any pending rollback.
    ///
    /// - Parameter completionClosure: block that will be called if a rollback was pending
    func cancelRollback(completionClosure: () -> Void) {
        if timeout.isScheduled {
            timeout.cancel()
            completionClosure()
        }
    }

    /// Debug description.
    var debugDescription: String {
        return "policy: \(_policy) supportedPolicies: \(supportedPolicies) updating: \(updating)"
    }
}

/// Network link details implementation.
public class NetworkControlLinkInfoCore: NetworkControlLinkInfo, Equatable, CustomDebugStringConvertible {

    /// Link type.
    private (set) public var type: NetworkControlLinkType

    /// Link status.
    private (set) public var status: NetworkControlLinkStatus

    /// Link error or `nil`.
    private (set) public var error: NetworkControlLinkError?

    /// Link quality.
    private (set) public var quality: Int?

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

/// Direct connection setting implementation.
class NetworkDirectConnectionSettingCore: NetworkDirectConnectionSetting, CustomDebugStringConvertible {

    /// Delegate called when the setting value is changed by setting properties.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes.
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { return timeout.isScheduled }

    /// Supported direct connection modes.
    private(set) var supportedModes: Set<NetworkDirectConnectionMode> = []

    /// Direct connection mode.
    var mode: NetworkDirectConnectionMode {
        get {
            return _mode
        }
        set {
            if _mode != newValue && supportedModes.contains(newValue) {
                if backend(newValue) {
                    let oldValue = _mode
                    // value sent to the backend, update setting value and mark it updating
                    _mode = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(mode: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }

    /// Direct connection mode.
    private var _mode: NetworkDirectConnectionMode = .legacy

    /// Closure to call to change the value.
    private let backend: ((NetworkDirectConnectionMode) -> Bool)

    /// Constructor.
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (NetworkDirectConnectionMode) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Updates supported modes.
    ///
    /// - Parameter supportedModes: new supported policies
    /// - Returns: true if supported modes changed, false otherwise
    func update(supportedModes newSupportedModes: Set<NetworkDirectConnectionMode>) -> Bool {
        if supportedModes != newSupportedModes {
            supportedModes = newSupportedModes
            return true
        }
        return false
    }

    /// Updates direct connection mode.
    ///
    /// - Parameter mode: new mode
    /// - Returns: true if the setting has been changed, false otherwise
    func update(mode newMode: NetworkDirectConnectionMode) -> Bool {
        if updating || _mode != newMode {
            _mode = newMode
            timeout.cancel()
            return true
        }
        return false
    }

    /// Cancels any pending rollback.
    ///
    /// - Parameter completionClosure: block that will be called if a rollback was pending
    func cancelRollback(completionClosure: () -> Void) {
        if timeout.isScheduled {
            timeout.cancel()
            completionClosure()
        }
    }

    /// Debug description.
    var debugDescription: String {
        return "mode: \(_mode) supportedModes: \(supportedModes) updating: \(updating)"
    }
}

/// Internal NetworkControl peripheral implementation.
public class NetworkControlCore: PeripheralCore, NetworkControl {

    /// Network routing policy setting.
    public var routingPolicy: NetworkControlRoutingSetting { _routingPolicy }

    /// Network routing policy setting.
    private var _routingPolicy: NetworkControlRoutingSettingCore!

    /// Current link.
    private (set) public var currentLink: NetworkControlLinkType?

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
    public var directConnection: NetworkDirectConnectionSetting { _directConnection }

    /// Direct connection mode setting.
    private var _directConnection: NetworkDirectConnectionSettingCore!

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

        _routingPolicy = NetworkControlRoutingSettingCore(didChangeDelegate: self) { [unowned self] policy in
            self.backend.set(policy: policy)
        }

        _maxCellularBitrate = IntSettingCore(didChangeDelegate: self) { [unowned self] bitrate in
            self.backend.set(maxCellularBitrate: bitrate)
        }

        _directConnection = NetworkDirectConnectionSettingCore(didChangeDelegate: self) { [unowned self] mode in
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
        if _routingPolicy.update(supportedPolicies: newSupportedPolicies) {
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
        if _routingPolicy.update(policy: newPolicy) {
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
        if _directConnection.update(supportedModes: newSupportedModes) {
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
        if _directConnection.update(mode: newMode) {
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
