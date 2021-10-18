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

/// Operation for challenge signature
public enum SecureElementSignatureOperation: String, CustomStringConvertible, CaseIterable {
    /// Associate operation.
    case associate
    /// Unpair all operation.
    case unpair_all

    /// Debug description.
    public var description: String { return rawValue }
}

/// Challenge request state.
public enum SecureElementChallengeSigningState: Equatable, CustomStringConvertible {
    /// Challenge request is ongoing.
    case processing(challenge: String)

    /// Challenge request succeed.
    case success(challenge: String, token: String)

    /// Challenge request failed.
    case failure(challenge: String)

    /// Debug description.
    public var description: String {
        switch self {
        case .processing(challenge: let challenge):
            return "Processing challenge: \(challenge)"
        case .success(challenge: let challenge, token: let token):
            return "Success challenge: \(challenge), token: \(token)"
        case .failure(challenge: let challenge):
            return "Failed challenge: \(challenge)"
        }
    }

    /// Equatable.
    static public func == (lhs: SecureElementChallengeSigningState, rhs: SecureElementChallengeSigningState) -> Bool {
        switch (lhs, rhs) {
        case (let .processing(challengeL), let .processing(challengeR)):
            return challengeL == challengeR
        case (let .success(challengeL, tokenL), let .success(challengeR, tokenR)):
            return challengeL == challengeR && tokenL == tokenR
        case (let .failure(challengeL), let .failure(challengeR)):
            return challengeL == challengeR
        default:
            return false
        }
    }
}

/// Completion status of certificate download.
public enum CertificateDownloadCompletionStatus: Int, CustomStringConvertible {

    /// No certificate for images download in progress.
    case none

    /// Certificate for images download has completed successfully.
    case success

    /// Certificate for images download has started.
    case started

    /// Certificate for images download has failed.
    case failed

    /// Debug description.
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .success:
            return "success"
        case .started:
            return "started"
        case .failed:
            return "failed"
        }
    }
}

/// State of the certificate for images downloader.
public class CertificateImagesDownloaderState: NSObject {
    /// Current completion status of the CertificateImages downloader.
    ///
    /// The completion status changes to either `.failed` or `.success` when the download failed or
    /// completes successfully, then remains in this state until drone disconnect ,
    /// where it switches back to `.none`.
    public internal(set) var status: CertificateDownloadCompletionStatus

    internal init(status: CertificateDownloadCompletionStatus = .none, downloadedCount: Int = 0) {
        self.status = status
        super.init()
    }
}

/// SecureElement peripheral.
///
/// This peripheral allows you to use SecureElement features.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.secureElement)
/// ```
public protocol SecureElement: Peripheral {
    /// Challenge request state, or `nil` if no challenge request was sent yet.
    var challengeRequestState: SecureElementChallengeSigningState? { get }

    /// Sends a challenge signature request to connected device.
    /// Challenge request state and result is provided by challengeRequestState.
    /// A challenge request can be sent only when there is no request currently started.
    func sign(challenge: String, with operation: SecureElementSignatureOperation)

    /// Certificate download state.
    var certificateForImagesState: CertificateImagesDownloaderState { get }

    /// Certificate used to validate image signature.
    var certificateForImages: URL? { get }
}

/// :nodoc:
/// SecureElement description
public class SecureElementDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = SecureElement
    public let uid = PeripheralUid.secureElement.rawValue
    public let parent: ComponentDescriptor? = nil
}
