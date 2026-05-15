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

/// Completion status of a flight log download.
public enum FlightLogDownloadCompletionStatus: Int, CustomStringConvertible {
    /// Download is not complete yet. Flight log download may still be ongoing or not even started yet.
    case none

    /// Flight logs download has completed successfully.
    case success

    /// Flight logs download interrupted.
    case interrupted

    /// Debug description.
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .success:
            return "success"
        case .interrupted:
            return "interrupted"
        }
    }
}

/// Flight log downloading state
public enum FlightLogDownloadingState: CustomStringConvertible, Equatable {
    /// No download at this time.
    case none

    /// Flight logs are being downloaded.
    ///
    /// - Parameter hasFlight whether the files currently downloading have a flight or not.
    case downloading(hasFlight: Bool)

    /// Debug description.
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .downloading(let hasFlight):
            return "downloading hasFlight: \(hasFlight))"
        }
    }
}

/// Flight log downloader.
///
/// This peripheral informs about current flight log download.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.flightLogDownloader)
/// ```
public protocol FlightLogDownloader: Peripheral {

    /// Downloading state.
    ///
    /// Files are downloaded in order of date, and whether there was a flight or not in it.
    var downloadingState: FlightLogDownloadingState { get }

    /// Current completion status of the flight log downloader.
    ///
    /// The completion status changes to either `.interrupted` or `.success` when the download has been interrupted or
    /// completes successfully, then remains in this state until another flight log download begins, where it switches back
    /// to `.none`.
    var completionStatus: FlightLogDownloadCompletionStatus { get }

    /// Informs about the count of successfully downloaded flight logs before interruption.
    var latestDownloadCount: Int { get }
}

/// :nodoc:
/// FlightLogDownloader description
public class FlightLogDownloaderDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = FlightLogDownloader
    public let uid = PeripheralUid.flightLogDownloader.rawValue
    public let parent: ComponentDescriptor? = nil
}
