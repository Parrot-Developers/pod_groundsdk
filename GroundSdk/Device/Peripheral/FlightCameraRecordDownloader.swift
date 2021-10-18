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

/// Completion status of a flight camera record download.
public enum FCRDownloadCompletionStatus: Int, CustomStringConvertible {
    /// Download is not complete yet. Flight camera record download may still be ongoing or not even started yet.
    case none

    /// Flight camera records download has completed successfully.
    case success

    /// Flight camera records download interrupted.
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

/// State of the flight camera record downloader.
/// Informs about any ongoing flight camera records download progress, as well as the completion status of the flight
/// camera records download.
public class FlightCameraRecordDownloaderState: NSObject {
    /// Current completion status of the flight camera record downloader.
    ///
    /// The completion status changes to either `.interrupted` or `.success` when the download has been interrupted or
    /// completes successfully,
    /// then remains in this state until another flight camera record download begins, where it
    /// switches back to `.none`.
    public internal(set) var status: FCRDownloadCompletionStatus

    /// The current progress of an ongoing flight camera record download, expressed as a percentage.
    public internal(set) var downloadedCount: Int

    /// Constructor
    ///
    /// - Parameters:
    ///     - status: flight camera record download completion status.
    ///     - downloadedCount: downloaded count.
    internal init(status: FCRDownloadCompletionStatus = .none, downloadedCount: Int = 0) {
        self.status = status
        self.downloadedCount = downloadedCount
        super.init()
    }
}

/// Flight camera record downloader.
///
/// This peripheral informs about current flight camera record download.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.flightCameraRecordDownloader)
/// ```
public protocol FlightCameraRecordDownloader: Peripheral {
    /// Current download state.
    var state: FlightCameraRecordDownloaderState { get }

    /// Whether a flight camera record is currently being downloaded.
    var isDownloading: Bool { get }
}

/// :nodoc:
/// FlightCameraRecordDownloader description
public class FlightCameraRecordDownloaderDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = FlightCameraRecordDownloader
    public let uid = PeripheralUid.flightCameraRecordDownloader.rawValue
    public let parent: ComponentDescriptor? = nil
}
