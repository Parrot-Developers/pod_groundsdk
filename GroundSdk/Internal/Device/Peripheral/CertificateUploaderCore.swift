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

/// Certificate Uploader backend part.
public protocol CertificateUploaderBackend: AnyObject {
    /// Uploads a certificate file to the drone.
    ///
    /// When the upload ends, the drone will restart
    ///
    /// - Parameter certificate: local path of the file to upload
    func upload(certificate filepath: String) -> CancelableCore?

    /// Fetches the signature of the current license certificate installed on the drone.
    ///
    /// - Parameters:
    ///   - completion: the completion callback (called on the main thread)
    ///   - signature: the retrieved signature
    func fetchSignature(completion: @escaping (_ signature: String?) -> Void)

    /// Fetches the information of the current license certificate installed on the drone.
    ///
    /// - Parameters:
    ///   - completion: the completion callback (called on the main thread)
    ///   - info: the retrieved information
    func fetchInfo(completion: @escaping (_ info: CertificateInfo?) -> Void)
}

/// Internal certificate uploader peripheral implementation
public class CertificateUploaderCore: PeripheralCore, CertificateUploader {

    private(set) public var state: CertificateUploadState?

    /// Implementation backend.
    private unowned let backend: CertificateUploaderBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: Certificate Uploader backend
    public init(store: ComponentStoreCore, backend: CertificateUploaderBackend) {
        self.backend = backend
        super.init(desc: Peripherals.certificateUploader, store: store)
    }

    public func upload(certificate filepath: String) -> CancelableCore? {
        return backend.upload(certificate: filepath)
    }

    public func fetchSignature(completion: @escaping (String?) -> Void) {
        backend.fetchSignature(completion: completion)
    }

    public func fetchInfo(completion: @escaping (CertificateInfo?) -> Void) {
        backend.fetchInfo(completion: completion)
    }
}

/// Backend callback methods.
extension CertificateUploaderCore {
    /// Updates the upload state.
    ///
    /// - Parameter state: new upload state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(state newValue: CertificateUploadState?) -> CertificateUploaderCore {
        if state != newValue {
            state = newValue
            markChanged()
        }
        return self
    }
}
