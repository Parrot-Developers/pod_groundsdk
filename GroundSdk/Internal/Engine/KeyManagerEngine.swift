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

/// Engine that manages keys used to decrypt some drone logs.
class KeyManagerEngine: EngineBaseCore {
    /// Key manager utility
    private var keyManagerUtility: KeyManagerCoreImpl!

    /// Public tag used to save or get the key.
    let publicTag = "KeyManager-private".data(using: .utf8)!

    /// Private tag used to save or get the key.
    let privateTag = "KeyManager-public".data(using: .utf8)!

    /// Constructor
    ///
    /// - Parameter enginesController: engines controller
    public required init(enginesController: EnginesControllerCore) {
        keyManagerUtility = KeyManagerCoreImpl()

        super.init(enginesController: enginesController)
        publishUtility(keyManagerUtility)
    }

    public override func startEngine() {
        checkExistingKey() ? getExistingKey() : createKey()
        ULog.d(.keyManagerTag, "key \(String(describing: keyManagerUtility.publicKey))")
    }

    /// Check if the flight log key has already been registered
    ///
    /// - Returns: `true` if the key is already registered, `false` otherwise
    public func checkExistingKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: privateTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Gets the existing  key
    ///
    /// - Parameter type: the type of key
    /// - Returns: a sec key and its base 64 equivalent if found, `nil` otherwise
    private func getKey(type: CFString, tag: Data) -> (Data, String)? {
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: type,
            kSecReturnRef as String: true
        ]

        var keyItem: CFTypeRef?
        let status = SecItemCopyMatching(keyQuery as CFDictionary, &keyItem)

        guard status == errSecSuccess, let key = keyItem else {
            return nil
        }

        var error: Unmanaged<CFError>?
        guard let keyData = SecKeyCopyExternalRepresentation(key as! SecKey, &error) as Data? else {
            // should not happen since a checkExistingKey() has been called at true.
            return nil
        }

        return (keyData, keyData.base64EncodedString())
    }

    /// Gets the existing key
    private func getExistingKey() {
        if let publicKeys = getKey(type: kSecAttrKeyClassPublic, tag: publicTag) {
            keyManagerUtility.publicKey = publicKeys.1
        }
        if let privateKeys = getKey(type: kSecAttrKeyClassPrivate, tag: privateTag) {
            keyManagerUtility.privateKeyData = privateKeys.0
            keyManagerUtility.privateKey = privateKeys.1

        }
    }

    /// Creates the private and public key
    public func createKey() {
        let attributes: [String: Any] = [
            kSecAttrType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: true,
                                            kSecAttrApplicationTag as String: privateTag],
            kSecPublicKeyAttrs as String: [kSecAttrIsPermanent as String: true,
                                            kSecAttrApplicationTag as String: publicTag]
        ]
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            ULog.e(.keyManagerTag, "Failed to create private key \(error.debugDescription)")
            return
        }

        guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else {
            ULog.e(.keyManagerTag, "Failed to create data private key \(error.debugDescription)")
            return
        }

        // Convert in Base64
        keyManagerUtility.privateKey = privateKeyData.base64EncodedString()

        keyManagerUtility.privateKeyData = privateKeyData

        let publicKey = SecKeyCopyPublicKey(privateKey)
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey!, &error) as Data? else {
            ULog.e(.keyManagerTag, "Failed to create public key \(error.debugDescription)")
            return
        }

        // Convert in Base64
        keyManagerUtility.publicKey = publicKeyData.base64EncodedString()
    }
}
