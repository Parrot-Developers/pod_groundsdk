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

/// Frequency band into which a Mars channel operates.
public enum MarsBand: CaseIterable, Comparable {
    /// 1.6 GHz band.
    case band_1_6_Ghz
    /// 1.8 GHz band.
    case band_1_8_Ghz
    /// 2.0 GHz band.
    case band_2_0_Ghz
    /// 2.2 GHz band.
    case band_2_2_Ghz
    /// 2.3 GHz band.
    case band_2_3_Ghz
    /// 2.4 GHz band.
    case band_2_4_Ghz
    /// 2.5 GHz band.
    case band_2_5_Ghz
    /// 3.5 GHz band.
    case band_3_5_Ghz
    /// 4.5 GHz band.
    case band_4_5_Ghz
    /// 5.0 GHz band.
    case band_5_0_Ghz
}

/// Mars channel.
public struct MarsChannel: Hashable, CustomStringConvertible, Comparable {

    /// Frequency band into which the channel operates.
    public let band: MarsBand

    /// Channel identifier.
    public let id: UInt

    /// Corresponding frequency in MHz.
    public let frequency: UInt?

    /// Debug description.
    public var description: String {
        return "\(band)-\(id)-\(frequency ?? 0)"
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - band: frequency band
    ///   - id: channel identifier
    ///   - frequency: channel frequency
    public init(band: MarsBand, id: UInt, frequency: UInt? = nil) {
        self.band = band
        self.id = id
        self.frequency = frequency
    }

    /// Comparable conformance.
    public static func < (lhs: MarsChannel, rhs: MarsChannel) -> Bool {
        lhs.band < rhs.band || (lhs .band == rhs.band && lhs.id < rhs.id)
    }

    public static func == (lhs: MarsChannel, rhs: MarsChannel) -> Bool {
        lhs.band == rhs.band && lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(band)
        hasher.combine(id)
    }
}

/// Mars channel selection mode.
public enum MarsChannelSelectionMode: Equatable, CustomStringConvertible {

    /// Channel is selected manually.
    case manual

    /// Channel is selected automatically within the given bands.
    /// - bands: allowed bands
    case autoOnBands(bands: Set<MarsBand>)

    /// RX/TX channels are selected automatically from the given sets.
    /// - rxChannels: allowed RX channels
    /// - txChannels: allowed TX channels
    case autoOnChannels(rxChannels: Set<MarsChannel>, txChannels: Set<MarsChannel>)

    /// Debug description.
    public var description: String {
        switch self {
        case .manual:
            return "manual"
        case .autoOnBands(let bands):
            return "auto bands: [\(bands.map { "\($0)" }.joined(separator: ", "))]"
        case .autoOnChannels(let rxChannels, let txChannels):
            return "auto rx: [\(rxChannels.map { $0.description }.joined(separator: ", "))]"
            + " tx: [\(txChannels.map { $0.description }.joined(separator: ", "))]"
        }
    }
}

/// Setting providing access to the Mars channel setup.
public protocol MarsChannelSetting: AnyObject {

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Current selection mode of the channel.
    var selectionMode: MarsChannelSelectionMode { get }

    /// Set of channels to which the mars component may be configured.
    var availableChannels: Set<MarsChannel> { get }

    /// Set of bands to which the mars component  may be configured.
    var availableBands: Set<MarsBand> { get }

    /// Mars component current channel.
    var channel: MarsChannel { get }

    /// Changes the current channel.
    ///
    /// - Parameter channel: new channel to use
    func select(channel: MarsChannel)

    /// Requests the device to select the most appropriate channel automatically within the given list of allowed
    /// `bands`.
    ///
    /// The device will run its auto-selection process and eventually may change the current channel.
    ///
    /// At any time the device may then change channel and switch to a channel that it considers better, provided
    /// this channel is in allowed `bands`.
    ///
    /// The device will also remain in this auto-selection mode, that is, it will run auto-selection to setup
    /// the channel on subsequent boots, until the application selects a channel manually (with `select(channel:)`).
    ///
    /// - Parameter bands: the frequency bands on which the automatic selection should be done.
    func autoSelect(onBands bands: Set<MarsBand>)

    /// Requests the device to select the most appropriate RX/TX channels automatically.
    ///
    /// The device will run its auto-selection process and eventually may change the current RX channel to any
    /// channel from the `rxChannels` set, and also may change the current TX channel to any channel from the
    /// `txChannels` set.
    ///
    /// At any time the device may then change channels and switch to channels that it considers better, provided the
    /// considered channel is allowed by the appropriate allowance set provided to this function.
    ///
    /// The device will also remain in this auto-selection mode, that is, it will run auto-selection to setup
    /// the channel on subsequent boots, until the application selects a channel manually (with `select(channel:)`).
    ///
    /// - Parameters:
    ///   - rxChannels: the set of allowed RX channels
    ///   - txChannels: the set of allowed TX channels
    func autoSelect(rxChannels: Set<MarsChannel>, txChannels: Set<MarsChannel>)
}
