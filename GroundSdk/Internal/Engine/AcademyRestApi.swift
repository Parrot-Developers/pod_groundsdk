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

/// Rest api for Academy.
public class AcademyRestApi {

    /// Academy server.
    private let academyServer = URL(string: "https://academy.parrot.com")

    /// Base address to access the challenge api.
    private let challengeBaseApi = "/apiv1/4g/pairing/challenge"

    /// Base address to access the pairing.
    private let pairingRequestBaseApi = "/apiv2/4g/pairing"

    /// Base address to access the unpairing
    private let unpairingRequestBaseApi = "/apiv1/4g/pairing"

    /// The get drone list API.
    private let getDroneListApi = "/apiv1/drone/list"

    /// Api key.
    private var xapikey: String = "c7cnXUqugRaGTHCpo6uXQaZQsjrIxT679XTYFQml"

    /// Time stamp query parameter.
    private let queryParameterTimeStamp = "ts"

    /// Token query parameter.
    private let queryParameterToken = "token"

    /// Associate operation.
    private let operationAssociate = "associate"

    /// Cloud server utility
    private let cloudServer: CloudServerCore

    /// Constructor
    public init(cloudServer: CloudServerCore) {
        self.cloudServer = cloudServer
    }

    /// Requests challenge.
    ///
    /// - Parameters:
    ///    - userAccountToken: the user account token to send
    ///    - completion: completion callback
    public func requestChallenge(userAccountToken: String,
                                 completion: @escaping (String?) -> Void)
        -> CancelableCore? {
        if let academyServer {
            return cloudServer.getData(baseUrl: academyServer, api: challengeBaseApi,
                                       query: ["operation": operationAssociate],
                                       requestCustomization: {

                $0.setValue("Bearer \(userAccountToken)", forHTTPHeaderField: "Authorization")}
            ) { result, data in
                switch result {
                case .success(_):
                    if let data = data {
                        do {
                            let challenge =  try self.decode(data)
                            completion(challenge)
                        } catch {
                            completion(nil)
                        }
                    } else {
                        completion(nil)
                    }
                default:
                    completion(nil)
                }
            }
        }
        return nil
    }

    /// Requests pairing.
    ///
    /// - Parameters:
    ///    - userAccountToken: the user account token to send
    ///    - signedChallenge: the signed challenge to send
    ///    - certificate: the certificate to send
    ///    - completion: completion callback
    public func requestPairing(userAccountToken: String, signedChallenge: String,
                               certificate: String,
                               completion: @escaping (Bool) -> Void) -> CancelableCore? {

        var newtoken: String?
        if let data = signedChallenge.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            newtoken = message
        }

        if let academyServer, let newtoken {
            let bodyParams: [String: Any] = [
                "message": newtoken,
                "certificate": certificate,
                "certificate_encoding": "der"
            ]
            do {
                let bodyData = try JSONSerialization.data(withJSONObject: bodyParams)
                return cloudServer.sendData(baseUrl: academyServer, api: pairingRequestBaseApi,
                                            data: bodyData, method: .post,
                                            requestCustomization: {
                    $0.setValue("Bearer \(userAccountToken)", forHTTPHeaderField: "Authorization")}
                ) { result, data in
                    switch result {
                    case .success(_):
                        completion(true)
                    default:
                        completion(false)
                    }
                }
            } catch {
                completion(false)
            }
        }
        return nil
    }

    /// Requests unpairing.
    ///
    /// - Parameters:
    ///    - apcToken: the APC user account token
    ///    - commonName: the drone common name (serial number)
    ///    - completion: completion callback
    public func requestUnpairing(apcToken: String, commonName: String,
                                 completion: @escaping (CellularPairingError) -> Void) -> CancelableCore? {
        if let academyServer {
            return cloudServer.delete(baseUrl: academyServer,
                                      api: "\(unpairingRequestBaseApi)/\(commonName)",
                                      requestCustomization: {
                $0.setValue("Bearer \(apcToken)", forHTTPHeaderField: "Authorization")}
            ) { result in
                switch result {
                case .success:
                    completion(.none)
                case .httpError(let code):
                    switch code {
                    case 401:
                        completion(.invalidToken)
                    case 403:
                        completion(.badRequest)
                    case 404:
                        completion(.unpairingFailed)
                    default:
                        completion(.serverError)
                    }
                case .canceled:
                    completion(.canceled)
                default:
                    completion(.unknownError)
                }
            }
        }
        return nil
    }

    /// Gets drone list.
    ///
    /// - Parameter completion: completion closure called when the request is terminated.
    /// - Returns: a canceallable request
    public func getDroneList(apcToken: String, completion: @escaping (CellularPairingError, String?) -> Void)
        -> CancelableCore? {
        if let academyServer {
            return cloudServer.getData(baseUrl: academyServer, api: getDroneListApi,
                requestCustomization: { $0.setValue("Bearer \(apcToken)",
                                                    forHTTPHeaderField: "Authorization")}) { httpResponse, data in
                switch httpResponse {
                case .success(_):
                    if let data {
                        do {
                            if let droneList =  try self.decode(data) {
                                completion(.none, droneList)
                            }
                        } catch _ {
                            completion(.failedtoGetDroneList, nil)
                        }
                    }
                case .httpError(let error):
                    switch error {
                    case 400, 403:
                        completion(.badRequest, nil)
                    default:
                        completion(.serverError, nil)
                    }
                default:
                    completion(.unknownError, nil)
                }
            }
        } else {
            // should not happen
            return nil
        }
    }

    /// Decodes data.
    ///
    /// - Parameters:
    ///    - data: the data to decode
    ///    - allowMalformed: whether to allow malformed or not
    /// - Returns: the decoded string
    private func decode(_ data: Data, allowMalformed: Bool = false) throws -> String? {
        if allowMalformed {
            return String(decoding: data, as: UTF8.self)
        }

        guard let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
}
