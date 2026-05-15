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

/// Discrovered service on the drone.
public struct DiscoveredService: Encodable {

    /// Name of service.
    public var name: String

    /// Type of service.
    public var type: String

    /// Domain name.
    public var domain: String

    /// IP address.
    public var address: String

    /// Port number.
    public var port: Int

    /// Array of TXT records as defined in
    /// `[RFC 6763 section-6](https://datatracker.ietf.org/doc/html/rfc6763#section-6)`.
    public var recordData: [String]

    /// Constructor
    ///
    /// - Parameter serviceDiscovery: drone service discovery
    public init(from serviceDiscovery: ArsdkServiceDiscovery) {
           self.name = serviceDiscovery.name
           self.type = serviceDiscovery.type
           self.domain = serviceDiscovery.domain
           self.address = serviceDiscovery.address
           self.port = serviceDiscovery.port
           self.recordData = serviceDiscovery.recordData
       }
}
