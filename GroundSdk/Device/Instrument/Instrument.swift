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

/// Base protocol for all Instrument components.
public protocol Instrument: Component {
}

/// Instrument component descriptor.
public protocol InstrumentClassDesc: ComponentApiDescriptor {
    /// Protocol of the instrument
    associatedtype ApiProtocol = Instrument
}

/// Defines all known Instrument descriptors.
public class Instruments: NSObject {
    /// Alarms information instrument.
    public static let alarms = AlarmsDesc()
    /// Altimeter instrument.
   public static let altimeter = AltimeterDesc()
    /// Attitude instrument.
    public static let attitudeIndicator = AttitudeIndicatorDesc()
    /// Battery information instrument.
    public static let batteryInfo = BatteryInfoDesc()
    /// Camera exposure values instrument.
    public static let cameraExposureValues = CameraExposureValuesDesc()
    /// Cellular logs instrument.
    public static let cellularLogs = CellularLogsDesc()
    /// Cellular session status instrument.
    public static let cellularSession = CellularSessionDesc()
    /// Heading instrument.
    public static let compass = CompassDesc()
    /// Flight info instrument.
    public static let flightInfo = FlightInfoDesc()
    /// Flight meter instrument.
    public static let flightMeter = FlightMeterDesc()
    /// Flying indicators instrument.
    public static let flyingIndicators = FlyingIndicatorsDesc()
    /// Location instrument.
    public static let gps = GpsDesc()
    /// Photo progress instrument.
    public static let photoProgressIndicator = PhotoProgressIndicatorDesc()
    /// Radio instrument.
    public static let radio = RadioDesc()
    /// Speedometer instrument.
    public static let speedometer = SpeedometerDesc()
    /// Takeoff checklist instrument.
    public static let takeoffChecklist = TakeoffChecklistDesc()
    /// Anemometer instrument.
    public static let anemometer = AnemometerDesc()
}

/// Instruments uid.
enum InstrumentUid: Int {
    case alarms
    case altimeter
    case attitudeIndicator
    case batteryInfo
    case cameraExposureValues
    case cellularLogs
    case cellularSession
    case compass
    case flightInfo
    case flightMeter
    case flyingIndicators
    case gps
    case photoProgressIndicator
    case radio
    case speedometer
    case takeoffChecklist
    case anemometer
}
