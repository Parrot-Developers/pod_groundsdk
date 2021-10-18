//    Copyright (C) 2020 Parrot Drones SAS
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

/// This object is in charge of uploading flightCameraRecord reports to the server.
class FlightCameraRecordUploader {

    /// Uploader error
    enum UploadError: Error, CustomStringConvertible {
        /// Flight camera record is not well formed. Hence, it can be deleted.
        case badFlightCameraRecord
        /// Server error. flightCameraRecord report should not be deleted because another try might succeed.
        case serverError
        /// Connection error, flightCameraRecord report should not be deleted because another try might succeed.
        case connectionError
        /// Request sent had an error. FlightCameraRecord report can be deleted even though the file is not corrupted
        /// to avoid infinite retry.
        /// This kind of error is a development error and can normally be fixed in the code.
        case badRequest
        /// Upload has been canceled. FlightCameraRecord report should be kept in order to retry its upload later.
        case canceled

        /// Debug description.
        var description: String {
            switch self {
            case .badFlightCameraRecord:    return "badFlightCameraRecord"
            case .serverError:              return "serverError"
            case .connectionError:          return "connectionError"
            case .badRequest:               return "badRequest"
            case .canceled:                 return "canceled"
          }
        }
    }

    /// Prototype of the callback of upload completion
    ///
    /// - Parameters:
    ///   - flightCameraRecord: the report that should have been uploaded
    ///   - error: the error if upload was not successful, nil otherwise
    public typealias CompletionCallback = (_ flightCameraRecord: FlightCameraRecordFile,
        _ error: UploadError?) -> Void

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

    /// Upload a flightCameraRecord report on Parrot cloud server.
    ///
    /// - Parameters:
    ///   - baseUrl: the base url.
    ///   - flightCameraRecord: the flightCameraRecord report to upload
    ///   - token: the token corresponding to the account
    ///   - completionCallback: closure that will be called when the upload completes.
    /// - Returns: a request that can be canceled.
    func upload(baseUrl: URL, flightCameraRecord: FlightCameraRecordFile, token: String,
        completionCallback: @escaping CompletionCallback) -> CancelableCore {
        ULog.d(.parrotCloudFcrTag, "Will upload FlightCameraRecord \(flightCameraRecord)")
        ULog.d(.parrotCloudFcrTag, "With token \(token)")
        var api: String = ""

        api = "/apiv1/image/uploadurl"
        return getUploadUrlFromServer(baseUrl: baseUrl, api: api, flightCameraRecord: flightCameraRecord,
            token: token,
            completionCallback: completionCallback)
    }

    /// Get upload Url from server to upload flightCameraRecord
    ///
    /// - Parameters:
    ///   - baseUrl: server base url. Use default server URL if not provided.
    ///   - api: api to use
    ///   - flightCameraRecord: the flightCameraRecord report to upload
    ///   - token: the token corresponding to the account
    ///   - completionCallback: closure that will be called when the upload completes.
    func getUploadUrlFromServer(baseUrl: URL, api: String, flightCameraRecord: FlightCameraRecordFile, token: String,
        completionCallback: @escaping CompletionCallback) -> CancelableCore {
        return cloudServer.sendFile(baseUrl: baseUrl, api: api, fileUrl: flightCameraRecord.jsonFile, method: .post,
            anonymous: false, requestCustomization: { $0.setValue("Bearer \(token)",
                forHTTPHeaderField: "Authorization")}, progress: { _ in }, completion: { result, data in

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
                        api: "", flightCameraRecord: flightCameraRecord, method: .put,
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
                    uploadError = .badFlightCameraRecord
                }
            case .error(let error):
                switch (error  as NSError).urlError {
                case .canceled:
                    uploadError = .canceled
                case .connectionError:
                    uploadError = .connectionError
                case .otherError:
                    // by default, blame the error on the report in order to delete it.
                    uploadError = .badFlightCameraRecord
                }
            case .canceled:
                uploadError = .canceled
            }
            if uploadError != nil {
                completionCallback(flightCameraRecord, uploadError)
            }
        })
    }

    /// Upload a flightCameraRecord report on chosen server.
    ///
    /// - Parameters:
    ///   - baseUrl: server base url. Use default server URL if not provided.
    ///   - api: api to use
    ///   - flightCameraRecord: the flightCameraRecord report to upload
    ///   - method: method to upload flightCameraRecord
    ///   - anonymous: whether the request is anonymous or not
    ///   - completionCallback: closure that will be called when the upload completes.
    /// - Returns: a request that can be canceled.
    func sendFileToServer(baseUrl: URL = CloudServerCore.defaultUrl, api: String,
                          flightCameraRecord: FlightCameraRecordFile,
                          method: HttpSessionCore.SendMethod, anonymous: Bool = false,
                          completionCallback: @escaping CompletionCallback) -> CancelableCore {

        return cloudServer.sendFile(
            baseUrl: baseUrl,
            api: api,
            fileUrl: flightCameraRecord.blurFile, method: method,
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
                        uploadError = .badFlightCameraRecord
                    }
                case .error(let error):
                    switch (error  as NSError).urlError {
                    case .canceled:
                        uploadError = .canceled
                    case .connectionError:
                        uploadError = .connectionError
                    case .otherError:
                        // by default, blame the error on the report in order to delete it.
                        uploadError = .badFlightCameraRecord
                    }
                case .canceled:
                    uploadError = .canceled
                }
                if let uploadError = uploadError {
                    GroundSdkCore.logEvent(message: "EVT:LOGS;event='upload';" +
                        "file='\(flightCameraRecord.blurFile.lastPathComponent)';" +
                        "'result='\(uploadError.description)';" +
                        "'http_error='\(httpCode)'")
                } else {
                    GroundSdkCore.logEvent(message: "EVT:LOGS;event='upload';" +
                        "file='\(flightCameraRecord.blurFile.lastPathComponent)';" +
                        "'result='success';" +
                        "'http_error='\(httpCode)'")
                }
                completionCallback(flightCameraRecord, uploadError)
        })
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
