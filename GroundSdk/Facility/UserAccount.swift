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

/// Policy to observe with regard to user data that were collected before the user decides to allow data upload.
@objc(GSOldDataPolicy)
public enum OldDataPolicy: Int, Codable, CustomStringConvertible {
    /// Already collected data must not be uploaded and should be deleted.
    case denyUpload
    /// Already collected data may be uploaded.
    case allowUpload

    public var description: String {
        switch self {
        case .denyUpload: return "denyUpload"
        case .allowUpload: return "allowUpload"
        }
    }
}

/// Data upload policy.
@objc(GSDataUploadPolicy)
public enum DataUploadPolicy: Int, Codable, CustomStringConvertible {
    /// Uploading data is forbidden.
    case deny
    /// Uploading anonymous data is authorized.
    case anonymous
    /// Uploading all except GPS data is authorized.
    case noGps
    /// Uploading all except media data (FCRs) is authorized.
    case noMedia
    /// Uploading all data is authorized.
    case full

    public var description: String {
        switch self {
        case .deny: return "deny"
        case .anonymous: return "anonymous"
        case .noGps: return "noGps"
        case .noMedia: return "noMedia"
        case .full: return "full"
        }
    }
}

/// Facility that allows the application to register some user account identifier.
///
/// The application may register a user account in order to allow GroundSdk to upload data that may disclose
/// user-personal information to the configured remote server. This includes:
/// - flight blackboxes,
/// - flight logs,
/// - flight camera records,
/// - full crash reports.
///
/// All HTTP requests that upload such data will include the registered user account identifier.
///
/// In the absence of such a user account, then by default GroundSdk is not allowed to upload any data to the configured
/// remote server.
///
/// However, the application may authorize GroundSdk to upload anonymous data (which do not disclose any user-personal
/// information) to the configured remote server. This includes:
/// - anonymous crash reports.
///
/// The application can opt-in anonymous data upload upon clearing any registered user account, by specifying the
/// desired data upload policy to observe.
///
/// Note that GroundSdk may always collect both anonymous and personal data from connected devices and will store them
/// on the user's device, regardless of the presence of any user account.
/// When the application eventually registers a user account, it may at that point indicate what to do with personal
/// data that were collected beforehand, by specifying the desired old data policy to observe.
///
/// User account identifiers, or absence thereof, as well as whether anonymous data upload is allowed (when no user
/// account is registered), are persisted by GroundSdk across application restarts.
///
/// By default, there is no registered user account (so personal data upload is denied), anonymous data upload is also
/// denied, and private mode is disabled.
@objc(GSUserAccount)
public protocol UserAccount: Facility {

    /// Registers a user account.
    ///
    /// Only one user account may be registered, calling this method with a different account provider or account id
    /// will erase any previously set user account.
    ///
    /// In case no user account was set beforehand, or data upload becomes allowed, the specified old data policy
    /// informs GroundSdk about what to do with user data that have already been collected on the user's device.
    ///
    /// Calling this method doesn't change private mode, and upload policy is always set to `.deny` if it is enabled.
    ///
    /// - Parameters:
    ///   - accountProvider: accountProvider identifies the account provider
    ///   - accountId: accountId identifies the account
    ///   - dataUploadPolicy: data upload policy.
    ///   - oldDataPolicy:
    ///         true: Already collected data without account may be uploaded.
    ///         false: Already collected data without account must not be uploaded and should be deleted.
    ///   - token: token.
    ///   - droneList: user drone list, APC JSON format
    @objc(setAccountProvider:accountId:dataUploadPolicy:oldDataPolicy:token:droneList:)
    func set(accountProvider: String, accountId: String, dataUploadPolicy: DataUploadPolicy,
             oldDataPolicy: OldDataPolicy, token: String, droneList: String)

    /// Sets data policies.
    ///
    /// In case a user account is present and data upload becomes allowed at any anonymization level, the specified old
    /// data policy informs GroundSdk about what to do with user data that have already been collected on the user's
    /// device while data upload was denied.
    ///
    /// In case no user account is present, only `deny` and `anonymous` upload policies are allowed and old data policy
    /// is ignored.
    ///
    /// This method has no effect if private mode is enabled.
    ///
    /// - Parameters:
    ///     - dataUploadPolicy: policy to observe with regard to data upload from now on
    ///     - oldDataPolicy: policy to observe with regard to data that were collected so far
    func set(dataUploadPolicy: DataUploadPolicy, oldDataPolicy: OldDataPolicy)

    /// Sets private mode.
    ///
    /// Private mode ensures that no data is uploaded, and that no new data is collected on the user's device.
    ///
    /// If private mode is enabled, any collected user data are cleared, and data upload policy is ignored. Otherwise,
    /// the given policy is applied.
    ///
    /// - Parameters:
    ///     - privateMode: `true` to enable private mode and clear user data, `false` to disable it
    ///     - dataUploadPolicy: policy to observe with regard to data upload from now on
    func set(privateMode: Bool, dataUploadPolicy: DataUploadPolicy)

    /// Sets the authentication token.
    ///
    /// The token can be set even if no user account is registered, e.g. for cellular pairing purpose.
    ///
    /// - Parameter token: the token to set
    func set(token: String)

    /// Sets drone list for current user account.
    ///
    /// - Parameter droneList: user drone list, APC JSON format
    ///
    /// - Note: drone list is updated only if user account exists.
    func set(droneList: String)

    /// Clears any registered user account.
    ///
    /// In the absence of any registered user account, the application may nevertheless specify a policy to observe with
    /// regard to anonymous data. Only `.deny` and `.anonymous` upload policy values are meaningful here, any other
    /// value will be treated in the same way as `.anonymous`.
    ///
    /// Calling this method doesn't change private mode, and upload policy is always set to `.deny` if it is enabled.
    ///
    /// - Parameter dataUploadPolicy: data upload policy
    func clear(dataUploadPolicy: DataUploadPolicy)
}

/// :nodoc:
/// UserAccount facility descriptor
@objc(GSUserAccountDesc)
public class UserAccountDesc: NSObject, FacilityClassDesc {
    public typealias ApiProtocol = UserAccount
    public let uid = FacilityUid.userAccount.rawValue
    public let parent: ComponentDescriptor? = nil
}
