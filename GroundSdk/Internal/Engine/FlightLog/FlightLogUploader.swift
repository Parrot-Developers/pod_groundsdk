//    Copyright (C) 2019 Parrot Drones SAS
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
import CommonCrypto

/// This object is in charge of uploading flightLog reports to the server.
class FlightLogUploader {

    /// Uploader error
    enum UploadError: Error, CustomStringConvertible {
        /// Flight log is not well formed. Hence, it can be deleted.
        case badFlightLog
        /// Server error. flightLog report should not be deleted because another try might succeed.
        case serverError
        /// Connection error, flightLog report should not be deleted because another try might succeed.
        case connectionError
        /// Request sent had an error. FlightLog report can be deleted even though the file is not corrupted to avoid
        /// infinite retry.
        /// This kind of error is a development error and can normally be fixed in the code.
        case badRequest
        /// Upload has been canceled. FlightLog report should be kept in order to retry its upload later.
        case canceled

        /// Debug description.
        var description: String {
            switch self {
            case .badFlightLog:    return "badFlightLog"
            case .serverError:     return "serverError"
            case .connectionError: return "connectionError"
            case .badRequest:      return "badRequest"
            case .canceled:        return "canceled"
          }
        }
    }

    /// Prototype of the callback of upload completion
    ///
    /// - Parameters:
    ///   - flightLogUrl: the local url of the report that should have been uploaded
    ///   - error: the error if upload was not successful, nil otherwise
    public typealias CompletionCallback = (_ flightLogUrl: URL, _ error: UploadError?) -> Void

    /// Cloud server utility
    private let cloudServer: CloudServerCore

    /// Monitor of the userAccount changes
    private var userAccountMonitor: MonitorCore!

    /// Constructor.
    ///
    /// - Parameter cloudServer: the cloud server to upload reports with
    init(cloudServer: CloudServerCore) {
        self.cloudServer = cloudServer
    }

    /// Upload a flightLog report on Parrot cloud server.
    ///
    /// - Parameters:
    ///   - baseUrl: the base url.
    ///   - flightLogUrl: the local url of the flightLog report to upload
    ///   - token: the token corresponding to the account
    ///   - completionCallback: closure that will be called when the upload completes.
    /// - Returns: a request that can be canceled.
    func upload(baseUrl: URL, flightLogUrl: URL, token: String,
        completionCallback: @escaping CompletionCallback) -> CancelableCore {
        ULog.d(.flightLogEngineTag, "Will upload flightLog \(flightLogUrl)")
        var api: String = ""
        var sha256: String = ""

        if let data = getData(url: flightLogUrl) {
            sha256 = hexStringFromData(input: toSha256(input: data))
        }
        api = "/apiv1/flight/uploadurl"
        return getUploadUrlFromServer(baseUrl: baseUrl, api: api, flightLogUrl: flightLogUrl,
            token: token,
            sha256: sha256, completionCallback: completionCallback)
    }

    /// Get upload Url from server to upload flightLog
    ///
    /// - Parameters:
    ///   - baseUrl: server base url. Use default server URL if not provided.
    ///   - api: api to use
    ///   - token: the token corresponding to the account
    ///   - sha256: sha256 of the flight log.
    ///   - flightLogUrl: the local url of the flightLog report to upload
    ///   - completionCallback: closure that will be called when the upload completes.
    func getUploadUrlFromServer(baseUrl: URL, api: String, flightLogUrl: URL, token: String, sha256: String,
        completionCallback: @escaping CompletionCallback) -> CancelableCore {
        return cloudServer.getData(baseUrl: baseUrl, api: api, token: token, query: ["sha256": sha256], anonymous: true,
            requestCustomization: { $0.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")},
            completion: { result, data in
            /// get url from json data
            var uploadError: UploadError?

            switch result {
            case .success:
                if let data = data,
                let stringJson = String(data: data, encoding: String.Encoding.utf8),
                let arrayJson = self.convertToDictionary(string: stringJson),
                let baseString = arrayJson["upload_url"],
                let baseUrl = URL(string: baseString as! String) {
                    _ = self.sendFileToServer(baseUrl: baseUrl,
                        api: "", flightLogUrl: flightLogUrl, method: .put,
                        anonymous: true,
                        completionCallback: completionCallback)
                }
            case .httpError(let errorCode):
                switch errorCode {
                case 400,   // bad request
                     403:   // bad api called
                    uploadError = .badRequest
                case 429,   // too many requests
                     _ where errorCode >= 500:   // server error, try again later
                    uploadError = .serverError
                default:
                    // by default, blame the error on the report in order to delete it.
                    uploadError = .badFlightLog
                }
            case .error(let error):
                switch (error  as NSError).urlError {
                case .canceled:
                    uploadError = .canceled
                case .connectionError:
                    uploadError = .connectionError
                case .otherError:
                    // by default, blame the error on the report in order to delete it.
                    uploadError = .badFlightLog
                }
            case .canceled:
                uploadError = .canceled
            }
            if uploadError != nil {
                completionCallback(flightLogUrl, uploadError)
            }
        })
    }

    /// Upload a flightLog report on chosen server.
    ///
    /// - Parameters:
    ///   - baseUrl: server base url. Use default server URL if not provided.
    ///   - api: api to use
    ///   - flightLogUrl: the local url of the flightLog report to upload
    ///   - method: method to upload flightLog
    ///   - anonymous: whether the request is anonymous or not
    ///   - completionCallback: closure that will be called when the upload completes.
    /// - Returns: a request that can be canceled.
    func sendFileToServer(baseUrl: URL = CloudServerCore.defaultUrl, api: String, flightLogUrl: URL,
                               method: HttpSessionCore.SendMethod, anonymous: Bool = false,
                               completionCallback: @escaping CompletionCallback) -> CancelableCore {
        return cloudServer.sendFile(
            baseUrl: baseUrl,
            api: api,
            fileUrl: flightLogUrl, method: method,
            anonymous: anonymous,
            progress: { _ in },
            completion: { result, _ in
                var httpCode: Int = 0
                var uploadError: UploadError?
                switch result {
                case .success:
                    break
                case .httpError(let errorCode):
                    httpCode = errorCode
                    switch errorCode {
                    case 400,   // bad request
                         403:   // bad api called
                        uploadError = .badRequest
                    case 429,   // too many requests
                         _ where errorCode >= 500:   // server error, try again later
                        uploadError = .serverError
                    default:
                        // by default, blame the error on the report in order to delete it.
                        uploadError = .badFlightLog
                    }
                case .error(let error):
                    switch (error  as NSError).urlError {
                    case .canceled:
                        uploadError = .canceled
                    case .connectionError:
                        uploadError = .connectionError
                    case .otherError:
                        // by default, blame the error on the report in order to delete it.
                        uploadError = .badFlightLog
                    }
                case .canceled:
                    uploadError = .canceled
                }
                if let uploadError = uploadError {
                    GroundSdkCore.logEvent(message: "EVT:LOGS;event='upload';" +
                        "file='\(flightLogUrl.lastPathComponent)';" +
                        "'result='\(uploadError.description)';" +
                        "'http_error='\(httpCode)'")
                } else {
                    GroundSdkCore.logEvent(message: "EVT:LOGS;event='upload';" +
                        "file='\(flightLogUrl.lastPathComponent)';" +
                        "'result='success';" +
                        "'http_error='\(httpCode)'")
                }
                completionCallback(flightLogUrl, uploadError)
        })
    }

    /// Get sha256 from NSData
    ///
    /// - Parameter input: flightLog data
    /// - Returns: sha256 in nsdata
    private func toSha256(input: NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    /// Get data from file url.
    ///
    /// - Parameter url: flight log url
    /// - Returns: Data from file.
    private func getData(url: URL) -> NSData? {
        if FileManager.default.fileExists(atPath: url.path) {
            if let cert = NSData(contentsOfFile: url.path) {
                return cert
            }
        }
        return nil
    }

    /// Convert data to hexadecimal string.
    ///
    /// - Parameter input: data to convert in hexadecimal string
    /// - Returns: hexadecimal string.
    private func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)

        var hexString = ""
        for byte in bytes {
            hexString += String(format: "%02x", UInt8(byte))
        }

        return hexString
    }

    /// Convert string to dictionary
    ///
    /// - Parameter string: string to dictionary.
    /// - Returns: converted string.
    private func convertToDictionary(string: String) -> [String: Any]? {
        if let data = string.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                ULog.e(.flightCameraRecordStorageTag, error.localizedDescription)
            }
        }
        return nil
    }
}
