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

/// Base protocol for all Facility components.
@objc(GSFacility)
public protocol Facility: Component {
}

/// Facility component descriptor.
public protocol FacilityClassDesc: ComponentApiDescriptor {
    /// Protocol of the facility.
    associatedtype ApiProtocol = Facility
}

/// Defines all known facilities descriptors.
@objcMembers
@objc(GSFacilities)
public class Facilities: NSObject {
    /// Automatic connection facility.
    public static let autoConnection = AutoConnectionDesc()
    /// Black box reporter facility.
    public static let blackBoxReporter = BlackBoxReporterDesc()
    /// Crash reporter facility.
    public static let crashReporter = CrashReporterDesc()
    /// Event logger facility.
    public static let eventLogger = EventLoggerDesc()
    /// Firmware update facility.
    public static let firmwareManager = UpdateManagerDesc()
    /// Flight camera record reporter facility.
    public static let flightCameraRecordReporter = FlightCameraRecordReporterDesc()
    /// Flight data manager facility.
    public static let flightDataManager = FlightDataManagerDesc()
    /// Flight log reporter facility.
    public static let flightLogReporter = FlightLogReporterDesc()
    /// Gutma log manager facility.
    public static let gutmaLogManager = GutmaLogManagerDesc()
    /// Reverse geocoder facility.
    public static let reverseGeocoder = ReverseGeocoderDesc()
    /// User account facility.
    public static let userAccount = UserAccountDesc()
    /// User heading facility.
    public static let userHeading = UserHeadingDesc()
    /// User location facility.
    public static let userLocation = UserLocationDesc()
}

/// Facilities uid.
enum FacilityUid: Int {
    case autoConnection
    case blackBoxReporter
    case crashReporter
    case eventLogger
    case firmwareManager
    case flightCameraRecordReporter
    case flightDataManager
    case flightLogReporter
    case gutmaLogManager
    case reverseGeocoder
    case userAccount
    case userHeading
    case userLocation
}

/// Objective-C wrapper of Ref<Facility>. Required because swift generics can't be used from Objective-C
/// - Note: This class is for Objective-C only and must not be used in Swift.
@objcMembers
public class GSFacilityRef: NSObject {
    private let ref: Ref<Facility>

    /// Referenced facility.
    public var value: Facility? {
        return ref.value
    }

    /// Constructor.
    ///
    /// - Parameter ref: referenced facility
    init(ref: Ref<Facility>) {
        self.ref = ref
    }
}
