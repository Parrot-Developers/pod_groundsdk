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

/// Utility protocol allowing to access flight camera record engine internal storage.
///
/// This mainly allows to query the location where flightCameraRecord files should be stored and
/// to notify the engine when new flightCameraRecords have been downloaded.
public protocol FlightCameraRecordStorageCore: UtilityCore {

    /// Directory where new flight camera record files may be downloaded.
    ///
    /// Inside this directory, flightCameraRecord downloaders may create temporary folders, that have a `.tmp`
    /// suffix to their name. Those folders will be cleaned up by the flight camera record engine when appropriate.
    ///
    /// Any directory with another name is considered to be a valid flightCameraRecord by the flightCameraRecord engine
    ///
    /// Multiple downloaders may be assigned the same download directory. As a consequence, flightCameraRecord
    /// directories that a downloader may create should have a name as unique as possible to avoid collision.
    ///
    /// The directory in question might not exist, and the caller has the responsibility to create it if necessary,
    /// but should ensure to do so on a background thread.
    var workDir: URL { get }

    /// Notifies the flight camera record engine that a new flightCameraRecord as been downloaded.
    ///
    /// - Note: the flightCameraRecord file must be located in `workDir`.
    ///
    /// - Parameter flightCameraRecordUrl: URL of the downloaded flightCameraRecord file
    func notifyFlightCameraRecordReady(flightCameraRecordUrl: URL)
}

/// Implementation of the `FlightCameraRecordStorage` utility.
class FlightCameraRecordStorageCoreImpl: FlightCameraRecordStorageCore {

    let desc: UtilityCoreDescriptor = Utilities.flightCameraRecordStorage

    /// Engine that acts as a backend for this utility.
    unowned let engine: FlightCameraRecordEngine

    var workDir: URL {
        return engine.workDir
    }

    /// Constructor
    ///
    /// - Parameter engine: the engine acting as a backend for this utility
    init(engine: FlightCameraRecordEngine) {
        self.engine = engine
    }

    func notifyFlightCameraRecordReady(flightCameraRecordUrl: URL) {
        guard flightCameraRecordUrl.deletingLastPathComponent().absoluteString == workDir.absoluteString else {
            ULog.w(.flightCameraRecordStorageTag, "flightCameraRecordUrl \(flightCameraRecordUrl)" +
                " is not located in the flighLog directory \(workDir)")
            return
        }
        engine.add(flightCameraRecordUrl: flightCameraRecordUrl)
    }
}

/// Flight camera record storage utility description
public class FlightCameraRecordStorageCoreDesc: NSObject, UtilityCoreApiDescriptor {
    public typealias ApiProtocol = FlightCameraRecordStorageCore
    public let uid = UtilityUid.flightCameraRecordStorage.rawValue
}
