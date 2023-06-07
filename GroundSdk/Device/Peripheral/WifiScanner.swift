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

/// Wifi network environment scan result.
///
/// Represents one network which was visible during a scan operation (see `WifiScanner`).
public struct ScanResult: Equatable {

    /// Scanned network SSID.
    public let ssid: String

    /// Scanned network channel. `nil` if unknown or unavailable.
    public let channel: WifiChannel?

    public init(ssid: String, channel: WifiChannel?) {
        self.ssid = ssid
        self.channel = channel
    }
}

/// WifiScanner peripheral interface.
///
/// Allows scanning the device's wifi environment to obtain information about the current occupation of wifi channels.
///
/// This peripheral can be retrieved by:
/// ```
/// drone.getPeripheral(Peripherals.wifiScanner)
/// ```
public protocol WifiScanner: Peripheral {

    /// Whether the peripheral is currently scanning wifi networks environment.
    var scanning: Bool { get }

    /// Latest scan results. Empty if no results were obtained yet or when scanning is not ongoing.
    var scanResults: [ScanResult] { get }

    /// Requests the wifi environment scanning process to start.
    ///
    /// While scanning, the peripheral will regularly report wifi channels occupation.
    /// These results can be obtained using `scanResults`.
    ///
    /// This has no effect if `scanning` is already ongoing.
    func startScan()

    /// Requests an ongoing scan operation to stop.
    ///
    /// When scanning stops, `scanResults` are cleared immediately.
    ///
    /// This has no effect if this peripheral is not currently `scanning`.
    func stopScan()

    /// Retrieves the amount of wifi networks that are currently using a given wifi channel.
    ///
    /// - Parameter channel: the wifi channel to query occupation information of
    /// - Returns: the channel occupation rate
    @available(*, deprecated, message: "Use `scanResults` instead")
    func getOccupationRate(forChannel channel: WifiChannel) -> Int
}

/// :nodoc:
/// Wifi scanner description
public class WifiScannerDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = WifiScanner
    public let uid = PeripheralUid.wifiScanner.rawValue
    public let parent: ComponentDescriptor? = nil
}
