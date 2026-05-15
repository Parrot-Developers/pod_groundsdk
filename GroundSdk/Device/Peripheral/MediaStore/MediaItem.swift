// Copyright (C) 2019 Parrot Drones SAS
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

/// Media item in a media store.
public class MediaItem: NSObject {
    /// Type of media.
    public enum MediaType: Int, CustomStringConvertible {
        /// Media is a photo.
        case photo
        /// Media is a video.
        case video

        /// Debug description.
        public var description: String {
            switch self {
            case .photo:
                return "photo"
            case .video:
                return "video"
            }
        }
    }

    /// Type of resource.
    public enum ResourceType: Int, CustomStringConvertible {
        /// Resource is a photo.
        case photo
        /// Resource is a video.
        case video
        /// Resource is a generated panorama.
        case panorama

        /// Debug description.
        public var description: String {
            switch self {
            case .photo:
                return "photo"
            case .video:
                return "video"
            case .panorama:
                return "panorama"
            }
        }
    }

    /// Media format.
    public enum Format: Int, CustomStringConvertible {
        /// JPEG photo.
        case jpg
        /// Digital Negative (DNG) photo.
        case dng
        /// MP4 video.
        case mp4
        /// PNG photo.
        case png

        /// Debug description.
        public var description: String {
            switch self {
            case .jpg:
                return "jpg"
            case .dng:
                return "dng"
            case .mp4:
                return "mp4"
            case .png:
                return "png"
            }
        }
    }

    /// Photo mode.
    public enum PhotoMode: Int, CustomStringConvertible {
        /// single shot mode.
        case single
        /// bracketing mode (take a burst of 3 or 5 frames with a different exposure).
        case bracketing
        /// burst mode (take burst of frames).
        case burst
        /// panorama mode (take successive set of photos from one hovering point while rotating).
        case panorama
        /// Photo mode that allows to take frames at a regular time interval.
        case timeLapse
        /// Photo mode that allows to take frames at a regular GPS position interval.
        case gpsLapse

        /// Debug description.
        public var description: String {
            switch self {
            case .single:
                return "single"
            case .bracketing:
                return "bracketing"
            case .burst:
                return "burst"
            case .panorama:
                return "panorama"
            case .timeLapse:
                return "timeLapse"
            case .gpsLapse:
                return "gpsLapse"
            }
        }
    }

    /// Panorama type.
    public enum PanoramaType: Int, CustomStringConvertible {
        /// Horizontal 180° panorama type.
        case horizontal_180
        /// Vertical 180° panorama type.
        case vertical_180
        /// Spherical panorama type.
        case spherical
        /// Super wide panorama type.
        case super_wide

        /// Debug description.
        public var description: String {
            switch self {
            case .horizontal_180:
                return "horizontal_180"
            case .vertical_180:
                return "vertical_180"
            case .spherical:
                return "spherical"
            case .super_wide:
                return "super_wide"
            }
        }
    }

    /// Available metadata types.
    public enum MetadataType: Int, CustomStringConvertible {
        /// Media contains thermal metadata.
        case thermal

        /// Debug description.
        public var description: String {
            switch self {
            case .thermal:
                return "thermal"
            }
        }
    }

    /// Track of a media.
    public enum Track: Int, CustomStringConvertible {
        /// Default video track.
        case defaultVideo
        /// Thermal raw video, not blended with thermal data.
        case thermalUnblended

        /// Debug description.
        public var description: String {
            switch self {
            case .defaultVideo:
                return "defaultVideo"
            case .thermalUnblended:
                return "thermalUnblended"
            }
        }
    }

    /// Resource camera spectrum
    public enum CameraSpectrum {

        /// Resource has an unknown camera spectrum.
        case unknown

        /// Resource has a visible camera spectrum.
        case visible

        /// Resource has a blended camera spectrum.
        case blended

        /// Resource has a thermal camera spectrum.
        case thermal
    }

    /// A resource of a media.
    public class Resource: NSObject {

        /// Resource unique identifier.
        public let uid: String

        /// Resource type.
        public let type: MediaItem.ResourceType

        /// Resource path
        public let path: String

        /// Resource format.
        public let format: MediaItem.Format

        /// Resource data size, in bytes.
        public let size: UInt64

        /// Resource duration in seconds (for video).
        public let duration: TimeInterval?

        /// Resource creation date.
        public let creationDate: Date

        /// Resource creation location.
        public let location: CLLocation?

        /// Available metaData types in this ressource.
        public let metadataTypes: Set<MetadataType>

        /// Camera spectrum. `nil` if this resource `type` is not a `photo`.
        public let cameraSpectrum: CameraSpectrum?

        /// Storage of the ressource.
        public let storage: StorageType?

        /// Tells whether the media can be streamed from the device.
        public var streamable: Bool {
            if let availableTracks = getAvailableTracks() {
                return !availableTracks.isEmpty
            }
            return false
        }

        /// Tells whether the resource is signed.
        public let signed: Bool

        /// Gets available tracks of media.
        /// Subclasses should override this function.
        public func getAvailableTracks() -> Set<Track>? { return nil }

        /// Constructor.
        ///
        /// - Parameters:
        ///   - format: resource format
        ///   - type: resource type
        ///   - path: resource path
        ///   - size: resource data size
        ///   - duration: resource duration in seconds (for video)
        ///   - location: resource creation location, may be `nil` if unavailable
        ///   - creationDate: media creation date
        ///   - metadataTypes: set of 'MetadataType' available in this ressource
        ///   - cameraSpectrum: camera spectrum of the media; `nil` if `type` is not `photo`
        ///   - storage: resource storage type `nil` if unavailable
        ///   - signed: `true` if resource is signed, `false` otherwise
        init(uid: String, type: MediaItem.ResourceType, path: String, format: MediaItem.Format, size: UInt64,
             duration: TimeInterval?, location: CLLocation?, creationDate: Date, metadataTypes: Set<MetadataType>,
             cameraSpectrum: CameraSpectrum?, storage: StorageType?,
             signed: Bool) {
            self.uid = uid
            self.type = type
            self.path = path
            self.format = format
            self.size = size
            self.duration = duration
            self.location = location
            self.creationDate = creationDate
            self.metadataTypes = metadataTypes
            self.cameraSpectrum = cameraSpectrum
            self.storage = storage
            self.signed = signed
        }
    }

    /// Media unique identifier.
    public let uid: String

    /// Media name.
    public let name: String

    /// Media type.
    public let type: MediaType

    /// Unique identifier of the run for this media.
    public let runUid: String

    /// Custom identifier defined by application if available, otherwise nil.
    /// The custom identifier can be defined using `Camera2` component `Camera2MediaMetadata`.
    public let customId: String?

    /// Custom title defined by application if available, otherwise nil.
    /// The custom title can be defined using `Camera2` component `Camera2MediaMetadata`.
    public let customTitle: String?

    /// Media creation date.
    public let creationDate: Date

    /// Drone boot date if available, otherwise nil.
    public let bootDate: Date?

    /// Flight date if available, otherwise nil.
    public let flightDate: Date?

    /// location of a media
    public let location: CLLocation?

    /// Expected number of resources in the media.
    public let expectedCount: UInt64?

    /// Photo mode of the media (if available and media is a photo else nil).
    public let photoMode: MediaItem.PhotoMode?

    /// Panorama type, if media is a panorama photo, otherwise nil.
    public let panoramaType: PanoramaType?

    /// Media available resources.
    public let resources: [Resource]

    /// Available metaData types in this Media.
    public let metadataTypes: Set<MetadataType>

    /// Custom user data. Client can use this property to store custom data for this item, like it selection state.
    /// This property be kept between updates of a media list reference.
    public var userData: Any?

    /// Constructor.
    ///
    /// - Parameters:
    ///   - uid: media unique identifier
    ///   - name: media name
    ///   - type: media type
    ///   - runUid: unique identifier of the run for this media
    ///   - customId: application custom identifier
    ///   - customTitle: application custom title
    ///   - creationDate: media creation date
    ///   - bootDate: drone boot date
    ///   - flightDate: flight date
    ///   - location: location of the media
    ///   - expectedCount: expected number of resources in the media
    ///   - photoMode: photo mode of the media (if available and media is a photo else nil)
    ///   - panoramatype: panoramaType
    ///   - resources: available resources by formats
    ///   - metadataTypes: set of 'MetadataType' available in this media
    init(uid: String, name: String, type: MediaType, runUid: String, customId: String?, customTitle: String?,
         creationDate: Date, bootDate: Date? = nil, flightDate: Date? = nil, location: CLLocation? = nil,
         expectedCount: UInt64?, photoMode: MediaItem.PhotoMode?, panoramaType: PanoramaType?, resources: [Resource],
         metadataTypes: Set<MetadataType>) {
        self.uid = uid
        self.name = name
        self.type = type
        self.runUid = runUid
        self.customId = customId
        self.customTitle = customTitle
        self.creationDate = creationDate
        self.bootDate = bootDate
        self.flightDate = flightDate
        self.location = location
        self.expectedCount = expectedCount
        self.photoMode = photoMode
        self.panoramaType = panoramaType
        self.resources = resources
        self.metadataTypes = metadataTypes
    }
}
