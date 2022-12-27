// Copyright (C) 2021 Parrot Drones SAS
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

/// Takeoff alarm with a level.
public class TakeoffAlarm: NSObject {

    /// Kind of check.
    public enum Kind: Int, CustomStringConvertible {
        /// Barometer health check
        case baro

        /// Battery gauge software update requirement check
        case batteryGaugeUpdateRequired

        /// Battery identification check
        case batteryIdentification

        /// Battery level check
        case batteryLevel

        /// Battery poor connection
        case batteryPoorConnection

        /// Battery under temperature check
        case batteryTooCold

        /// Battery over temperature check
        case batteryTooHot

        /// Battery USB connection check
        case batteryUsbPortConnection

        /// Cellular modem firmware updating check
        case cellularModemFirmwareUpdate

        /// Drone Remote Identification check.
        case dri

        /// Drone inclination check
        case droneInclination

        /// Gps check
        case gps

        /// Gyro health check
        case gyro

        /// Magneto health check
        case magneto

        /// Magneto calibration check
        case magnetoCalibration

        /// Ultrasound check
        case ultrasound

        /// Ongoing firmware update check
        case updateOngoing

        /// VCAM check
        case vcam

        /// Vertical TOF check
        case verticalTof

        /// Debug description.
        public var description: String {
            switch self {
            case .baro:                                 return "baro"
            case .batteryGaugeUpdateRequired:           return "batteryGaugeUpdateRequired"
            case .batteryIdentification:                return "batteryIdentification"
            case .batteryLevel:                         return "batteryLevel"
            case .batteryPoorConnection:                return "batteryPoorConnection"
            case .batteryTooCold:                       return "batteryTooCold"
            case .batteryTooHot:                        return "batteryTooHot"
            case .batteryUsbPortConnection:             return "batteryUsbPortConnection"
            case .cellularModemFirmwareUpdate:          return "cellularModemFirmwareUpdate"
            case .dri:                                  return "dri"
            case .droneInclination:                     return "droneInclination"
            case .gps:                                  return "gps"
            case .gyro:                                 return "gyro"
            case .magneto:                              return "magneto"
            case .magnetoCalibration:                   return "magnetoCalibration"
            case .ultrasound:                           return "ultrasound"
            case .updateOngoing:                        return "updateOngoing"
            case .vcam:                                 return "vcam"
            case .verticalTof:                          return "verticalTof"
            }
        }

        /// Set containing all possible kinds of alarm.
        public static let allCases: Set<Kind> = [
            .baro, .batteryGaugeUpdateRequired, .batteryIdentification, .batteryLevel,
            .batteryPoorConnection, .batteryTooCold, .batteryTooHot, .batteryUsbPortConnection,
            .cellularModemFirmwareUpdate, .dri, .droneInclination, .gps, .gyro, .magneto,
            .magnetoCalibration, .ultrasound, .updateOngoing, .vcam, .verticalTof]
    }

    /// Alarm level.
    public enum Level: Int, CustomStringConvertible {
        /// Alarm is not available
        case notAvailable

        /// Alarm is off.
        case off

        /// Alarm is at warning level.
        case on

        /// Debug description.
        public var description: String {
            switch self {
            case .notAvailable: return "notAvailable"
            case .off:          return "off"
            case .on:           return "on"
            }
        }
    }

    /// Kind of the alarm.
    public let kind: Kind

    /// Level of the alarm.
    public internal(set) var level: Level

    /// Constructor.
    ///
    /// - Parameters:
    ///    - kind: the kind of the alarm
    ///    - level: the initial level of the alarm
    internal init(kind: Kind, level: Level) {
        self.kind = kind
        self.level = level
    }

    /// Debug description.
    public override var description: String {
        return "TakeoffChecklist \(kind): \(level)"
    }
}

/// Instrument that informs about take off checklist.
///
/// This instrument can be retrieved by:
/// ```
/// drone.getInstrument(Instruments.takeoffChecklist)
/// ```
public protocol TakeoffChecklist: Instrument {

    /// Gets the takeoff alarm of a given kind.
    ///
    /// - Parameter kind: the kind of alarm to get
    /// - Returns: the alarm
    func getAlarm(kind: TakeoffAlarm.Kind) -> TakeoffAlarm
}

/// :nodoc:
/// Instrument descriptor
public class TakeoffChecklistDesc: NSObject, InstrumentClassDesc {
    public typealias ApiProtocol = TakeoffChecklist
    public let uid = InstrumentUid.takeoffChecklist.rawValue
    public let parent: ComponentDescriptor? = nil
}
