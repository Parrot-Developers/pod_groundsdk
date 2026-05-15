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
//    OF THE USE OF TH

/// Utility interface providing access to keys used for drone logs encryption.
///
/// This utility is always available and can be safely requested after engine startup using
/// `UtilityCoreRegistry.getUtility(desc:)` it can be forced unwrapped.
public protocol KeyManagerCore: UtilityCore {

    /// Public key in base64.
    var publicKey: String? { get }

    /// Private key.
    var privateKeyData: Data? { get }

    /// Private key in base64.
    var privateKey: String? { get }
}

/// Implementation of KeyManager utility.
class KeyManagerCoreImpl: KeyManagerCore {

    let desc: UtilityCoreDescriptor = Utilities.keyManager

    /// Public key in base64.
    var publicKey: String?

    /// Private key.
    var privateKeyData: Data?

    /// Private key in base64.
    var privateKey: String?
}

/// Description of the flight log key manager utility
public class KeyManagerCoreDesc: NSObject, UtilityCoreApiDescriptor {
    public typealias ApiProtocol = KeyManagerCore
    public let uid = UtilityUid.keyManager.rawValue
}
