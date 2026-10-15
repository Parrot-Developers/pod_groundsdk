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
import CryptoKit

/// Rest api for APC.
class ApcRestApi {

    /// Result of a request
    enum Result {
        /// Request succeeded
        case success
        /// Request failed
        case failed
        /// Request was canceled
        case canceled
    }

    /// An object representing the temporary user account as the REST API describes it.
    private struct TemporaryAccount: Decodable {
        enum CodingKeys: String, CodingKey {

            /// The APC token of the account
            case apcToken

            /// The user structure of the account
            case user
        }

        let apcToken: String
        let user: User
    }

    /// An object representing the user as the REST API describes it.
    private struct User: Decodable {
        enum CodingKeys: String, CodingKey {
            /// The user email
            case email
        }

        let email: String
    }

    /// The apc server URL.
    private let apcServer = URL(string: "https://accounts-api.parrot.com")

    /// The check validity API.
    private let checkValidityApi = "/V4/isvalidusertoken"

    /// The create temporary account API.
    private let createTemporaryAccountApi = "/V4/account/tmp/create"

    /// The APC secret key.
    private var apcSecretKey: String?

    /// The XCallerId header.
    private let  xCallerIdHeader = "X-callerId"

    /// The XCallerId header value.
    private var  xCallerIdHeaderValue: String?

    /// Cloud server utility
    private let cloudServer: CloudServerCore

    /// Constructor
    ///
    /// - Parameter server: the drone server that the upload should use
    init(cloudServer: CloudServerCore) {
        self.cloudServer = cloudServer
        if let xCallerId = GroundSdkConfig.sharedInstance.xCallerId {
            self.xCallerIdHeaderValue = xCallerId
        }
        if let apcSecretKey = GroundSdkConfig.sharedInstance.apcSecretKey {
            self.apcSecretKey = apcSecretKey
        }
    }

    /// Checks validity of a user account.
    ///
    /// - Parameters:
    ///   - token: user account token
    ///   - completion: completion closure called when the request is terminated.
    /// - Returns: a canceallable request
    func checkValidity(token: String, completion: @escaping (CellularPairingError, Bool) -> Void)
        -> CancelableCore? {
        guard let xCallerIdHeaderValue else {
            completion(.missingXCallerId, false)
            return nil
        }

        guard let apcSecretKey else {
            completion(.missingApcSecretKey, false)
            return nil
        }
        let date = Date()
        let time = "\(Int(date.timeIntervalSince1970))"
        if let apcServer {
            return cloudServer.getData(baseUrl: apcServer, api: checkValidityApi,
                                       query: ["apcToken": token, "ts": time,
                                               "token": md5(token + time + apcSecretKey)],
                                       requestCustomization: { $0.setValue(xCallerIdHeaderValue,
                forHTTPHeaderField: xCallerIdHeader)}) { httpResponse, _ in
                switch httpResponse {
                case .success(_):
                    completion(.none, true)
                case .httpError(let error):
                    switch error {
                    case 401:
                        completion(.none, false)
                    case 400, 403:
                        completion(.badRequest, false)
                    default:
                        completion(.serverError, false)
                    }
                default:
                    completion(.unknownError, false)
                }
            }
        } else {
            // should not happen.
            return nil
        }
    }

    /// Creates temporary account.
    ///
    /// - Parameter completion: completion closure called when the request is terminated.
    /// - Returns: a canceallable request
    func createTemporaryAccount(completion: @escaping (CellularPairingError, String?, String?) -> Void)
        -> CancelableCore? {
        guard let xCallerIdHeaderValue else {
            completion(.missingXCallerId, nil, nil)
            return nil
        }

        guard let apcSecretKey else {
            completion(.missingApcSecretKey, nil, nil)
            return nil
        }
        let date = Date()
        let time = "\(Int(date.timeIntervalSince1970))"
        if let apcServer {
            return cloudServer.sendData(baseUrl: apcServer, api: createTemporaryAccountApi, data: nil, method: .post,
                                        query: ["ts": time, "token": md5(time + apcSecretKey)],
                                        requestCustomization: { $0.setValue(xCallerIdHeaderValue,
                                            forHTTPHeaderField: xCallerIdHeader)}) { httpResponse, data in
                switch httpResponse {
                case .success(_):
                    if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            let userAccountValidity = try decoder.decode(TemporaryAccount.self, from: data)
                            completion(.none, userAccountValidity.apcToken, userAccountValidity.user.email)
                        } catch _ {
                            completion(.failedToCreateTemporaryAccount, nil, nil)
                        }
                    }
                case .httpError(let error):
                    switch error {
                    case 400, 403:
                        completion(.badRequest, nil, nil)
                    default:
                        completion(.serverError, nil, nil)
                    }
                default:
                    completion(.unknownError, nil, nil)
                }
            }
        } else {
            // should not happen.
            return nil
        }
    }

    /// MD5 of a string
    ///
    /// - Parameter string: the string.
    /// - Returns: the md5 string
    private func md5(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    /// Decodes data.
    ///
    /// - Parameters:
    ///   - data: the data to decode
    /// - Returns: the decoded string
    private func decode(_ data: Data) throws -> String? {
        guard let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
}
