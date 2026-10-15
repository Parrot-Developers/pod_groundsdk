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

/// Backend interface used by IpConfigSettingCore to apply changes.
public protocol IpConfigSettingBackend: AnyObject {
    /// Sets the Ethernet IP configuration.
    /// - Parameter config: new IP configuration to apply
    /// - Returns: true if the request was sent, false otherwise
    func setEthernetIpConfig(_ config: IpConfig) -> Bool
}

/// Core implementation of IpConfigSetting, following SettingCore pattern with rollback/timeout.
public final class IpConfigSettingCore: IpConfigSetting, CustomDebugStringConvertible {

    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object (internal for testing)
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    public var updating: Bool { return timeout.isScheduled }

    /// Current IP configuration value
    public var currentConfig: IpConfig = .automatic

    /// Closure to call to change the value on backend
    private let backend: (IpConfig) -> Bool

    /// Constructor
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    public init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (IpConfig) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Sets the IP configuration to automatic (DHCP).
    public func setAutomatic() {
        sendIpConfig(.automatic)
    }

    /// Sets the IP configuration to static.
    /// - Parameters:
    ///   - address: IP address
    ///   - mask: subnet mask
    ///   - gateway: optional gateway address
    public func setStatic(address: String, mask: String, gateway: String?) {
        sendIpConfig(.static(address: address, mask: mask, gateway: gateway))
    }

    /// Sends the new IP configuration setting to backend with rollback scheduling.
    /// - Parameter config: new IP configuration
    private func sendIpConfig(_ config: IpConfig) {
        guard config != currentConfig else { return }
        let rollbackConfig = currentConfig
        if backend(config) {
            currentConfig = config
            timeout.schedule { [weak self] in
                if let self = self, self.update(config: rollbackConfig) {
                    self.didChangeDelegate.userDidChangeSetting()
                }
            }
            didChangeDelegate.userDidChangeSetting()
        }
    }

    /// Called by the backend, updates the IP configuration.
    /// - Parameter config: new IP configuration
    /// - Returns: self to allow call chaining
    @discardableResult
    public func update(config: IpConfig) -> Bool {
        if updating || currentConfig != config {
            currentConfig = config
            timeout.cancel()
            return true
        }
        return false
    }

    /// Cancels any pending rollback.
    public func cancelRollback(completionClosure: () -> Void) {
        if timeout.isScheduled {
            timeout.cancel()
            completionClosure()
        }
    }

    /// Debug description
    public var debugDescription: String {
        return "IpConfig: \(String(describing: currentConfig)) updating: [\(updating)]"
    }
}
