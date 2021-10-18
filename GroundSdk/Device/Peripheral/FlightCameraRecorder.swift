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

/// Flight camera recording setting.
public protocol FlightCameraRecorderSetting: AnyObject {
    /// Tells if setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported modes.
    var supportedValues: Set<FlightCameraRecorderPipeline> { get }

    /// Flight camera recorder pipelines.
    var value: Set<FlightCameraRecorderPipeline> { get set }
}

/// Type of pipeline.
public enum FlightCameraRecorderPipeline: Int, RawRepresentable, Hashable, CaseIterable, CustomStringConvertible {
    /// Drone left stereo camera pipeline.
    case fstcamLeftTimelapse
    /// Drone right stereo camera pipeline.
    case fstcamRightTimelapse
    /// Drone front camera pipeline.
    case fcamTimelapse
    /// Drone left stereo camera last frames pipeline.
    case fstcamLeftEmergency
    /// Drone right stereo camera last frames pipeline.
    case fstcamRightEmergency
    /// Drone front camera last frames pipeline.
    case fcamEmergency
    /// Drone front camera follow me pipeline.
    case fcamFollowme
    /// Drone vertical camera precise home pipeline.
    case vcamPrecisehome
    /// Drone left stereo camera obstacle avoidance pipeline.
    case fstcamLeftObstacleavoidance
    /// Drone right stereo camera obstacle avoidance pipeline.
    case fstcamRightObstacleavoidance
    /// Drone vertical camera precise hovering pipeline.
    case vcamPrecisehovering
    /// Drone left stereo camera love calibration pipeline.
    case fstcamLeftCalibration
    /// Drone right stereo camera love calibration pipeline.
    case fstcamRightCalibration
    /// Drone right stereo camera precise hovering pipeline.
    case fstcamRightPrecisehovering
    /// Drone left stereo camera specific events pipeline.
    case fstcamLeftEvent
    /// Drone right stereo camera specific events pipeline.
    case fstcamRightEvent

    /// Debug description.
    public var description: String { "(\rawValue)" }
}

/// Flight camera recorder peripheral interface for anafi2 drones.
///
/// This peripheral allows to configure flight camera recorder behavior, such as:
/// Active recording pipelines
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.flightCameraRecorder)
/// ```
public protocol FlightCameraRecorder: Peripheral {
    /// Gives access to the active pipelines setting.
    /// This setting allows to select which recording pipelines are active for flight camera recording.
    /// - Note: This setting remains available when the drone is not connected.
    var activePipelines: FlightCameraRecorderSetting { get }
}

/// :nodoc:
/// Flight camera recorder description
public class FlightCameraRecorderDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = FlightCameraRecorder
    public let uid = PeripheralUid.flightCameraRecorder.rawValue
    public let parent: ComponentDescriptor? = nil
}
