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

/// Reasons why a tracking piloting interface may be unavailable or unavailable in degraded mode.
///
/// - Note: `FollowMePilotingItf` and `LookAtPilotingItf` are "tracking pilotingItf".
@objc(GSTrackingIssue)
public enum TrackingIssue: Int, CustomStringConvertible {

    /// Drone is not flying.
    case droneNotFlying
    /// Drone is not calibrated.
    case droneNotCalibrated
    /// Drone gps is not fixed or has a poor accuracy.
    case droneGpsInfoInaccurate
    /// Drone is too close to the target.
    case droneTooCloseToTarget
    /// Drone is too close to the ground.
    case droneTooCloseToGround
    /// Target gps is not fixed or has a poor accuracy.
    case targetGpsInfoInaccurate
    /// Target barometer data are missing.
    case targetBarometerInfoInaccurate
    /// External target detection information is missing.
    case targetDetectionInfoMissing
    /// Drone is above max altitude.
    case droneAboveMaxAltitude
    /// Drone is outside of the geofence.
    case droneOutOfGeofence
    /// Drone is too far from target.
    case droneTooFarFromTarget
    /// Target horizontal speed is too high.
    case targetHorizontalSpeedKO
    /// Target vertical speed is too high.
    case targetVerticalSpeedKO
    /// Target altitude has a bad accuracy.
    case targetAltitudeAccuracyKO

    /// Debug description.
    public var description: String {
        switch self {
        case .droneNotFlying:                   return "droneNotFlying"
        case .droneNotCalibrated:               return "droneNotCalibrated"
        case .droneGpsInfoInaccurate:           return "droneGpsInfoInaccurate"
        case .droneTooCloseToTarget:            return "droneTooCloseToTarget"
        case .droneTooCloseToGround:            return "droneTooCloseToGround"
        case .targetGpsInfoInaccurate:          return "targetGpsInfoInaccurate"
        case .targetBarometerInfoInaccurate:    return "targetBarometerInfoInaccurate"
        case .targetDetectionInfoMissing:       return "targetDetectionInfoMissing"
        case .droneAboveMaxAltitude:            return "droneAboveMaxAltitude"
        case .droneOutOfGeofence:               return "droneOutOfGeofence"
        case .droneTooFarFromTarget:            return "droneTooFarFromTarget"
        case .targetHorizontalSpeedKO:          return "targetHorizontalSpeedKO"
        case .targetVerticalSpeedKO:            return "targetVerticalSpeedKO"
        case .targetAltitudeAccuracyKO:         return "targetAltitudeAccuracyKO"
        }
    }
}
