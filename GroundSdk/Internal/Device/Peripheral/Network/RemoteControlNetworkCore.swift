// Copyright (C) 2026 Parrot Drones SAS
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

/// RemoteControlNetwork backend part.
public protocol RemoteControlNetworkBackend: AnyObject {

    /// Sets ethernet IP configuration.
    ///
    /// - Parameter ethernetIpConfig: the new ethernet IP configuration
    /// - Returns: `true` if the command has been sent, `false` if not connected and the value has been changed immediately
    func set(ethernetIpConfig: IpConfig) -> Bool
}

/// Internal RemoteControlNetwork peripheral implementation.
public class RemoteControlNetworkCore: PeripheralCore, RemoteControlNetwork {

    /// Ethernet IP config.
    private var _ethernetIpConfig: IpConfigSettingCore?

    public var ethernetIpConfig: IpConfigSetting? {
        return _ethernetIpConfig
    }

    /// Implementation backend.
    private unowned let backend: RemoteControlNetworkBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: remote control network backend
    public init(store: ComponentStoreCore, backend: RemoteControlNetworkBackend) {
        self.backend = backend
        super.init(desc: Peripherals.remoteControlNetwork, store: store)
    }

    /// Creates the IP config setting if it doesn't exist yet and returns it.
    public func ensureEthernetIpConfig() -> IpConfigSettingCore {
        if _ethernetIpConfig == nil {
            _ethernetIpConfig = IpConfigSettingCore(didChangeDelegate: self) { [unowned self] ipConfig in
                return self.backend.set(ethernetIpConfig: ipConfig)
            }
            markChanged()
        }
        return _ethernetIpConfig!
    }
}

/// Backend callback methods.
extension RemoteControlNetworkCore {

    /// Updates the ethernet IP configuration.
    ///
    /// - Parameter ethernetIpConfig: new IP configuration
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(ethernetIpConfig newConfig: IpConfig) -> RemoteControlNetworkCore {
        if ensureEthernetIpConfig().update(config: newConfig) {
            markChanged()
        }
        return self
    }

    /// Clears the ethernet IP configuration.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func clearEthernetIpConfig() -> RemoteControlNetworkCore {
        if _ethernetIpConfig != nil {
            _ethernetIpConfig = nil
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func cancelSettingsRollback() -> RemoteControlNetworkCore {
        _ethernetIpConfig?.cancelRollback { markChanged() }
        return self
    }
}
