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

/// Class to store the user account informations
public class UserAccountInfoCore: Equatable, CustomStringConvertible, Codable {

    private enum CodingKeys: String, CodingKey {
        case account
        case changeDate
        case dataUploadPolicy
        case oldDataPolicy
        case privateMode
        case token
        case droneList
    }

    /// User account identifier, `nil` if none
    public let account: String?

    /// Latest user account change date
    public let changeDate: Date

    /// Data upload policy.
    public var dataUploadPolicy: DataUploadPolicy

    /// Policy to observe with regard to user data that were collected before the user decides to allow data upload.
    public var oldDataPolicy: OldDataPolicy

    /// Whether private mode is enabled.
    public var privateMode: Bool

    /// User account token, `nil` if none.
    public var token: String?

    /// List of drones linked to the account in json format
    public var droneList: String?

    /// Private Constructor for the UserAccountInfo (only public for test)
    ///
    /// - Parameters:
    ///   - account: user account identifier, `nil` if none
    ///   - changeDate: latest user account change date except for droneList
    ///   - dataUploadPolicy: policy to observe with regard to personal data from now on
    ///   - oldDataPolicy: already collected data policy to observe
    ///   - privateMode: `true` to enable private mode
    ///   - token: authentication token
    ///   - droneList: user drone list, APC JSON format
    internal init(account: String?, changeDate: Date, dataUploadPolicy: DataUploadPolicy,
                  oldDataPolicy: OldDataPolicy, privateMode: Bool = false, token: String?, droneList: String?) {
        self.account = account
        self.changeDate = changeDate
        self.dataUploadPolicy = dataUploadPolicy
        self.oldDataPolicy = oldDataPolicy
        self.privateMode = privateMode
        self.token = token
        self.droneList = droneList
    }

    /// Constructor for the UserAccountInfo (the change Date will be set at current Date)
    ///
    /// - Parameters:
    ///   - account: user account identifier, nil if none
    ///   - dataUploadPolicy: policy to observe with regard to personal data from now on
    ///   - oldDataPolicy: already collected data policy to observe
    ///   - privateMode: `true` to enable private mode
    ///   - token: authentication token
    ///   - droneList: user drone list, APC JSON format
    convenience init(account: String? = nil, dataUploadPolicy: DataUploadPolicy = .deny,
                     oldDataPolicy: OldDataPolicy = .denyUpload, privateMode: Bool = false, token: String? = nil,
                     droneList: String? = nil) {
        self.init(account: account, changeDate: Date(), dataUploadPolicy: dataUploadPolicy,
                  oldDataPolicy: oldDataPolicy, privateMode: privateMode, token: token, droneList: droneList)
    }

    /// Debug description.
    public var description: String {
        return "AccountInfo: account = \(account ?? "nil")), changeDate = \(changeDate))" +
        ", dataUploadPolicy = \(dataUploadPolicy)" +
        ", oldDataPolicy = \(oldDataPolicy)" +
        ", privateMode = \(privateMode)" +
        ", token = \(token != nil ? token! : "nil")" +
        ", droneList = \(droneList != nil ? droneList! : "nil")"
    }

    /// Equatable concordance
    public static func == (lhs: UserAccountInfoCore, rhs: UserAccountInfoCore) -> Bool {
        return lhs.account == rhs.account && lhs.changeDate == rhs.changeDate &&
            lhs.dataUploadPolicy == rhs.dataUploadPolicy &&
            lhs.oldDataPolicy == rhs.oldDataPolicy &&
            lhs.privateMode == rhs.privateMode &&
            lhs.token == rhs.token &&
            lhs.droneList == rhs.droneList
    }
}

/// Engine for UserAccount information.
/// The engine publishes the UserAccount utility and Facility
class UserAccountEngine: EngineBaseCore {

    /// Key used in UserDefaults dictionary
    private let storeDataKey = "userAccountEngine"

    private var userAccountInfo: UserAccountInfoCore? {
        didSet {
            userAccountUtilityCoreImpl.update(userAccountInfo: userAccountInfo)
            ULog.d(.myparrot, "Engine set user \(String(describing: userAccountInfo))")
        }
    }

    /// UserAccount facility (published in this Engine)
    private var userAccount: UserAccountCore!

    /// UserAccount utility (published in this Engine)
    private let userAccountUtilityCoreImpl: UserAccountUtilityCoreImpl

    private var groundSdkUserDefaults: GroundSdkUserDefaults!

    /// Constructor
    ///
    /// - Parameter enginesController: engines controller
    public required init(enginesController: EnginesControllerCore) {
        // init utilities
        userAccountUtilityCoreImpl = UserAccountUtilityCoreImpl()
        super.init(enginesController: enginesController)

        if let groundSdkUserDefaults = enginesController.groundSdkUserDefaults {
            self.groundSdkUserDefaults = groundSdkUserDefaults
        } else {
            self.groundSdkUserDefaults = GroundSdkUserDefaults(storeDataKey)
        }

        // init facilities : UserAccount
        userAccount = UserAccountCore(store: enginesController.facilityStore, backend: self)
        // reload persisting Datas
        loadData()
        ULog.d(.userAccountEngineTag, "Loading UserAccountEngine.")
        // publishes UserAccountUtility
        publishUtility(userAccountUtilityCoreImpl)
    }

    public override func startEngine() {
        ULog.d(.userAccountEngineTag, "Starting UserAccountEngine.")
        // publish facilities
        userAccount.publish()
    }

    public override func stopEngine() {
        ULog.d(.userAccountEngineTag, "Stopping UserAccountEngine.")
        // unpublish facilities
        userAccount.unpublish()
    }
}

// MARK: - UserAccountBackend
extension UserAccountEngine: UserAccountBackend {

    func set(account: String, dataUploadPolicy: DataUploadPolicy, oldDataPolicy: OldDataPolicy,
             token: String, droneList: String) {
        update(account: account, dataUploadPolicy: dataUploadPolicy, oldDataPolicy: oldDataPolicy, token: token,
               droneList: droneList)
    }

    func set(dataUploadPolicy: DataUploadPolicy, oldDataPolicy: OldDataPolicy) {
        update(dataUploadPolicy: dataUploadPolicy, oldDataPolicy: oldDataPolicy)
    }

    func set(privateMode: Bool, dataUploadPolicy: DataUploadPolicy) {
        update(dataUploadPolicy: dataUploadPolicy, privateMode: privateMode)
    }

    func set(token: String) {
        update(token: token)
    }

    func set(droneList: String) {
        update(droneList: droneList)
    }

    /// Updates the user account with the given parameters.
    ///
    /// All parameters are optional and will remain unchanged if set to `nil`, except upload policy that may change
    /// according to account and private mode.
    ///
    /// - Parameters:
    ///   - account: user account identifier
    ///   - dataUploadPolicy: policy to observe with regard to personal data from now on
    ///   - oldDataPolicy: already collected data policy to observe
    ///   - privateMode: `true` to enable private mode
    ///   - token: authentication token
    ///   - droneList: user drone list, APC JSON format
    private func update(account: String? = nil, dataUploadPolicy: DataUploadPolicy? = nil,
                        oldDataPolicy: OldDataPolicy? = nil, privateMode: Bool? = nil, token: String? = nil,
                        droneList: String? = nil) {
        let newAccount = account ?? userAccountInfo?.account
        var newUploadPolicy = dataUploadPolicy ?? userAccountInfo?.dataUploadPolicy ?? .deny
        let newOldPolicy = oldDataPolicy ?? userAccountInfo?.oldDataPolicy ?? .denyUpload
        let newPrivateMode = privateMode ?? userAccountInfo?.privateMode ?? false
        let newToken = token ?? userAccountInfo?.token
        let newDroneList = droneList ?? userAccountInfo?.droneList

        if newPrivateMode {
            newUploadPolicy = .deny
        } else if newAccount == nil && newUploadPolicy != .deny {
            newUploadPolicy = .anonymous
        }

        if userAccountInfo == nil
            || userAccountInfo?.account != newAccount
            || userAccountInfo?.dataUploadPolicy != newUploadPolicy
            || userAccountInfo?.oldDataPolicy != newOldPolicy
            || userAccountInfo?.privateMode != newPrivateMode
            || userAccountInfo?.token != newToken
            || userAccountInfo?.droneList != newDroneList {

            let newDate = userAccountInfo?.changeDate == nil
                || userAccountInfo?.account != newAccount
                || userAccountInfo?.dataUploadPolicy != newUploadPolicy
                || userAccountInfo?.oldDataPolicy != newOldPolicy
                || userAccountInfo?.privateMode != newPrivateMode
                ? Date() : userAccountInfo!.changeDate

            userAccountInfo = UserAccountInfoCore(account: newAccount,
                                                  changeDate: newDate,
                                                  dataUploadPolicy: newUploadPolicy,
                                                  oldDataPolicy: newOldPolicy,
                                                  privateMode: newPrivateMode,
                                                  token: newToken,
                                                  droneList: newDroneList)
            saveData()
        }
    }

    func clear(dataUploadPolicy: DataUploadPolicy) {
        // we update the UserAccountInfo if :
        //    - if userAccountInfo does not exist
        // or - if the accountId is not nil
        // or - if the dataUploadPolicy flags changes
        // or - if the token is not nil
        // or - if the drone list is not nil
        var newUploadPolicy = dataUploadPolicy
        let privateMode = userAccountInfo?.privateMode ?? false
        if privateMode {
            newUploadPolicy = .deny
        } else if newUploadPolicy != .deny {
            newUploadPolicy = .anonymous
        }
        if userAccountInfo == nil
            || userAccountInfo?.account != nil
            || userAccountInfo?.dataUploadPolicy != newUploadPolicy
            || userAccountInfo?.token != nil
            || userAccountInfo?.droneList != nil {
            userAccountInfo = UserAccountInfoCore(dataUploadPolicy: newUploadPolicy, privateMode: privateMode)
            saveData()
        }
    }
}

// MARK: - loading and saving persisting data
extension UserAccountEngine {

    private enum PersistingDataKeys: String {
        case userAccountData
    }

    /// Save persisting data
    private func saveData() {
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(userAccountInfo)
            let savedDictionary = [PersistingDataKeys.userAccountData.rawValue: data]
            groundSdkUserDefaults.storeData(savedDictionary)
            ULog.d(.myparrot, "save user data\(String(describing: userAccountInfo))")
        } catch {
            // Handle error
            ULog.e(.userAccountEngineTag, "saveData: " + error.localizedDescription)
        }
    }

    /// Load persisting data
    private func loadData() {
        ULog.d(.myparrot, "try to load previous user")
        let loadedDictionary = groundSdkUserDefaults.loadData() as? [String: Any]
        if let accountData = loadedDictionary?[PersistingDataKeys.userAccountData.rawValue] as? Data {
            let decoder = PropertyListDecoder()
            userAccountInfo = try? decoder.decode(UserAccountInfoCore.self, from: accountData)
        } else {
            userAccountInfo = nil
        }
    }
}
