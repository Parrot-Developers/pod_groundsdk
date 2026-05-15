// Copyright (C) 2025 Parrot Drones SAS
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

/// USB power backend part.
public protocol UsbPowerBackend: AnyObject {
    /// Enables or disables the power of the given USB-C connector type.
    ///
    /// - Parameters:
    ///    - type : the USB-C connector type
    ///    - value: `true` to enable power, `false` to disable it
    func enable(type: UsbConnectorType, value: Bool) -> Bool
}

/// Internal USB power peripheral implementation
public class UsbPowerCore: PeripheralCore, UsbPower {

    public private(set) var supportedTypes: Set<UsbConnectorType> = []

    /// Power state of each connector type.
    private var states = [UsbConnectorType: Bool]()

    /// Implementation backend
    private unowned let backend: UsbPowerBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: USB power backend
    public init(store: ComponentStoreCore, backend: UsbPowerBackend) {
        self.backend = backend
        super.init(desc: Peripherals.usbPower, store: store)
    }

    public func isEnabled(type: UsbConnectorType) -> Bool? {
        return states[type]
    }

    public func enable(type: UsbConnectorType, value: Bool) -> Bool {
        return states[type] != value && supportedTypes.contains(type) && backend.enable(type: type, value: value)
    }

    /// Resets the list telling if a USB-C connector is enabled or not.
    public func resetStates() {
        states.removeAll()
    }

    /// Updates the supported USB-C connector types.
    ///
    /// - Parameter type: the set of supported USB-C connector types
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedTypes newValue: Set<UsbConnectorType>) -> UsbPowerCore {
        if supportedTypes != newValue {
            supportedTypes = newValue
            markChanged()
        }
        return self
    }

    /// Updates the power state of a connector type.
    ///
    /// - Parameters:
    ///   - type: the USB-C connector type
    ///   - state: the new power state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(type: UsbConnectorType, state newValue: Bool) -> UsbPowerCore {
        if states[type] != newValue {
            states.updateValue(newValue, forKey: type)
            markChanged()
        }
        return self
    }
}
