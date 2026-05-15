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

import Foundation

/// eSIM status
public enum ESimStatus: CustomStringConvertible {
    /// No eSIM profile present.
    case notPresent

    /// The embedded UICC is not supported. It is not possible to have multiple profiles.
    case euiccNotSupported

    /// The eSIM is ready.
    case ready

    /// Debug description.
    public var description: String {
        switch self {
        case .notPresent:        return "notPresent"
        case .euiccNotSupported: return "euiccNotSupported"
        case .ready:             return "ready"
        }
    }
}

/// Error code.
public enum ESimErrorCode: CustomStringConvertible {

    /// There is no error.
    case ok

    /// Internal error.
    case internalError

    /// Invalid Sim error.
    case invalidSim

    /// Invalid ICCID error.
    case invalidICCID

    /// Invalid profile state error.
    case invalidProfileState

    /// Disallowed by policy error.
    case disallowedByPolicy

    /// Wrong profile reenabling error.
    case wrongProfileReenabling

    /// HTTP connect failure error.
    case httpConnectFailure

    /// HTTP request failure error.
    case httpRequestFailure

    /// Invalid activation code error.
    case invalidActivationCode

    /// Confirmation code required error.
    case confirmationCodeRequired

    /// Server authentication failure error.
    case serverAuthenticationFailure

    /// Client authentication failure error.
    case clientAuthenticationFailure

    /// Unknown error
    case unknown

    /// Debug description.
    public var description: String {
        switch self {
        case .ok:                            return "ok"
        case .internalError:                 return "internalError"
        case .invalidSim:                    return "invalidSim"
        case .invalidICCID:                  return "invalidICCID"
        case .invalidProfileState:           return "invalidProfileState"
        case .disallowedByPolicy:            return "disallowedByPolicy"
        case .wrongProfileReenabling:        return "wrongProfileReenabling"
        case .httpConnectFailure:            return "httpConnectFailure"
        case .httpRequestFailure:            return "httpRequestFailure"
        case .invalidActivationCode:         return "invalidActivationCode"
        case .confirmationCodeRequired:      return "confirmationCodeRequired"
        case .serverAuthenticationFailure:   return "serverAuthenticationFailure"
        case .clientAuthenticationFailure:   return "clientAuthenticationFailure"
        case .unknown:                       return "unknown"
        }
    }
}

/// The eSIM profile
public struct ESimProfile: Hashable, CustomStringConvertible, Equatable {

    /// The profile's ICCID.
    public var iccid: String

    /// The profile's provider.
    public var provider: String

    /// Indicates whether the profile is enabled or not.
    public var enabled: Bool

    /// Constructor.
    ///
    /// - Parameters:
    ///   - iccid: the ICCID
    ///   - provider: the provider
    ///   - enabled: whether the profile is enabled or not
    public init(iccid: String, provider: String, enabled: Bool) {
        self.iccid = iccid
        self.provider = provider
        self.enabled = enabled
    }

    /// Debug description.
    public var description: String {
        return "iccid: \(iccid) provider: \(provider) enabled: \(enabled)"
    }
}

/// Operation state
public enum OperationState: Equatable {
    /// Download operation state.
    ///
    /// - Parameters:
    ///   - error: the error code
    ///   - iccid: the ICCID
    ///   - enable: whether the profile is enabled or not
    case download(error: ESimErrorCode?, profile: ESimProfile?)

    /// Enable operation state.
    ///
    /// - Parameters:
    ///   - error: the error code
    ///   - iccid: the ICCID
    ///   - enabled: whether the profile is enabled or not
    case enable(error: ESimErrorCode?, iccid: String, enabled: Bool)

    /// Delete operation state
    ///
    /// - Parameters:
    ///   - error: the error code
    ///   - iccid: the ICCID
    case delete(error: ESimErrorCode?, iccid: String)
}

/// ESIM peripheral interface.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.eSim)
/// ```
public protocol ESim: Peripheral {

    /// The eSIM status.
    var status: ESimStatus { get }

    /// The eSIM EID.
    var eid: String { get }

    /// The profile list.
    var profileList: Set<ESimProfile> { get }

    /// The operation state.
    ///
    /// `nil` when there is no operation in progress.
    var operationState: OperationState? { get }

    /// Download profile.
    ///
    /// After this call, `operationState` should return an `OperationState.Download` object enum value.
    ///
    /// - Parameters:
    ///    - activationCode: the activation code
    ///    - confirmationCode: the confirmation code
    /// - Returns: true if the command has been sent, false otherwise
    /// - Note: the activation code format is `LPA:1$sm-dp+example.com$ABC123456789`
    func downloadProfile(activationCode: String, confirmationCode: String?) -> Bool

    /// Enable profile.
    ///
    /// After this call, `operationState` should return an `OperationState.Enable` enum value.
    ///
    /// - Parameters:
    ///    - iccid: the ICCID
    ///    - enable: whether to enable the profile or not
    /// - Returns: true if the command has been sent, false otherwise
    func enableProfile(iccid: String, enable: Bool) -> Bool

    /// Delete profile.
    ///
    /// After this call, `operationState` should return an `OperationState.Delete` enum value.
    ///
    /// - Parameter iccid: the ICCID
    /// - Returns: true if the command has been sent, false otherwise
    func deleteProfile(iccid: String) -> Bool
}

/// :nodoc:
/// eSIM description
public class ESimDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = ESim
    public let uid = PeripheralUid.eSim.rawValue
    public let parent: ComponentDescriptor? = nil
}
