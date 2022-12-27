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

/// Mission manager backend protocol
public protocol MissionUpdaterBackend: AnyObject {

    /// Uploads a mission to the server.
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

public class MissionUpdaterCore: PeripheralCore, MissionUpdater {

    /// Implementation backend
    private unowned let backend: MissionUpdaterBackend

    public var missions: [String: Mission] {
        return _missions
    }
    private(set) public var _missions: [String: MissionCore] = [:]

    private(set) public var state: MissionUpdaterUploadState?

    private(set) public var currentFilePath: String?

    private(set) public var currentProgress: Int?

    /// Constructor
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored.
    ///   - backend: mission backend.
    public init(store: ComponentStoreCore, backend: MissionUpdaterBackend) {
        self.backend = backend
        super.init(desc: Peripherals.missionsUpdater, store: store)
    }

    public func upload(filePath: URL, overwrite: Bool, postpone: Bool, makeDefault: Bool)
        -> CancelableCore? {
            return self.backend.upload(filePath: filePath, overwrite: overwrite, postpone: postpone,
                                       makeDefault: makeDefault)
    }

    public func delete(uid: String, success: @escaping (Bool) -> Void) {
        return self.backend.delete(uid: uid, success: success)
    }

    public func browse() {
        self.backend.browse()
    }

    public func complete() {
        self.backend.complete()
    }
}

extension MissionUpdaterCore {
    ///  Updates the upload state.
    ///
    /// - Parameter state: new upload state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(state newValue: MissionUpdaterUploadState?) -> MissionUpdaterCore {
        if self.state != newValue {
            self.state = newValue
            markChanged()
        }
        return self
    }

    ///  Updates the upload progress.
    ///
    /// - Parameter progress: new update progress
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(progress newValue: Int?) -> MissionUpdaterCore {
        if self.currentProgress != newValue {
            self.currentProgress = newValue
            markChanged()
        }
        return self
    }

    ///  Updates the file path.
    ///
    /// - Parameter filePath: new file path
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(filePath newValue: String?) -> MissionUpdaterCore {
        if self.currentFilePath != newValue {
            self.currentFilePath = newValue
            markChanged()
        }
        return self
    }

    ///  Updates the missions array
    ///
    /// - Parameter missions: new missions array
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(missions newValue: [String: MissionCore]) -> MissionUpdaterCore {
        if _missions != newValue {
            _missions = newValue
            markChanged()
        }
        return self
    }

}
