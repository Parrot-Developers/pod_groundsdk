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

/// Utility protocol allowing to access certificates for images engine internal storage.
///
/// This mainly allows to query the location where certificateImages files should be stored and
/// to notify the engine when new certificateImages have been downloaded.
public protocol CertificateImagesStorageCore: UtilityCore {

    /// Directory where new certificate files may be downloaded.
    ///
    /// Inside this directory, certificateImages downloaders may create
    /// temporary folders, that have a `.tmp` suffix to their name.
    var workDir: URL { get }
}

/// Implementation of the `CertificateImagesStorage` utility.
class CertificateImagesStorageCoreImpl: CertificateImagesStorageCore {

    let desc: UtilityCoreDescriptor = Utilities.certificateImagesStorage

    var workDir: URL

    /// Constructor
    init() {
        let fileManager = FileManager.default
        let documentPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.workDir = documentPath.appendingPathComponent("certificates")
    }
}

/// Certificate images storage utility description
public class CertificateImagesStorageCoreDesc: NSObject, UtilityCoreApiDescriptor {
    public typealias ApiProtocol = CertificateImagesStorageCore
    public let uid = UtilityUid.certificateImagesStorage.rawValue
}
