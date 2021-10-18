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

/// Secure element backend
public protocol SecureElementBackend: AnyObject {
    /// Requests a challenge signature to the drone.
    ///
    /// - Parameter challenge: the challenge to send to the drone
    func sign(challenge: String, with operation: SecureElementSignatureOperation)

    /// Cancels ongoing request.
    func cancel()
}

/// Internal implementation of the SecureElement
public class SecureElementCore: PeripheralCore, SecureElement {

    public private(set) var challengeRequestState: SecureElementChallengeSigningState?

    public func sign(challenge: String, with operation: SecureElementSignatureOperation) {
        if challengeRequestState != .processing(challenge: challenge) {
            doSign(challenge: challenge, with: operation)
        }
    }

    /// Implementation backend
    private unowned let backend: SecureElementBackend

    /// Constructor
    ///
    /// - Parameters :
    ///    - store: store where this peripheral will be stored
    ///    - backend: Secure element backend
    public init(store: ComponentStoreCore, backend: SecureElementBackend) {
        self.backend = backend
        self.certificateForImagesState = CertificateImagesDownloaderState()
        self.certificateImagesStorage = CertificateImagesStorageCoreImpl()
        super.init(desc: Peripherals.secureElement, store: store)
    }

    /// Private signature implementation
    private func doSign(challenge: String, with operation: SecureElementSignatureOperation) {
        backend.sign(challenge: challenge, with: operation)
    }

    /// Current download state.
    private(set) public var certificateForImagesState: CertificateImagesDownloaderState

    /// Certificates storage
    private(set) public var certificateImagesStorage: CertificateImagesStorageCore

    /// Certificate used to validate image signature.
    private(set) public var certificateForImages: URL?
}

/// Backend callback methods
extension SecureElementCore {

    /// Updates the challenge state.
    ///
    /// - Parameter newChallengeState: the new challenge state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(newChallengeState: SecureElementChallengeSigningState) -> SecureElementCore {
        if challengeRequestState != newChallengeState {
            challengeRequestState = newChallengeState
            markChanged()
        }
        return self
    }

    /// Updates certificate download completion status.
    ///
    /// - Parameter completionStatus: new completion status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(certificateCompletionStatus: CertificateDownloadCompletionStatus)
        -> SecureElementCore {
            if certificateForImagesState.status != certificateCompletionStatus {
                certificateForImagesState.status = certificateCompletionStatus
                markChanged()
            }
        return self
    }

    /// Updates certificate url.
    ///
    /// - Parameter certificateForImages: new certificate URL
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(certificateForImages: URL)
        -> SecureElementCore {
        if self.certificateForImages != certificateForImages {
            self.certificateForImages = certificateForImages
                markChanged()
            }
        return self
    }
}
