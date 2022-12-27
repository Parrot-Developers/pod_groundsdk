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

/// Update file upload state.
public enum MissionUpdaterUploadState: CustomStringConvertible, Equatable {

    /// Update files are currently being upload.
    case uploading

    /// The request update file has successfully been upload.
    case success

    /// The requested update file failed to be uploaded.
    case failed(error: MissionUpdaterError)

    /// Debug description.
    public var description: String {
        switch self {
        case .uploading:  return "uploading"
        case .success:      return "success"
        case .failed(let error): return "failed \(error)"
        }
    }

    public static func == (lhs: MissionUpdaterUploadState, rhs: MissionUpdaterUploadState) -> Bool {
        switch (lhs, rhs) {
        case (let .failed(error1), let .failed(error2)):
            return error1 == error2
        case (.uploading, .uploading):
            return true
        case (.success, .success):
            return true
        default:
            return false
        }
    }
}

/// Updater error
public enum MissionUpdaterError: Error {
    /// mission file is not well formed.
    case badMissionFile
    /// Server error.
    case serverError
    /// Connection error.
    case connectionError
    /// Request sent had an error.
    case badRequest
    /// Upload has been canceled.
    case canceled
    /// Another upload is already in progress.
    case busy
    /// Mission already installed but overwrite parameter set to false.
    case missionAlreadyExists
    /// Installation of mission failed.
    case installationFailed
    ///  No space left to install mission in internal storage.
    case noSpaceLeft
    /// Api called to install mission is incorrect.
    case incorrectMethod
    /// Sginature of mission is invalid
    case invalidSignature
    /// Mission version does not match with drone version.
    case versionMismatch
    /// Target model of mission does not match with drone model.
    case modelMismatch
    /// Something is wrong in info file.
    case badInfoFile
    /// File is corrupted or invalid.
    case corruptedFile

    /// Debug description.
    public var description: String {
        switch self {
        case .badMissionFile:       return "badMissionFile"
        case .serverError:          return "serverError"
        case .connectionError:      return "connectionError"
        case .badRequest:           return "badRequest"
        case .canceled:             return "canceled"
        case .busy:                 return "busy"
        case .missionAlreadyExists: return "missionAlreadyExists"
        case .installationFailed:   return "installationFailed"
        case .noSpaceLeft:          return "noSpaceLeft"
        case .incorrectMethod:      return "incorrectMethod"
        case .invalidSignature:     return "invalidSignature"
        case .versionMismatch:      return "versionMismatch"
        case .modelMismatch:        return "modelMismatch"
        case .badInfoFile:          return "badInfoFile"
        case .corruptedFile:        return "corruptedFile"
        }
    }
}

/// Mission updater peripheral
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.missionUpdater)
/// ```

public protocol MissionUpdater: Peripheral {
    /// Array of mission
    var missions: [String: Mission] { get }

    /// Upload state of the last mission request
    var state: MissionUpdaterUploadState? { get }

    /// File path of the uploading mission
    var currentFilePath: String? { get }

    /// Progress of the upload.
    var currentProgress: Int? { get }

    /// Uploads a mission to the server.
    /// The mission is installed immediately or upon next reboot, depending on the `postpone` parameter.
    /// In any case, the mission will be activable on next reboot, the `complete` function should be called for this
    /// purpose.
    ///
    /// - Parameters:
    ///    - filePath: URL of the mission file to upload
    ///    - overwrite: `true` to overwrite any potentially existing mission with the same uid
    ///    - postpone: `true` to postpone the installation until next reboot
    ///    - makeDefault: `true` to make the uploaded mission the default one (starts at drone boot)
    func upload(filePath: URL, overwrite: Bool, postpone: Bool, makeDefault: Bool) -> CancelableCore?

    /// Deletes a mission.
    ///
    /// - Parameters:
    ///    - uid: internal id (given by the drone when the mission was installed).
    ///    - success: true if the delete was successfull, else false
    func delete(uid: String, success: @escaping (Bool) -> Void)

    /// Browses all missions.
    func browse()

    /// Completes the installation of the uploaded missions by rebooting the drone.
    func complete()
}

/// Extension providing default parameter values to functions to ensure backward compatibility.
public extension MissionUpdater {

    /// Uploads a mission to the server.
    /// The mission is installed immediately or upon next reboot, depending on the `postpone` parameter.
    /// In any case, the mission will be activable on next reboot, the `complete` function should be called for this
    /// purpose.
    ///
    /// - Parameters:
    ///    - filePath: URL of the mission file to upload
    ///    - overwrite: `true` to overwrite any potentially existing mission with the same uid
    ///    - postpone: `true` to postpone the installation until next reboot
    ///    - makeDefault: `true` to make the uploaded mission the default one (starts at drone boot)
    func upload(filePath: URL, overwrite: Bool = true, postpone: Bool = false, makeDefault: Bool = false)
        -> CancelableCore? {
            return upload(filePath: filePath, overwrite: overwrite, postpone: postpone, makeDefault: makeDefault)
    }
}

/// :nodoc:
/// Mission updater description.
public class MissionUpdaterDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = MissionUpdater
    public let uid = PeripheralUid.missionUpdater.rawValue
    public let parent: ComponentDescriptor? = nil
}
