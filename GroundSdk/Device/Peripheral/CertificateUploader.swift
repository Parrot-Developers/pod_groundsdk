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

/// Certificate upload state.
public enum CertificateUploadState: CustomStringConvertible {

    /// The certificate upload is in progress.
    case uploading

    /// The certificate upload was successful.
    case success

    /// The certificate upload has failed.
    case failed

    /// The certificate upload has been canceled.
    case canceled

    /// Debug description.
    public var description: String {
        switch self {
        case .uploading:    return "uploading"
        case .success:      return "success"
        case .failed:       return "failed"
        case .canceled:     return "canceled"
        }
    }
}

/// Information about the certificate.
public struct CertificateInfo {

    /// The list of debug features.
    public let debugFeatures: [String]

    /// The list of premium features.
    public let premiumFeatures: [String]

    /// Constructor.
    ///
    /// - Parameters:
    ///   - debugFeatures: list of debug features
    ///   - premiumFeatures: list of premium features
    public init(debugFeatures: [String], premiumFeatures: [String]) {
        self.debugFeatures = debugFeatures
        self.premiumFeatures = premiumFeatures
    }
}

/// Certificate Uploader peripheral interface.
///
/// This peripheral allows to upload certificates to connected devices, in order to unlock new features on the drone.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.certificateUploader)
/// ```
public protocol CertificateUploader: Peripheral {
    /// Latest upload state.
    var state: CertificateUploadState? { get }

    /// Uploads a certificate file to the drone.
    ///
    /// For a successful upload, the drone has to remain in a landed state for the whole upload duration.
    ///
    /// - Parameter certificate: local path of the file to upload
    func upload(certificate filepath: String) -> CancelableCore?

    /// Fetches the signature of the current license certificate installed on the device.
    ///
    /// - Parameters:
    ///   - completion: the completion callback
    ///   - signature: the retrieved signature
    func fetchSignature(completion: @escaping (_ signature: String?) -> Void)

    /// Fetches the information of the current license certificate installed on the drone.
    ///
    /// - Parameters:
    ///   - completion: the completion callback
    ///   - info: the retrieved information
    func fetchInfo(completion: @escaping (_ info: CertificateInfo?) -> Void)
}

/// :nodoc:
/// Certificate Uploader description
public class CertificateUploaderDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = CertificateUploader
    public let uid = PeripheralUid.certificateUploader.rawValue
    public let parent: ComponentDescriptor? = nil
}
