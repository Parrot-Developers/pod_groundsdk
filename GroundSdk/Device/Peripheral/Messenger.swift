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

/// Messenger peripheral interface.
///
/// This component allows to send SMS using the remote device cellular connection, when available.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.messenger)
/// ```
public protocol Messenger: Peripheral {
    /// Requests the remote device to send an SMS through the available cellular connection.
    ///
    /// - Parameters:
    ///   - recipientAddress: address/phone number of the recipient of the SMS to be sent
    ///   - content: text content of the SMS to be sent
    /// - Returns: `true` if the request was successfully sent to the remote device, otherwise `false`
    func sendSms(recipientAddress: String, content: String) -> Bool
}

/// :nodoc:
/// Messenger description
public class MessengerDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = Messenger
    public let uid = PeripheralUid.messenger.rawValue
    public let parent: ComponentDescriptor? = nil
}
