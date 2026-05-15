// Copyright (C) 20230 Parrot Drones SAS
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
import CoreLocation

/// Add an opaque reference to backend dted in dted file
public class DtedFileCore: DtedFile {

    /// Backend data
    public let backendData: Any?

    /// Url used to stream the file from the device, or nil if not available
    let streamUrl: String?

    /// Constructor
    ///
    /// - Parameters:
    ///   - uid: file unique identifier
    ///   - name: file name
    ///   - uploadDate: file upload date
    ///   - origin: file origin coordinate
    ///   - gridResolution: file grid resolution
    ///   - checksum: file checksum
    ///   - elevation: the elevation requested
    ///   - streamUrl: url used to stream the file from the device
    ///   - backendData: backend media data
    public init(name: String, uploadDate: Date, origin: CLLocationCoordinate2D,
                gridResolution: GridResolution, checksum: String?, elevation: Double? = nil,
                streamUrl: String? = nil, backendData: Any? = nil) {
        self.streamUrl = streamUrl
        self.backendData = backendData
        super.init(name: name, uploadDate: uploadDate, origin: origin,
                   gridResolution: gridResolution, checksum: checksum, elevation: elevation)

    }
}
