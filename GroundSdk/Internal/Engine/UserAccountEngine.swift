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
        case token
        case droneList
    }

    /// User account identifier, `nil` if none
    public let account: String?

    /// Latest user account change date
    public let changeDate: Date

    /// Indicates whether an unauthenticated user allows anonymous data communication. This flag is significant only
    /// if `account` is `nil` (ie if the user has not agreed to disclose his personal data)
    public var dataUploadPolicy: DataUploadPolicy

    /// Policy to observe with regard to non-anonymous user data that were collected in the absence of a registered
    /// user account, upon registration of such an account.
    public var oldDataPolicy: OldDataPolicy

    /// User account token, `nil` if none.
    public var token: String?

    /// List of drones linked to the account in json format
    public var droneList: String?

    /// Private Constructor for the UserAccountInfo (only public for test)
    ///
    /// - Parameters:
    ///   - account: user account identifier, `nil` if none
    ///   - changeDate: latest user account change date except for droneList
    ///   - dataUploadPolicy: whether the upload is anonymous or not
    ///   - oldDataPolicy: policy to observe with regard to non-anonymous user data
    ///     that were collected in the absence of a registered user account, upon registration of such an account
    ///   - token: authentication token
    ///   - droneList: user drone list, APC JSON format
    internal init(account: String?, changeDate: Date, dataUploadPolicy: DataUploadPolicy,
                  oldDataPolicy: OldDataPolicy, token: String?, droneList: String?) {
        self.account = account
        self.changeDate = changeDate
        self.dataUploadPolicy = dataUploadPolicy
        self.oldDataPolicy = oldDataPolicy
        self.token = token
        self.droneList = droneList
    }

    /// Constructor for the UserAccountInfo (the change Date will be set at current Date)
    ///
    /// - Parameters:
    ///   - account: user account identifier, nil if none
    ///   - dataUploadPolicy: User allows or not to disclose anonymous Data or not
    ///   - oldDataPolicy: policy to observe with regard to non-anonymous user data
    ///     that were collected in the absence of a registered user account, upon registration of such an account
    ///   - token: authentication token
    ///   - droneList: user drone list, APC JSON format
    convenience init(account: String?, dataUploadPolicy: DataUploadPolicy = .deny,
                     oldDataPolicy: OldDataPolicy = .denyUpload, token: String?, droneList: String?) {
        self.init(account: account, changeDate: Date(), dataUploadPolicy: dataUploadPolicy,
                  oldDataPolicy: oldDataPolicy, token: token, droneList: droneList)
    }

    /// Debug description.
    public var description: String {
        return "AccountInfo: account = \(account ?? "nil")), changeDate = \(changeDate))" +
        ", dataUploadPolicy = \(dataUploadPolicy)" +
        ", oldDataPolicy = \(oldDataPolicy)" +
        ", token = \(token != nil ? token! : "nil")" +
        ", droneList = \(droneList != nil ? droneList! : "nil")"
    }

    /// Equatable concordance
    public static func == (lhs: UserAccountInfoCore, rhs: UserAccountInfoCore) -> Bool {
        return lhs.account == rhs.account && lhs.changeDate == rhs.changeDate &&
            lhs.dataUploadPolicy == rhs.dataUploadPolicy &&
            lhs.oldDataPolicy == rhs.oldDataPolicy &&
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
        if userAccountInfo?.account != account
            || userAccountInfo?.oldDataPolicy != oldDataPolicy
            || userAccountInfo?.token != token || userAccountInfo?.dataUploadPolicy != dataUploadPolicy
            || userAccountInfo?.droneList != droneList {

            let date = userAccountInfo?.changeDate == nil
                || userAccountInfo?.account != account
                || userAccountInfo?.dataUploadPolicy != dataUploadPolicy
                || userAccountInfo?.oldDataPolicy != oldDataPolicy
                ? Date() : userAccountInfo!.changeDate
            userAccountInfo = UserAccountInfoCore(account: account, changeDate: date,
                                                  dataUploadPolicy: dataUploadPolicy,
                                                  oldDataPolicy: oldDataPolicy,
                                                  token: token, droneList: droneList)
            saveData()
        }
    }

    func set(dataUploadPolicy: DataUploadPolicy, oldDataPolicy: OldDataPolicy) {
        if userAccountInfo?.account != nil && userAccountInfo?.token != nil
            && userAccountInfo?.droneList != nil {
            set(account: userAccountInfo!.account!, dataUploadPolicy: dataUploadPolicy, oldDataPolicy: oldDataPolicy,
                token: userAccountInfo!.token!, droneList: userAccountInfo!.droneList!)
        } else {
            clear(dataUploadPolicy: dataUploadPolicy)
        }
    }

    func set(droneList: String) {
        // we update the drone list only if user account exists.
        if userAccountInfo?.account != nil, userAccountInfo?.droneList != droneList {
            userAccountInfo = UserAccountInfoCore(account: userAccountInfo!.account!,
                    changeDate: userAccountInfo!.changeDate,
                    dataUploadPolicy: userAccountInfo!.dataUploadPolicy,
                    oldDataPolicy: userAccountInfo!.oldDataPolicy,
                    token: userAccountInfo!.token ?? "", droneList: droneList)
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
        var dataUploadPolicyToSet = dataUploadPolicy
        if dataUploadPolicy == .noGps || dataUploadPolicy == .full
            || dataUploadPolicy == .noMedia {
            dataUploadPolicyToSet = .anonymous
        }
        if userAccountInfo == nil || userAccountInfo?.dataUploadPolicy != dataUploadPolicy ||
            userAccountInfo?.account != nil || userAccountInfo?.token != nil {
            userAccountInfo = UserAccountInfoCore(account: nil, dataUploadPolicy: dataUploadPolicyToSet,
                oldDataPolicy: OldDataPolicy.denyUpload, token: nil, droneList: nil)
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
