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

/// Utility descriptor
public class Utilities: NSObject {
    /// Black boxes storage utility.
    public static let blackBoxStorage = BlackBoxStorageCoreDesc()
    /// Blacklisted versions utility.
    public static let blacklistedVersionStore = BlacklistedVersionStoreCoreDesc()
    /// Certificate images storage utility.
    public static let certificateImagesStorage = CertificateImagesStorageCoreDesc()
    /// Cloud server utility.
    public static let cloudServer = CloudServerCoreDesc()
    /// Crash report storage utility.
    public static let crashReportStorage = CrashReportStorageCoreDesc()
    /// Drones store utility.
    public static let droneStore = DroneStoreCoreDesc()
    /// GPS ephemeris utility.
    public static let ephemeris = EphemerisUtilityCoreDesc()
    /// Event logs utility.
    public static let eventLogger = EventLogUtilityCoreDesc()
    /// FileReplayBackend provider utility.
    public static let fileReplayProvider = FileReplayProviderCoreDesc()
    /// Firmware downloader utility.
    public static let firmwareDownloader = FirmwareDownloaderCoreDesc()
    /// Firmwares stores utility.
    public static let firmwareStore = FirmwareStoreCoreDesc()
    /// Flight camera records storage utility.
    public static let flightCameraRecordStorage = FlightCameraRecordStorageCoreDesc()
    /// Flight data storage utility.
    public static let flightDataStorage = FlightDataStorageCoreDesc()
    /// Flight log converter storage utility.
    public static let flightLogConverterStorage = FlightLogConverterStorageCoreDesc()
    /// Flight logs storage utility.
    public static let flightLogStorage = FlightLogStorageCoreDesc()
    /// Converted logs storage utility.
    public static let gutmaLogStorage = GutmaLogStorageCoreDesc()
    /// Internet connectivity monitoring utility.
    public static let internetConnectivity = InternetConnectivityCoreDesc()
    /// Plan generator utility.
    public static let planUtilityProvider = PlanUtilityCoreDesc()
    /// Remote controls store utility.
    public static let remoteControlStore = RemoteControlStoreCoreDesc()
    /// Reverse geocoder utility.
    public static let reverseGeocoder = ReverseGeocoderUtilityCoreDesc()
    /// System barometer utility.
    public static let systemBarometer = SystemBarometerCoreDesc()
    /// System position utility.
    public static let systemPosition = SystemPositionCoreDesc()
    /// User account utility.
    public static let userAccount = UserAccountUtilityCoreDesc()
}

/// Utilities uid
enum UtilityUid: Int {
    case blackBoxStorage
    case blacklistedVersionStore
    case certificateImagesStorage
    case cloudServer
    case crashReportStorage
    case droneStore
    case ephemeris
    case eventLogger
    case fileReplayProvider
    case firmwareDownloader
    case firmwareStore
    case flightCameraRecordStorage
    case flightDataStorage
    case flightLogConverterStorage
    case flightLogStorage
    case gutmaLogStorage
    case internetConnectivity
    case planUtilityProvider
    case remoteControlStore
    case reverseGeocoder
    case systemBarometer
    case systemPosition
    case userAccount
}

/// Describe a Utility
public protocol UtilityCoreDescriptor: AnyObject {
    /// Unique identifier of the utility class
    var uid: Int { get }
}

/// Describe an utility protocol
public protocol UtilityCoreApiDescriptor: UtilityCoreDescriptor {
    /// Protocol of the Utility
    associatedtype ApiProtocol = UtilityCore
}

/// Defines a Utility.
public protocol UtilityCore {
    /// The utility descriptor
    var desc: UtilityCoreDescriptor { get }
}

/// A store of utilities.
public final class UtilityCoreRegistry {

    /// Utilities, indexed by their description uid.
    private var utilities: [Int: UtilityCore] = [:]

    /// Gets a utility.
    ///
    /// - Parameter desc: description of the requested utility.
    ///             See `Utilities` api for available descriptors instances
    /// - Returns: the requested utility or nil if it is not available.
    public func getUtility<Desc: UtilityCoreApiDescriptor>(_ desc: Desc) -> Desc.ApiProtocol? {
        // we first get the utility if it exists
        // then, before returning it, we force cast it as we are sure that this cannot fail
        if let utility = utilities[desc.uid] {
            return utility as? Desc.ApiProtocol
        }
        return nil
    }

    /// Publishes a utility.
    ///
    /// - Parameter utility: the utility to publish
    public func publish(utility: UtilityCore) {
        guard utilities[utility.desc.uid] == nil else {
            preconditionFailure("Utility registered multiple times: \(utility.desc.uid).")
        }

        utilities[utility.desc.uid] = utility
    }
}
