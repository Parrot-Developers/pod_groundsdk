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

/// Reason why this piloting interface is currently unavailable.
@objc(GSFlightPlanUnavailabilityReason)
public enum FlightPlanUnavailabilityReason: Int, CustomStringConvertible {
    /// Not enough battery.
    case insufficientBattery
    /// Drone GPS accuracy is too weak.
    case droneGpsInfoInaccurate
    /// Drone needs to be calibrated.
    case droneNotCalibrated
    /// No flight plan file uploaded.
    case missingFlightPlanFile
    /// Drone cannot take-off.
    /// This error can happen if the flight plan piloting interface is activated while the drone
    /// cannot take off.
    /// It can be for example if the drone is in emergency or has not enough battery to take off.
    case cannotTakeOff
    /// Drone camera is not available.
    case cameraUnavailable
    /// First waypoint is too far to be reached.
    case firstWaypointTooFar
    /// Drone is in an invalid state
    case droneInvalidState

    /// Debug description.
    public var description: String {
        switch self {
        case .insufficientBattery:      return "insufficientBattery"
        case .droneGpsInfoInaccurate:   return "droneGpsInfoInaccurate"
        case .droneNotCalibrated:       return "droneNotCalibrated"
        case .missingFlightPlanFile:    return "missingFlightPlanFile"
        case .cannotTakeOff:            return "cannotTakeOff"
        case .cameraUnavailable:        return "cameraUnavailable"
        case .droneInvalidState:        return "droneInvalidState"
        case .firstWaypointTooFar:      return "firstWaypointTooFar"
        }
    }
}

/// Defines how a mavlink flight plan file is interpreted by the drone.
@objc(GSFlightPlanInterpreter)
public enum FlightPlanInterpreter: Int, CustomStringConvertible {
    /// Interpret file according to Parrot legacy non-standard rules.
    case legacy
    /// Interpret file according to Mavlink standard.
    case standard

    /// Debug description.
    public var description: String {
        switch self {
        case .legacy:   return "legacy"
        case .standard: return "standard"
        }
    }
}

/// Activation error.
@objc(GSFlightPlanActivationError)
public enum FlightPlanActivationError: Int, CustomStringConvertible {
    /// No activation error.
    case none
    /// Incorrect flight plan file.
    case incorrectFlightPlanFile
    /// One or more waypoints are beyond the geofence.
    case waypointBeyondGeofence

    /// Debug description.
    public var description: String {
        switch self {
        case .none:                     return "none"
        case .incorrectFlightPlanFile:  return "incorrectFlightPlanFile"
        case .waypointBeyondGeofence:   return "waypointBeyondGeofence"
        }
    }
}

/// Flight Plan file upload state.
@objc(GSFlightPlanFileUploadState)
public enum FlightPlanFileUploadState: Int, CustomStringConvertible {
    /// No flight plan file has been uploaded yet.
    case none
    /// The flight plan file is currently uploading to the drone.
    case uploading
    /// The flight plan file has been successfully uploaded to the drone.
    case uploaded
    /// The flight plan file upload has failed.
    case failed

    /// Debug description.
    public var description: String {
        switch self {
        case .none:         return "none"
        case .uploading:    return "uploading"
        case .uploaded:     return "uploaded"
        case .failed:       return "failed"
        }
    }
}

/// Result of media resources clean before recovery of a flight plan execution,
/// see `cleanBeforeRecovery`.
public enum CleanBeforeRecoveryResult: String, CustomStringConvertible {
    /// Media resources clean succeeded.
    case success
    /// Media resources clean failed.
    case failed
    /// Media resources clean was canceled.
    case canceled

    /// Debug description.
    public var description: String { rawValue }
}

/// Information for flight plan execution recovery.
public struct RecoveryInfo: Equatable {

    /// Flight plan identifier.
    public let id: String

    /// Custom identifier.
    public let customId: String

    /// Index of the latest mission item completed.
    public let latestMissionItemExecuted: UInt

    /// Running time of the flightplan being executed.
    public let runningTime: TimeInterval

    /// First resource id of the latest media capture requested by the flightplan.
    public let resourceId: String

    /// Constructor.
    ///
    /// - Parameters:
    ///   - id: flight plan identifier
    ///   - customId: custom identifier
    ///   - latestMissionItemExecuted: index of the latest mission item completed
    ///   - runningTime: running time of the flightplan being executed
    ///   - resourceId: first resource id of the latest media capture requested by the flightplan.
    public init(id: String, customId: String, latestMissionItemExecuted: UInt,
                runningTime: TimeInterval, resourceId: String) {
        self.id = id
        self.customId = customId
        self.latestMissionItemExecuted = latestMissionItemExecuted
        self.runningTime = runningTime
        self.resourceId = resourceId
    }
}

/// Describes the drone's behaviour upon disconnection of GroundSdk.
public enum FlightPlanDisconnectionPolicy {
    /// The drone stops the current executing flight plan and performs an Return To Home.
    case returnToHome
    /// The drone continues the current flight plan execution until its completion. Upon reaching
    /// completion if the GroundSdk is still disconnected the default disconnect behavior is
    /// performed.
    case `continue`
}

/// Flight Plan piloting interface for drones.
///
/// Allows to make the drone execute predefined flight plans.
/// A flight plan is defined using a file in Mavlink format. For further information, please refer to
/// [Parrot FlightPlan Mavlink documentation](https://developer.parrot.com/docs/mavlink-flightplan/overview.html).
///
/// This piloting interface remains `.unavailable` until all `FlightPlanUnavailabilityReason` have
/// been cleared:
///  - A Flight Plan file (i.e. a mavlink file) has been uploaded to the drone (see
///    `uploadFlightPlan(filepath:)`)
///  - The drone GPS location has been acquired
///  - The drone is properly calibrated
///  - The drone is in a state that allows it to take off
///
/// Then, when all those conditions hold, the interface becomes `.idle` and can be activated to
/// begin or resume Flight Plan execution, which can be paused by deactivating this piloting
/// interface.
///
/// This piloting interface can be retrieved by:
/// ```
/// drone.getPilotingItf(flightPlan)
/// ```
public protocol FlightPlanPilotingItf: PilotingItf, ActivablePilotingItf {
    /// Latest flight plan file upload state.
    var latestUploadState: FlightPlanFileUploadState { get }

    /// Index of the latest mission item completed.
    var latestMissionItemExecuted: UInt? { get }

    /// Index of the latest mission item skipped.
    var latestMissionItemSkipped: UInt? { get }

    /// Set of reasons why this piloting interface is unavailable.
    ///
    /// Empty when state is `.idle` or `.active`.
    var unavailabilityReasons: Set<FlightPlanUnavailabilityReason> { get }

    /// Error raised during the latest activation.
    ///
    /// It is put back to `.none` as soon as `activate(restart:)` is called.
    var latestActivationError: FlightPlanActivationError { get }

    /// Whether the current flight plan on the drone is the latest one that has been uploaded from
    /// the application.
    var flightPlanFileIsKnown: Bool { get }

    /// Identifier of the flight plan currently loaded on the drone, `nil` if unknown.
    var flightPlanId: String? { get }

    /// Information about the latest flight plan started by the drone, `nil` if unavailable.
    ///
    /// This information is provided by the drone at connection and when a flight plan stops.
    /// It is turned to `nil` when the drone is disconnected or when `clearRecoveryInfo()` is called.
    ///
    /// If the application lose connection to the drone during a flight plan and then flight plan
    /// stops, this information will help the application to manage flight plan resume at
    /// reconnection.
    var recoveryInfo: RecoveryInfo? { get }

    /// Whether the flight plan is currently paused.
    ///
    /// If `true`, the restart parameter of `activate(restart:)` can be set to `false` to resume the
    /// flight plan instead of playing it from the beginning. If `isPaused` is `false,` this
    /// parameter will be ignored and the flight plan will be played from its beginning.
    ///
    /// When this piloting interface is deactivated, any currently playing flight plan will be
    /// paused.
    var isPaused: Bool { get }

    /// Whether start of a flight plan at a given mission item is supported.
    ///
    /// When `true`, method `activate(restart:interpreter:missionItem:)` can be used.
    var activateAtMissionItemSupported: Bool { get }

    /// Whether start of a flight plan at a given mission item with a disconnection policy is
    /// supported.
    ///
    /// When `true`, method `activate(restart:interpreter:missionItem:disconnectionPolicy:)` can be
    /// used.
    var activateAtMissionItemV2Supported: Bool { get }

    /// Tells whether uploading a flight plan with an associated custom identifier is supported.
    ///
    /// When `true`, method `uploadFlightPlan(filepath:customFlightPlanId:)` can be used.
    var isUploadWithCustomIdSupported: Bool { get }

    /// Uploads a Flight Plan file to the drone.
    ///
    /// When the upload ends, if all other necessary conditions hold (GPS location acquired, drone
    /// properly calibrated), then the interface becomes idle and the Flight Plan is ready to be
    /// executed.
    ///
    /// If any upload is on-going it is cancelled.
    ///
    /// - Parameter filepath: local path of the file to upload
    func uploadFlightPlan(filepath: String)

    /// Uploads a Flight Plan file to the drone.
    ///
    /// This method associates the provided identifier only if `isUploadWithCustomIdSupported`
    /// returns `true`, otherwise it behaves strictly as `uploadFlightPlan(filepath:)` function.
    ///
    /// When the upload ends, if all other necessary conditions hold (GPS location acquired, drone
    /// properly calibrated), then the interface becomes idle and the Flight Plan is ready to be
    /// executed.
    ///
    /// If any upload is on-going it is cancelled.
    ///
    /// - Parameters:
    ///     - filepath: local path of the file to upload
    ///     - customFlightPlanId: custom flight plan id
    /// - Note: customFlightPlanId will be ignored if activateAtMissionItemSupported is `false`.
    func uploadFlightPlan(filepath: String, customFlightPlanId: String)

    /// Cancels any on-going upload.
    ///
    /// If no upload is on-going there is no effect.
    func cancelPendingUpload()

    /// Activates this piloting interface and starts executing the uploaded flight plan.
    ///
    /// The interface should be `.idle` for this method to have effect.
    /// The flight plan is resumed if the `restart` parameter is false and `isPaused` is `true`.
    /// Otherwise, the flight plan is restarted from its beginning.
    ///
    /// If successful, it deactivates the current piloting interface and activates this one.
    ///
    /// - Parameter restart: `true` to force restarting the flight plan.
    ///                       If `isPaused` is `false`, this parameter will be ignored.
    /// - Returns: `true` on success, `false` if the piloting interface can't be activated
    /// - Note: `activate(restart:)` will call `activate(restart: interpreter:)` with interpreter
    /// `legacy`.
    func activate(restart: Bool) -> Bool

    /// Activates this piloting interface and starts executing the uploaded flight plan.
    ///
    /// The interface should be `.idle` for this method to have effect.
    /// The flight plan is resumed if the `restart` parameter is false and `isPaused` is `true`.
    /// Otherwise, the flight plan is restarted from its beginning.
    ///
    /// If successful, it deactivates the current piloting interface and activates this one.
    ///
    /// - Parameters:
    ///    - restart: `true` to force restarting the flight plan. If `isPaused` is `false`, this
    ///      parameter will be ignored.
    ///    - interpreter: instructs how the flight plan must be interpreted by the drone.
    /// - Returns: `true` on success, `false` if the piloting interface can't be activated
    func activate(restart: Bool, interpreter: FlightPlanInterpreter) -> Bool

    /// Activates this piloting interface and starts executing the uploaded flight plan at given
    /// mission item.
    ///
    /// The interface should be `.idle` for this method to have effect.
    /// The flight plan is resumed if the `restart` parameter is false and `isPaused` is `true`.
    /// Otherwise, the flight plan is restarted from the mission item.
    /// This method can be used only when `activateAtMissionItemSupported` is `true`.
    ///
    /// If successful, it deactivates the current piloting interface and activates this one.
    ///
    /// - Parameters:
    ///    - restart: `true` to force restarting the flight plan. If `isPaused` is `false`, this
    ///      parameter will be ignored.
    ///    - interpreter: instructs how the flight plan must be interpreted by the drone
    ///    - missionItem: index of mission item where the flight plan should start
    /// - Returns: `true` on success, `false` if the piloting interface can't be activated
    func activate(restart: Bool, interpreter: FlightPlanInterpreter, missionItem: UInt) -> Bool

    /// Activates this piloting interface and starts executing the uploaded flight plan at given mission item.
    ///
    /// The interface should be `.idle` for this method to have effect.
    /// The flight plan is resumed if the `restart` parameter is false and `isPaused` is `true`.
    /// Otherwise, the flight plan is restarted from the mission item.
    /// This method can be used only when `activateAtMissionItemSupported` is `true`.
    ///
    /// If successful, it deactivates the current piloting interface and activates this one.
    ///
    /// - Parameters:
    ///    - restart: `true` to force restarting the flight plan. If `isPaused` is `false`, this
    ///      parameter will be ignored.
    ///    - interpreter: instructs how the flight plan must be interpreted by the drone
    ///    - missionItem: index of mission item where the flight plan should start
    ///    - disconnectionPolicy: the behavior of the drone when a disconnection occurs
    /// - Returns: `true` on success, `false` if the piloting interface can't be activated
    /// - Note: This activation method is compatible with drones running on firmware at least 7.2.
    func activate(restart: Bool, interpreter: FlightPlanInterpreter, missionItem: UInt,
                  disconnectionPolicy: FlightPlanDisconnectionPolicy) -> Bool

    /// Stops execution of current flight plan, if any.
    ///
    /// This method has effect only if the piloting interface is active or if `isPaused` is `true`.
    /// Once the execution is stopped, the piloting interface is deactivated and `isPaused`
    /// is set to `false`.
    ///
    /// - Returns: `true` if the stop command was sent to the drone, `false` otherwise
    func stop() -> Bool

    /// Clears information about the latest flight plan started by the drone prior to current
    /// connection.
    ///
    /// This sends a command to the drone to clear this information, and sets `recoveryInfo` to
    /// `nil`.
    func clearRecoveryInfo()

    /// Cleans media resources before recovery of a flight plan execution.
    ///
    /// When a flight plan execution is interrupted, it can be restarted later from the latest
    /// reached waypoint. This function can be called before the flight plan restart to delete media
    /// resources captured during the interrupted execution and after the latest reached waypoint.
    /// The aim is to not have duplicate media resources captured after the latest reached waypoint.
    ///
    /// - Parameters:
    ///    - customId: custom identifier, as provided by `recoveryInfo`
    ///    - resourceId: first resource identifier of media captured after the latest reached
    ///      waypoint, as provided by `recoveryInfo`
    ///    - completion: completion callback (called on the main thread)
    ///    - result: media resources clean result
    /// - Returns: a clean media resources cancelable request
    func cleanBeforeRecovery(customId: String, resourceId: String,
                             completion: @escaping (_ result: CleanBeforeRecoveryResult) -> Void) -> CancelableCore?

    /// - important: DO NOT USE THIS METHOD, IT IS UNSTABLE, EXPERIMENTAL AND
    ///              WILL DISAPPEAR ON THE NEXT VERSION
    ///
    /// TODO: remove
    ///
    /// Prepares the drone for the upcoming flight plan activation.
    ///
    /// The drone will prepare the execution of a flight plan. This includes storing the current
    /// camera settings that will be restored at the end of the flight plan.
    ///
    /// This method should be called:
    ///   * **after** uploading the flight plan (cf `uploadFlightPlan(filepath:customFlightPlanId:)`
    ///   * but **before** modifying the camera settings (camera settings that should be effective
    ///     during the flight plan execution)
    ///   * and **before** activating the flight plan (cf `activate(restart:)`,
    ///    `activate(restart:interpreter:)` `activate(restart:interpreter:missionItem:)` and
    ///    `activate(restart:interpreter:missionItem:disconnectionPolicy:)`).
    ///
    /// - note: The preparation is in a best-effort basis and thus can fail. In that case the drone
    ///         will perform _no_ action of restoring any setting.
    func prepareForFlightPlanActivation()
}

/// Flight Plan piloting interface for drones.
///
/// Allows to make the drone execute predefined flight plans.
/// This piloting interface remains `.unavailable` until all `FlightPlanUnavailabilityReason` have
/// been cleared:
///  - A Flight Plan file (i.e. a mavlink file) has been uploaded to the drone (see
///    `uploadFlightPlan(filepath:))`
///  - The drone GPS location has been acquired
///  - The drone is properly calibrated
///  - The drone is in a state that allows it to take off
///
/// Then, when all those conditions hold, the interface becomes `.idle` and can be activated to
/// begin or resume Flight Plan execution, which can be paused by deactivating this piloting
/// interface.
///
/// This piloting interface can be retrieved by:
///
/// ```
/// id<GSFlightPlanPilotingItf> fplan = (id<GSFlightPlanPilotingItf>)[drone getPilotingItf:GSPilotingItfs.flightPlan];
/// ```
/// - Note: This protocol is for Objective-C only. Swift must use the protocol `FlightPlanPilotingItf`.
@objc
public protocol GSFlightPlanPilotingItf: PilotingItf, ActivablePilotingItf {
    /// Latest flight plan file upload state.
    var latestUploadState: FlightPlanFileUploadState { get }

    /// Index of the latest mission item completed.
    ///
    /// Negative value when not available.
    @objc(latestMissionItemExecuted)
    var gsLatestMissionItemExecuted: UInt { get }

    /// Error raised during the latest activation.
    ///
    /// It is put back to `.none` as soon as `activate(restart:)` is called.
    var latestActivationError: FlightPlanActivationError { get }

    /// Whether the current flight plan on the drone is the latest one that has been uploaded from
    /// the application.
    var flightPlanFileIsKnown: Bool { get }

    /// Whether the flight plan is currently paused.
    ///
    /// If `true`, the restart parameter of `activate(restart:)` can be set to `false` to resume the
    /// flight plan instead of playing it from the beginning. If `isPaused` is false, this parameter
    /// will be ignored and the flight plan will be played from its beginning.
    ///
    /// When this piloting interface is deactivated, any currently playing flight plan will be
    /// paused.
    var isPaused: Bool { get }

    /// Uploads a Flight Plan file to the drone.
    /// When the upload ends, if all other necessary conditions hold (GPS location acquired, drone
    /// properly calibrated), then the interface becomes idle and the Flight Plan is ready to be
    /// executed.
    ///
    /// - Parameter filepath: local path of the file to upload
    func uploadFlightPlan(filepath: String)

    /// Activates this piloting interface and starts executing the uploaded flight plan.
    ///
    /// The interface should be `.idle` for this method to have effect.
    /// The flight plan is resumed if the `restart` parameter is false and `isPaused` is `true`.
    /// Otherwise, the flight plan is restarted from its beginning.
    ///
    /// If successful, it deactivates the current piloting interface and activate this one.
    ///
    /// - Parameter restart: `true` to force restarting the flight plan.
    ///                      If `isPaused` is false, this parameter will be ignored.
    /// - Returns: `true` on success, `false` if the piloting interface can't be activated
    /// - Note: `activate(restart:)` will call `activate(restart: type:)`, default value of type is
    ///  `flightPlan`
    func activate(restart: Bool) -> Bool

    /// Activates this piloting interface and starts executing the uploaded flight plan.
    ///
    /// The interface should be `.idle` for this method to have effect.
    /// The flight plan is resumed if the `restart` parameter is false and `isPaused` is `true`.
    /// Otherwise, the flight plan is restarted from its beginning.
    ///
    /// If successful, it deactivates the current piloting interface and activate this one.
    ///
    /// - Parameters:
    ///    - restart: `true` to force restarting the flight plan.
    ///               If `isPaused` is `false`, this parameter will be ignored.
    ///    - interpreter: instructs how the flight plan must be interpreted by the drone.
    /// - Returns: `true` on success, `false` if the piloting interface can't be activated
    func activate(restart: Bool, interpreter: FlightPlanInterpreter) -> Bool

    /// Tells whether a given reason is partly responsible of the unavailable state of this piloting
    /// interface.
    ///
    /// - Parameter reason: the reason to query
    /// - Returns: `true` if the piloting interface is partly unavailable because of the given
    ///   reason.
    func hasUnavailabilityReason(_ reason: FlightPlanUnavailabilityReason) -> Bool
}

/// :nodoc:
/// FlightPlan piloting interface description
@objc(GSFlightPlanPilotingItfs)
public class FlightPlanPilotingItfs: NSObject, PilotingItfClassDesc {
    public typealias ApiProtocol = FlightPlanPilotingItf
    public let uid = PilotingItfUid.flightPlan.rawValue
    public let parent: ComponentDescriptor? = nil
}
