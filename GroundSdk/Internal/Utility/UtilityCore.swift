// Copyright (C) 2017 Parrot Drones SAS
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
    public static let internetConnectivity = InternetConnectivityCoreDesc()
    public static let droneStore = DroneStoreCoreDesc()
    public static let remoteControlStore = RemoteControlStoreCoreDesc()
    public static let crashReportStorage = CrashReportStorageCoreDesc()
    public static let flightDataStorage = FlightDataStorageCoreDesc()
    public static let flightLogStorage = FlightLogStorageCoreDesc()
    public static let firmwareStore = FirmwareStoreCoreDesc()
    public static let firmwareDownloader = FirmwareDownloaderCoreDesc()
    public static let blackBoxStorage = BlackBoxStorageCoreDesc()
    public static let systemPosition = SystemPositionCoreDesc()
    public static let cloudServer = CloudServerCoreDesc()
    public static let reverseGeocoder = ReverseGeocoderUtilityCoreDesc()
    public static let systemBarometer = SystemBarometerCoreDesc()
    public static let blacklistedVersionStore = BlacklistedVersionStoreCoreDesc()
    public static let userAccount = UserAccountUtilityCoreDesc()
    public static let ephemeris = EphemerisUtilityCoreDesc()
}

/// Utilities uid
enum UtilityUid: Int {
    case internetConnectivity = 1
    case droneStore
    case remoteControlStore
    case crashReportStorage
    case firmwareStore
    case firmwareDownloader
    case blackBoxStorage
    case systemPosition
    case cloudServer
    case reverseGeocoder
    case systemBarometer
    case blacklistedVersionStore
    case flightDataStorage
    case userAccount
    case ephemeris
    case flightLogStorage
}

/// Describe a Utility
public protocol UtilityCoreDescriptor: class {
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
            return (utility as! Desc.ApiProtocol)
        }
        return nil
    }

    // Publishes a utility.
    ///
    /// - Parameter utility: the utility to publish
    public func publish(utility: UtilityCore) {
        guard utilities[utility.desc.uid] == nil else {
            preconditionFailure("Utility registered multiple times: \(utility.desc.uid).")
        }

        utilities[utility.desc.uid] = utility
    }
}
