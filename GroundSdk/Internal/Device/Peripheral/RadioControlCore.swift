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

/// RadioControl backend part.
public protocol RadioControlBackend: AnyObject {
    /// Sets the transport used between the remote control and the drone.
    ///
    /// - Parameter transport: the new transport
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(transport: LinkTransport) -> Bool
}

/// Implementation of setting to change the transport used by the remote control - drone link.
class TransportSettingCore: TransportSetting, CustomDebugStringConvertible {

    /// Delegate called when the setting value is changed by setting properties.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes.
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { return timeout.isScheduled }

    /// Supported transports.
    public internal(set) var supportedTransports: Set<LinkTransport> = Set()

    /// Current transport.
    var value: LinkTransport {
        get {
            return _value
        }
        set {
            if _value != newValue && supportedTransports.contains(newValue) {
                if backend(newValue) {
                    let oldValue = _value
                    // value sent to the backend, update setting value and mark it updating
                    _value = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(transport: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }
    /// Current transport (internal value).
    private var _value: LinkTransport = .wifi

    /// Closure to call to change the value.
    private let backend: ((LinkTransport) -> Bool)

    /// Constructor.
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (LinkTransport) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, change the supported transports.
    ///
    /// - Parameter supportedTransports: new supported transports
    func update(supportedTransports newSupportedTransports: Set<LinkTransport>) -> Bool {
        if supportedTransports != newSupportedTransports {
            supportedTransports = newSupportedTransports
            return true
        }
        return false
    }

    /// Called by the backend, change the transport.
    ///
    /// - Parameter transport: new transport
    func update(transport newTransport: LinkTransport) -> Bool {
        if updating || _value != newTransport {
            _value = newTransport
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
        return "value: \(_value) updating: [\(updating)]"
    }
}

/// Extension of TransportSettingCore that implements ObjC API.
extension TransportSettingCore: GSTransportSetting {
    func isTransportSupported(_ transport: LinkTransport) -> Bool {
        return supportedTransports.contains(transport)
    }
}

/// Internal RadioControl peripheral implementation.
public class RadioControlCore: PeripheralCore, RadioControl {

    /// Transport setting
    public var  transportSetting: TransportSetting {
        return _transportSetting
    }
    private var _transportSetting: TransportSettingCore!

    /// Implementation backend
    private unowned let backend: RadioControlBackend

    /// Debug description
    public override var description: String {
        return "RadioControl : transportSetting = \(transportSetting)]"
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: RadioControl backend
    public init(store: ComponentStoreCore, backend: RadioControlBackend) {
        self.backend = backend
        super.init(desc: Peripherals.radioControl, store: store)
        _transportSetting = TransportSettingCore(didChangeDelegate: self, backend: { [unowned self] transport in
            return self.backend.set(transport: transport)})
    }

    /// Sends to remote control the transport used between the remote control and the drone.
    ///
    /// - Parameter transport: new transport
    public func setLinkTransport(_ transport: LinkTransport) {
        _ = backend.set(transport: transport)
    }
}

/// Extension of RadioControlCore that implements ObjC API.
extension RadioControlCore: GSRadioControl {
    public var gsTransportSetting: GSTransportSetting {
        return _transportSetting
    }
}

/// Backend callback methods
extension RadioControlCore {

    /// Sets the transport used between the remote control and the drone.
    ///
    /// - Parameter transport: the transport
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(transport newTransport: LinkTransport) -> RadioControlCore {
        if _transportSetting.update(transport: newTransport) {
            markChanged()
        }
        return self
    }

    /// Sets the supported transports used between the remote control and the drone.
    ///
    /// - Parameter supportedTransports: the supported transports
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(
        supportedTransports newSupportedTransports: Set<LinkTransport>) -> RadioControlCore {
        if _transportSetting.update(supportedTransports: newSupportedTransports) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> RadioControlCore {
        _transportSetting.cancelRollback { markChanged() }
        return self
    }
}
