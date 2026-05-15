// Copyright (C) 2026 Parrot Drones SAS
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

/// eSIM backend part.
public protocol ESimBackend: AnyObject {
    /// Download profile
    ///
    /// - Parameters:
    ///    - activationCode: the activation code
    ///    - confirmationCode: the confirmation code
    /// - Returns: true if the command has been sent, false otherwise
    func downloadProfile(activationCode: String, confirmationCode: String?) -> Bool

    /// Enable profile
    ///
    /// - Parameters:
    ///    - iccid: the ICCID
    ///    - enable: whether to enable the profile or not
    /// - Returns: true if the command has been sent, false otherwise
    func enableProfile(iccid: String, enable: Bool) -> Bool

    /// Delete profile
    ///
    /// - Parameter iccid: the ICCID
    /// - Returns: true if the command has been sent, false otherwise
    func deleteProfile(iccid: String) -> Bool
}

/// Internal eSIM peripheral implementation
public class ESimCore: PeripheralCore, ESim {

    /// The eSIM status
    public var status: ESimStatus {
        return _status
    }

    private var _status: ESimStatus = .notPresent

    /// The eSIM EID
    public var eid: String {
        return _eID
    }

    private var _eID: String = ""

    /// The profile list
    public var profileList: Set<ESimProfile> {
        return _profileList
    }

    private var _profileList = Set<ESimProfile>()

    /// The operation state
    public var operationState: OperationState? {
        return _operationState
    }

    private var _operationState: OperationState?

    /// implementation backend
    private unowned let backend: ESimBackend

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Default timeout
    private let defaultTimout = 30

    /// Download timeout
    private let downloadTimeout = 90

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: eSIM backend
    public init(store: ComponentStoreCore, backend: ESimBackend) {
        self.backend = backend
        super.init(desc: Peripherals.eSim, store: store)
    }

    public func downloadProfile(activationCode: String, confirmationCode: String?) -> Bool {
        if backend.downloadProfile(activationCode: activationCode, confirmationCode: confirmationCode) {
            applyState(state: OperationState.download(error: nil, profile: nil), timeoutValue: downloadTimeout)
            return true
        }
        return false
    }

    public func enableProfile(iccid: String, enable: Bool) -> Bool {
        if !profileList.filter({ profile in return profile.iccid == iccid && profile.enabled != enable }).isEmpty {
            if backend.enableProfile(iccid: iccid, enable: enable) {
                applyState(state: OperationState.enable(error: nil, iccid: iccid, enabled: enable),
                           timeoutValue: defaultTimout)
                return true
            }
        }
        return false
    }

    public func deleteProfile(iccid: String) -> Bool {
        if !profileList.filter({ profile in return profile.iccid == iccid }).isEmpty {
            if backend.deleteProfile(iccid: iccid) {
                applyState(state: OperationState.delete(error: nil, iccid: iccid), timeoutValue: defaultTimout)
                return true
            }
        }
        return false
    }

    private func applyState(state: OperationState, timeoutValue: Int) {
        update(operationState: state).notifyUpdated()
        timeout.schedule(timeout: DispatchTimeInterval.seconds(timeoutValue)) { [weak self] in
            if let `self` = self {
                self.update(operationState: nil)
                notifyUpdated()
            }
        }

    }

    /// Cancels any pending rollback.
    public func cancelRollback() {
        if timeout.isScheduled {
            timeout.cancel()
        }
    }
}

/// Backend callback methods
extension ESimCore {

    /// Updates the eSIM status.
    ///
    /// - Parameter status: the new eSIM status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(status newValue: ESimStatus) -> ESimCore {
        if _status != newValue {
            _status = newValue
            markChanged()
        }
        return self
    }

    /// Updates the eSIM EID.
    ///
    /// - Parameter status: the new eSIM EID
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(eID newValue: String) -> ESimCore {
        if _eID != newValue {
            _eID = newValue
            markChanged()
        }
        return self
    }

    /// Updates the profile list.
    ///
    /// - Parameter profileList: the new profile list
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(profileList newValue: Set<ESimProfile>) -> ESimCore {
        if _profileList != newValue {
            _profileList = newValue
            markChanged()
        }
        return self
    }

    /// Updates the profile operation status.
    ///
    /// - Parameter operationState: the new download status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(operationState newValue: OperationState?) -> ESimCore {
        if _operationState != newValue {
            _operationState = newValue
            markChanged()
        }
        return self
    }
}
