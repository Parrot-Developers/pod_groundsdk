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

/// A GridResolution of a DTED file.
public struct GridResolution: Equatable {

    /// Latitude spacing of a DTED grid resolution file
    public let latitudeSpacing: Double

    /// Longitude spacing of a DTED grid resolution file
    public let longitudeSpacing: Double

    /// Constructor.
    ///
    /// - Parameters:
    ///   - latitudeSpacing: latitude spacing of a DTED grid resolution file
    ///   - longitudeSpacing: longitude spacing of a DTED grid resolution file
    public init(latitudeSpacing: Double, longitudeSpacing: Double) {
        self.latitudeSpacing = latitudeSpacing
        self.longitudeSpacing = longitudeSpacing
    }
}

/// DTED file in a DTED store.
public class DtedFile: NSObject {

    /// Name of DTED file
    public let name: String

    /// DTED file upload date
    public let uploadDate: Date

    /// Origin of DTED file
    public let origin: CLLocationCoordinate2D

    /// Grid resolution of DTED file
    public let gridResolution: GridResolution

    /// DTED file checksum
    public let checksum: String?

    /// The elevation in meters at the requested coordinates (only in replies to single terrain requests)
    public let elevation: Double?

    /// Custom user data. Client can use this property to store custom data for this item, like it selection state.
    /// This property be kept between updates of a media list reference.
    public var userData: Any?

    /// Constructor.
    ///
    /// - Parameters:
    ///   - name: name of DTED file
    ///   - uploadDate: DTED file upload date
    ///   - origin: Origin of DTED file
    ///   - gridResolution: Grid resolution of DTED fil
    ///   - checksum: DTED file checksum
    ///   - elevation: The elevation in meters at the requested coordinates (only in replies to single terrain requests)
    public init(name: String, uploadDate: Date, origin: CLLocationCoordinate2D,
                gridResolution: GridResolution, checksum: String? = nil, elevation: Double? = nil) {
        self.name = name
        self.uploadDate = uploadDate
        self.origin = origin
        self.gridResolution = gridResolution
        self.checksum = checksum
        self.elevation = elevation
    }
}
