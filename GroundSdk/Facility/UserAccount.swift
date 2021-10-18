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

/// Policy to observe with regard to non-anonymous user data that were collected in the absence of a registered
/// user account, upon registration of such an account.
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
    /// Uploading anonymous is forbidden.
    case deny
    /// Anonymous
    case anonymous
    /// No gps.
    case noGps
    /// Full but without sending FCRs
    case noMedia
     /// Full
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
/// When such an identifier has been registered by the application, then flight blackboxes and full crash reports (which
/// may contain user-related information) may be uploaded to the configured remote server. Upload HTTP requests for
/// those data will contain this identifier.
///
/// When no identifier is registered, then:
///  * Flight blackboxes are neither recorded nor uploaded to the configured remote server.
///  * Only 'light' crash reports, which do not contain any user-related information, may be uploaded to the
///  configured remote server. Furthermore, in the absence of an authenticated user, this utility allows to define
///  the authorization to use anonymous data or not
@objc(GSUserAccount)
public protocol UserAccount: Facility {

    /// Registers an user account.
    ///
    /// * Only one user account may be registered, calling this method with a different account provider or account id
    /// will erase any previously set user account.
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
    /// In case no user account is present, only dataUploadPolicy (deny) and dataUploadPolicy (anonymous) upload
    /// policies are allowed and old data policy is ignored.
    /// - Parameters:
    ///     -  dataUploadPolicy: policy to observe with regard to data upload from now on
    ///     -   oldDataPolicy: policy to observe with regard to data that were collected so far
    func set(dataUploadPolicy: DataUploadPolicy, oldDataPolicy: OldDataPolicy)

    /// Sets drone list for current user account
    ///
    /// - Parameter droneList: user drone list, APC JSON format
    /// - Note: drone list is updated only if user account exists.
    func set(droneList: String)

    /// Clears any registered user account.
    ///
    /// Only dataUploadPolicy .deny  and .anonymous values are meaningful here, any other value will be treated in the
    /// same way as .anonymous
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
