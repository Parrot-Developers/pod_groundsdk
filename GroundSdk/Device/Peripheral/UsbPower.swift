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

/// UBS-C connector type.
public enum UsbConnectorType: String, CustomStringConvertible, CaseIterable {
    /// The battery USB-C connector
    case battery
    /// The body USB-C connector
    case body

    /// Debug description.
    public var description: String { return rawValue }
}

/// Usb power peripheral interface.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.usbPower)
/// ```
public protocol UsbPower: Peripheral {

    /// List of supported USB-C connector types.
    ///
    /// `empty` if unavailable.
    var supportedTypes: Set<UsbConnectorType> { get }

    /// Tells whether the power is enabled or not on the given USB-C connector type.
    ///
    /// - Parameter type: the USB-C connector type
    /// - Returns `true` if the power is on, `false` if off, `nil` if unavailable
    func isEnabled(type: UsbConnectorType) -> Bool?

    /// Enables or disables the power of the given USB-C connector type.
    ///
    /// - Parameters:
    ///    - type : the USB-C connector type
    ///    - value: `true` to enable power, `false` to disable it
    func enable(type: UsbConnectorType, value: Bool) -> Bool

}

/// :nodoc:
/// USB power peripheral description.
public class UsbPowerDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = UsbPower
    public let uid = PeripheralUid.usbPower.rawValue
    public let parent: ComponentDescriptor? = nil
}
