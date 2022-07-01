// Copyright (C) 2020 Parrot Drones SAS
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
import ImageIO

/// Flight camera record anonymization descriptor
public class FcrAnonymizationDescriptor {
    // CGRect array of faces
    public var faces: [CGRect]

    // CGRect array of texts
    public var texts: [CGRect]

    /// Constructor
    ///
    /// - Parameters:
    ///     - faces: array of faces
    ///     - texts: array of texts
    public init(faces: [CGRect] = [], texts: [CGRect] = []) {
        self.faces = faces
        self.texts = texts
    }
}

/// Protocol that handles flight camera records anonymizer.
public protocol FcrAnonymizer {

    /// Anonymize picture.
    ///
    /// - Parameters:
    ///   - picture: url picture
    ///   - completion: completion callback
    func anonymize(picture: URL, completion: @escaping (FcrAnonymizationDescriptor) -> Void)

    /// Constructor
    init()
}

/// Flight camera record file
public class FlightCameraRecordFile: CustomStringConvertible {
    /// Original file path
    public var originalFile: URL

    /// Blurred file path
    public var blurFile: URL

    /// JSON file path
    public var jsonFile: URL

    /// Constructor.
    ///
    /// - Parameters:
    ///   - originalFile: original file url
    ///   - blurFile: blurred file url
    ///   - jsonFile: json file url
    public init(originalFile: URL, blurFile: URL, jsonFile: URL) {
        self.originalFile = originalFile
        self.blurFile = blurFile
        self.jsonFile = jsonFile
    }

    /// Debug description.
    public var description: String {
        return originalFile.absoluteString
    }
}

/// Flight camera record engine.
class FlightCameraRecordEngine: EngineBaseCore {

    /// Anonymization result
    private enum AnonymizationResult {
        case success
        case failure
        case abort
    }

    /// flightCameraRecordReporter facility
    private let flightCameraRecordReporter: FlightCameraRecordReporterCore

    /// Url path of the root directory where flight camera records are stored on the user device's local file system.
    ///
    /// This directory is located in the cache folder of the phone/tablet.
    ///
    /// This directory may contain:
    /// - the current work directory (see `workDir`), which may itself contain temporary flight camera records
    ///   (being currently downloaded from remote devices) and finalized flight camera records
    ///   (that are ready to be uploaded)
    /// - previous work directories, that may themselves contain finalized flight camera records, or temporary
    ///   flight camera records that failed to be downloaded completely.
    ///
    /// When the engine starts, all finalized flight camera records from all work directories are listed and
    /// queued for upload; temporary flight camera records in previous work directories
    /// (other than the work directory) are deleted. Temporary flight camera records in the work
    /// directory are left untouched.
    let engineDir: URL

    /// Url path of the current work directory where flight camera records downloaded from remote devices get stored.
    /// This directory is located in `engineDir`.
    let workDir: URL

    /// Name of the directory in which the flight camera records should be stored
    private let flightCameraRecordsLocalDirName = "FlightCameraRecords"

    /// Monitor of the connectivity changes
    private var connectivityMonitor: MonitorCore!

    /// Monitor of the userAccount changes
    private var userAccountMonitor: MonitorCore!

    /// User account information
    private var userAccountInfo: UserAccountInfoCore?

    /// Flight camera records file collector.
    private var collector: FlightCameraRecordCollector?

    /// List of flight camera records waiting for upload.
    ///
    /// This list is used as a queue: new flight camera records are added at the end, flightCameraRecord
    /// to upload is the first one. The flight camera records to upload is removed from this list after it is fully
    /// and correctly uploaded.
    ///
    /// - Note: visibility is internal for testing purposes only.
    private(set) var pendingFlightCameraRecordUrls: [URL] = []

    /// The uploader.
    /// `nil` until engine is started.
    private var uploader: FlightCameraRecordUploader?

    /// Current upload request.
    /// Kept to allow cancellation.
    private var currentUploadRequest: CancelableCore?

    /// Space quota in megabytes
    private var spaceQuotaInMb: Int = 0

    /// Flight camera record anonymizer
    public var fcrAnonymizer: FcrAnonymizer?

    /// Flight camera record engine upload queue
    private let queue = DispatchQueue(label: "com.parrot.gsdk.flightCameraRecord", qos: .background)

    /// Extension of processing camera record files
    private var processingExtension = "processing"

    /// Constructor
    ///
    /// - Parameter enginesController: engines controller
    public required init(enginesController: EnginesControllerCore) {
        ULog.d(.flightCameraRecordEngineTag, "Loading FlightCameraRecordEngine.")

        let cacheDirUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        engineDir = cacheDirUrl.appendingPathComponent(flightCameraRecordsLocalDirName, isDirectory: true)
        workDir = engineDir.appendingPathComponent(UUID().uuidString, isDirectory: true)
        spaceQuotaInMb = GroundSdkConfig.sharedInstance.flightCameraRecordQuotaMb ?? 0

        flightCameraRecordReporter = FlightCameraRecordReporterCore(store: enginesController.facilityStore)

        super.init(enginesController: enginesController)
        publishUtility(FlightCameraRecordStorageCoreImpl(engine: self))
    }

    /// Flight camera anonymizer class init.
    ///
    /// - Returns: whether the flight camera anonymize class has been found or not
    public func flightCameraAnonymizer() -> Bool {
        if let fcrConverterClassName = GroundSdkConfig.sharedInstance.fcrAnonymizerFqn {
            if let bundleName = Bundle.main.bundlePath
                .components(separatedBy: "/").last?.components(separatedBy: ".").first {
                let loadedClass: AnyClass? = Bundle.main.classNamed(bundleName + "." + fcrConverterClassName)
                if let fcrConverter = loadedClass.self as? FcrAnonymizer.Type {
                    ULog.d(.flightCameraRecordEngineTag, "Anonymizer found.")
                    self.fcrAnonymizer = fcrConverter.init()
                    return true
                } else {
                    ULog.d(.flightCameraRecordEngineTag, "Indicated anonymizer class was not found.")
                }
            }
        } else {
            ULog.d(.flightCameraRecordEngineTag, "No anonymizer class.")
        }
        return false
    }

    public override func startEngine() {
        guard flightCameraAnonymizer() else {
            ULog.d(.flightCameraRecordEngineTag, "FlightCameraRecordEngine not started: no anonymizer")
            return
        }

        ULog.d(.flightCameraRecordEngineTag, "Starting FlightCameraRecordEngine.")

        // Get the UserAccount Utility in order to know if the user changes
        let userAccountUtility = utilities.getUtility(Utilities.userAccount)!
        // get userInfo and monitor changes
        userAccountInfo = userAccountUtility.userAccountInfo
        // monitor userAccount changes
        userAccountMonitor = userAccountUtility.startMonitoring(accountDidChange: { (newInfo) in
            // If the user account changes and if private mode is set or old data upload is denied, we delete all files
            if newInfo?.changeDate != self.userAccountInfo?.changeDate
                && (newInfo?.privateMode == true
                        || (newInfo?.account != nil
                                && newInfo?.dataUploadPolicy != .deny // keep old data until upload is allowed
                                && newInfo?.oldDataPolicy == .denyUpload)) {
                ULog.d(.myparrot,
                       "User account change with private mode or old data upload denied -> delete all records")
                self.dropFlightCameraRecords()
                self.userAccountInfo = newInfo
            } else {
                self.userAccountInfo = newInfo
                self.startFlightCameraRecordUploadProcess()
            }
        })

        if spaceQuotaInMb != 0 {
            try? FileManager.cleanOldInDirectory(url: engineDir, fileExt: "json",
                                                    totalMaxSizeMb: spaceQuotaInMb, includingSubfolders: true)
            try? FileManager.cleanOldInDirectory(url: engineDir, fileExt: "jpeg",
                                                    totalMaxSizeMb: spaceQuotaInMb, includingSubfolders: true)
        }

        collector = createCollector()
        collector?.collectFlightCameraRecords { [weak self] flightCameraRecords in
            if let `self` = self, self.started {
                ULog.d(.parrotCloudFcrTag, "Records locally collected: \(flightCameraRecords)")
                self.pendingFlightCameraRecordUrls.append(contentsOf: flightCameraRecords)
                self.startFlightCameraRecordUploadProcess()
            }
        }

        connectivityMonitor = utilities.getUtility(Utilities.internetConnectivity)!
            .startMonitoring { [unowned self] internetAvailable in
                if internetAvailable {
                    ULog.d(.parrotCloudFcrTag, "Internet ready")
                    self.startFlightCameraRecordUploadProcess()
                } else {
                    ULog.d(.parrotCloudFcrTag, "Internet NOT ready")
                    self.cancelCurrentUpload()
                }
        }
        // can force unwrap because this utility is always published.
        let cloudServer = utilities.getUtility(Utilities.cloudServer)!
        uploader = FlightCameraRecordUploader(cloudServer: cloudServer)

        flightCameraRecordReporter.publish()
    }

    public override func stopEngine() {
        ULog.d(.flightCameraRecordEngineTag, "Stopping FlightCameraRecordEngine.")
        userAccountMonitor?.stop()
        userAccountMonitor = nil
        flightCameraRecordReporter.unpublish()
        cancelCurrentUpload()
        uploader = nil
        collector?.cancelCollection()
        collector = nil
        pendingFlightCameraRecordUrls = []
        connectivityMonitor?.stop()
    }

    /// Adds a flightCameraRecord to the flight camera records to be uploaded.
    ///
    /// If the upload was not started and the upload may start, it will start.
    ///
    /// - Parameter flightCameraRecordUrl: local url of the FlightCameraRecord that has just been added
    func add(flightCameraRecordUrl: URL) {
        ULog.d(.parrotCloudFcrTag, "Add a file: \(flightCameraRecordUrl)")
        pendingFlightCameraRecordUrls.append(flightCameraRecordUrl)
        startFlightCameraRecordUploadProcess()
    }

    /// Creates a collector.
    ///
    /// - Returns: a new collector
    /// - Note: Visibility is internal only for testing purposes.
    func createCollector() -> FlightCameraRecordCollector {
        return FlightCameraRecordCollector(rootDir: engineDir, workDir: workDir)
    }

    /// Starts the uploading process of flight camera record files.
    ///
    /// If an uploading process is already started, we only update the pending count.
    private func startFlightCameraRecordUploadProcess() {
        guard !flightCameraRecordReporter.isUploading else {
            flightCameraRecordReporter.update(pendingCount: pendingFlightCameraRecordUrls.count).notifyUpdated()
            ULog.d(.parrotCloudFcrTag, "Did not start FCR upload process (already uploading)")
            return
        }
        ULog.d(.parrotCloudFcrTag, "Start FCR upload process")
        processNextFlightCameraRecord()
    }

    /// Try to upload the first record of the list.
    ///
    /// It will only start the upload if the engine is not currently uploading a flightCameraRecord,
    /// if Internet connectivity is available, if user account is present, if a token is present, and if
    /// data upload is allowed.
    private func processNextFlightCameraRecord() {
        flightCameraRecordReporter.update(pendingCount: pendingFlightCameraRecordUrls.count)

        // Check if upload process can go on
        let abortReason: String?
        if userAccountInfo == nil {
            abortReason = "no account"
        } else if userAccountInfo!.token == nil || userAccountInfo!.token! == "" {
            abortReason = "no token"
        } else if userAccountInfo!.dataUploadPolicy != .full {
            abortReason = "denied by policy"
        } else if uploader == nil {
            abortReason = "no uploader"
        } else if utilities.getUtility(Utilities.internetConnectivity)?.internetAvailable == false {
            abortReason = "no internet"
        } else {
            abortReason = nil
        }

        if let reason = abortReason {
            ULog.d(.parrotCloudFcrTag, "Stop FCR upload process (\(reason))")
            flightCameraRecordReporter.update(isUploading: false).notifyUpdated()
            return
        }

        guard let baseUrl = URL(string: GroundSdkConfig.sharedInstance.flightCameraRecordServer!) else {
            ULog.d(.parrotCloudFcrTag, "Stop FCR upload process (server incorrectly configured)")
            flightCameraRecordReporter.update(isUploading: false).notifyUpdated()
            return
        }

        guard let fcrUrl = pendingFlightCameraRecordUrls.first else {
            ULog.d(.parrotCloudFcrTag, "Stop FCR upload process (no file left)")
            flightCameraRecordReporter.update(isUploading: false).notifyUpdated()
            return
        }

        ULog.d(.parrotCloudFcrTag, "Process next FCR \(fcrUrl.absoluteString)")

        guard let blurUrl = fcrUrl.blurUrl,
              let jsonUrl = fcrUrl.jsonUrl else {
            ULog.w(.parrotCloudFcrTag, "Stop FCR upload process (blur url or json url is nil)")
            flightCameraRecordReporter.update(isUploading: false).notifyUpdated()
            return
        }

        // Check file creation date with respect to old data policy
        if fcrShouldBeDiscarded(fcrUrl) {
            deleteFlightCameraRecord(at: fcrUrl, reason: "denied")
            processNextFlightCameraRecord()
            return
        }

        // Log file size
        if ULog.d(.parrotCloudFcrTag),
           let attrs = try? FileManager.default.attributesOfItem(atPath: fcrUrl.path) {
            let fileSize = attrs[.size] as? UInt64
            ULog.d(.parrotCloudFcrTag, "FCR \(fcrUrl.lastPathComponent) size: \(String(describing: fileSize))")
        }

        flightCameraRecordReporter.update(isUploading: true).notifyUpdated()

        // Anonymize FCR
        let fcrFile = FlightCameraRecordFile(originalFile: fcrUrl, blurFile: blurUrl, jsonFile: jsonUrl)
        anonymize(fcrFile) { result in
            switch result {
            case .success:
                self.uploadFlight(baseUrl: baseUrl, fcr: fcrFile)
            case .failure:
                FlightLogEngineBase.recover(file: fcrUrl)
                self.deleteFlightCameraRecordFile(at: fcrFile, reason: "error")
                self.processNextFlightCameraRecord()
            case .abort:
                self.flightCameraRecordReporter.update(isUploading: false).notifyUpdated()
            }
        }
    }

    /// Checks if the flight camera record should be discarded according to the old data policy.
    ///
    /// If old data policy is set to `denyUpload`, and file was retrieved before user authentication, the file should
    /// be discarded.
    ///
    /// - Parameter fcrUrl: url of the record to check
    /// - Returns: `true` if file should be discarded
    private func fcrShouldBeDiscarded(_ fcrUrl: URL) -> Bool {
        if userAccountInfo!.oldDataPolicy == .denyUpload {
            let discard: Bool
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fcrUrl.path),
               let creationDate = attrs[.creationDate] as? Date,
               let userDate = userAccountInfo?.changeDate {
                discard = creationDate < userDate
            } else {
                ULog.w(.parrotCloudFcrTag, "Could not check date for \(fcrUrl.lastPathComponent)")
                discard = true
            }
            return discard
        }
        return false
    }

    /// Anonymizes the given flight camera record.
    ///
    /// - Parameters:
    ///   - fcr: the record to anonymize
    ///   - completion: the closure that will be called when the process completes
    private func anonymize(_ fcr: FlightCameraRecordFile,
                           completion: @escaping (_ result: AnonymizationResult) -> Void) {
        ULog.d(.parrotCloudFcrTag, "Anonymize \(fcr.originalFile.lastPathComponent)")
        /// Check if blur & json file already exist
        if FileManager.default.fileExists(atPath: fcr.blurFile.path),
           FileManager.default.fileExists(atPath: fcr.jsonFile.path) {
            ULog.d(.parrotCloudFcrTag, "Blur and json file already created -> upload directly")
            completion(.success)
        } else {
            let fcrUrl = fcr.originalFile
            let processingFcr = fcrUrl.deletingPathExtension().appendingPathExtension(processingExtension)

            do {
                try FileManager.default.moveItem(at: fcrUrl, to: processingFcr)
            } catch {
                ULog.e(.parrotCloudFcrTag, "Failed to rename FCR to processing file \(fcrUrl.absoluteString)")
                completion(.abort)
                return
            }
            ULog.d(.parrotCloudFcrTag, "Call FCR anonymizer")
            fcrAnonymizer?.anonymize(picture: processingFcr, completion: { file in
                do {
                    try FileManager.default.moveItem(at: processingFcr, to: fcrUrl)
                } catch {
                    ULog.e(.parrotCloudFcrTag, "Failed to rename processing file to FCR \(fcrUrl.absoluteString)")
                    completion(.abort)
                    return
                }
                self.queue.async {
                    self.createBlur(originalFile: fcrUrl, descriptor: file)
                    self.createJson(originalFile: fcrUrl, descriptor: file)
                    DispatchQueue.main.async {
                        if FileManager.default.fileExists(atPath: fcr.blurFile.path),
                           FileManager.default.fileExists(atPath: fcr.jsonFile.path) {
                            completion(.success)
                        } else {
                            ULog.w(.parrotCloudFcrTag, "Blur or json is missing after anonymization")
                            GroundSdkCore.logEvent(message: "EVT:LOGS;event='blur';file="
                                                    + "'\(fcrUrl.lastPathComponent)';result='error'")
                            completion(.failure)
                        }
                    }
                }
            })
        }
    }

    /// Uploads the given flight camera record.
    ///
    /// - Parameters:
    ///    - baseUrl: url of the server
    ///    - fcr: flight camera record to upload
    private func uploadFlight(baseUrl: URL, fcr: FlightCameraRecordFile) {
        let fcrFileName = fcr.originalFile.lastPathComponent
        ULog.d(.parrotCloudFcrTag, "Start uploading \(fcrFileName)")
        guard let token = userAccountInfo?.token else {
            flightCameraRecordReporter.update(isUploading: false).notifyUpdated()
            return
        }
        guard currentUploadRequest == nil else {
            ULog.d(.parrotCloudFcrTag, "Did not upload FCR (upload request in progress)")
            flightCameraRecordReporter.update(isUploading: false).notifyUpdated()
            return
        }

        currentUploadRequest = uploader?.upload(baseUrl: baseUrl,
            flightCameraRecord: fcr,
            token: token) { fcr, error in
            self.currentUploadRequest = nil
            if let error = error {
                switch error {
                case .badRequest:
                    ULog.d(.parrotCloudFcrTag, "Upload error (bad request) \(fcrFileName)")
                    // delete file and stop uploading to avoid multiple errors
                    self.deleteFlightCameraRecordFile(at: fcr, reason: "error")
                    self.flightCameraRecordReporter.update(isUploading: false).notifyUpdated()
                case .badFlightCameraRecord:
                    ULog.d(.parrotCloudFcrTag, "Upload error (bad FCR) \(fcrFileName)")
                    self.deleteFlightCameraRecordFile(at: fcr, reason: "error")
                    self.processNextFlightCameraRecord()
                case .serverError,
                     .connectionError:
                    // Stop uploading if the server is not accessible
                    ULog.d(.parrotCloudFcrTag, "Upload error (server or connection) \(fcrFileName)")
                    self.flightCameraRecordReporter.update(isUploading: false).notifyUpdated()
                case .canceled:
                    ULog.d(.parrotCloudFcrTag, "Upload canceled \(fcrFileName)")
                    self.flightCameraRecordReporter.update(isUploading: false).notifyUpdated()
                }
            } else { // success
                ULog.d(.parrotCloudFcrTag, "FCR successfully uploaded \(fcrFileName)")
                self.deleteFlightCameraRecordFile(at: fcr, reason: "sent")
                self.processNextFlightCameraRecord()
            }
        }
    }

    /// Removes the given flight camera record from the pending ones and deletes it from the file system.
    ///
    /// - Parameters:
    ///    - fcrUrl: the URL of the record to delete
    ///    - reason: the reason why the record should be deleted
    private func deleteFlightCameraRecord(at fcrUrl: URL, reason: String) {
        ULog.d(.parrotCloudFcrTag, "Delete FCR (\(reason)) \(fcrUrl.lastPathComponent)")

        if pendingFlightCameraRecordUrls.first?.absoluteString == fcrUrl.absoluteString {
            pendingFlightCameraRecordUrls.remove(at: 0)
        } else {
            ULog.w(.parrotCloudFcrTag, "FCR to remove is not the first one of the pending list")
            // fallback
            if let index: Int = pendingFlightCameraRecordUrls
                .firstIndex(where: {$0.absoluteString == fcrUrl.absoluteString}) {
                pendingFlightCameraRecordUrls.remove(at: index)
            } else {
                ULog.w(.parrotCloudFcrTag, "FCR not found in the pending list")
            }
        }
        collector?.deleteFlightCameraRecord(at: fcrUrl)

        GroundSdkCore.logEvent(message: "EVT:LOGS;event='delete';reason='\(reason)';file='\(fcrUrl.lastPathComponent)'")
    }

    /// Removes the given flight camera record from the pending ones, and deletes it and the associated blur and json
    /// files from the file system.
    ///
    /// - Parameters:
    ///    - fcr: the record to delete
    ///    - reason: the reason why the record should be deleted
    private func deleteFlightCameraRecordFile(at fcr: FlightCameraRecordFile, reason: String) {
        collector?.deleteFlightCameraRecord(at: fcr.blurFile)
        collector?.deleteFlightCameraRecord(at: fcr.jsonFile)
        deleteFlightCameraRecord(at: fcr.originalFile, reason: reason)
    }

    /// Cancel the current upload if there is one.
    private func cancelCurrentUpload() {
        // stop current upload request
        ULog.d(.parrotCloudFcrTag, "Cancel current upload request \(String(describing: currentUploadRequest))")
        currentUploadRequest?.cancel()
        currentUploadRequest = nil
    }

    /// Deletes all locally stored flight camera records waiting to be uploaded.
    ///
    /// This is called when the user account changes. All recorded flight camera records are dropped since
    /// there is no proper user account identifier to use for upload anymore.
    private func dropFlightCameraRecords() {
        // stop the upload if any
        cancelCurrentUpload()

        pendingFlightCameraRecordUrls.forEach { url in
            collector?.deleteFlightCameraRecord(at: url)
            GroundSdkCore.logEvent(message: "EVT:LOGS;event='delete';reason='denied';file='\(url.lastPathComponent)'")
        }

        // clear all pending flight camera records
        pendingFlightCameraRecordUrls.removeAll()

        // update the facility
        flightCameraRecordReporter.update(isUploading: false).update(pendingCount: 0).notifyUpdated()
    }

    /// Creates blurred picture from a given picture.
    ///
    /// - Parameters:
    ///     - originalFile: URL of original file
    ///     - descriptor: flight camera record anonymization descriptor
    public func createBlur(originalFile: URL, descriptor: FcrAnonymizationDescriptor) {
        ULog.d(.parrotCloudFcrTag, "Create blurred picture")
        if let blurUrl = originalFile.blurUrl, !FileManager.default.fileExists(atPath: blurUrl.path),
            let image = UIImage(contentsOfFile: originalFile.path) {
            // get metadata to copy in new image.
            var data: Data?
            do {
                data = try Data(contentsOf: originalFile)
            } catch {
                ULog.w(.parrotCloudFcrTag, "Cannot get data from URL \(originalFile.absoluteString)")
                return
            }
            var xmp: CGImageMetadata?
            var exif: CFDictionary?
            if let data = data, let imageSource = CGImageSourceCreateWithData(data as CFData, nil) {
                /// xmp
                if CGImageSourceCopyMetadataAtIndex(imageSource, 0, nil) != nil {
                    xmp = CGImageSourceCopyMetadataAtIndex(imageSource, 0, nil)
                }
                /// exif
                if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) {
                    exif = imageProperties
                }

                /// anonymize image
                let imageSize = image.size
                let scale: CGFloat = image.scale
                let rect = CGRect(x: 0, y: 0, width: imageSize.width * scale, height: imageSize.height * scale)

                UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
                UIColor.white.setFill()
                var maxRadius: Double = 0.0
                for frame in descriptor.faces {
                    let newRadius = Double(max(frame.size.height, frame.size.width) * 0.1)
                    maxRadius = max(newRadius, maxRadius)
                    UIRectFill(frame)
                }
                for frame in descriptor.texts {
                    let newRadius = Double(max(frame.size.height, frame.size.width) * 0.1)
                    maxRadius = max(newRadius, maxRadius)
                    UIRectFill(frame)
                }
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                guard let filter = CIFilter(name: "CIMaskedVariableBlur") else {
                    ULog.w(.parrotCloudFcrTag, "CIMaskedVariableBlur does not exist")
                    return
                }

                let ciInput = CIImage(image: image)
                let ciMask = CIImage(image: newImage!)
                filter.setValue(ciMask, forKey: "inputMask")
                filter.setValue(ciInput, forKey: kCIInputImageKey)
                filter.setValue(maxRadius, forKey: kCIInputRadiusKey)

                let ciContext = CIContext()

                if let ciOutput = filter.outputImage, let cgImage = ciContext.createCGImage(ciOutput, from: rect) {
                    let blurredImage = UIImage(cgImage: cgImage)
                    // save image with xmp and exif
                    if let type = CGImageSourceGetType(imageSource),
                       let destination = CGImageDestinationCreateWithURL(blurUrl as CFURL, type, 1, nil),
                       let cgImage = image.cgImage, let dataNewImage = blurredImage.jpegData(compressionQuality: 0.9),
                       let sourceNewImage = CGImageSourceCreateWithData(dataNewImage as CFData, nil) {
                        ULog.d(.parrotCloudFcrTag, "Save blur file")
                        CGImageDestinationAddImageAndMetadata(destination, cgImage, (xmp), nil)
                        CGImageDestinationAddImageFromSource(destination, sourceNewImage, 0, (exif as CFDictionary?))
                        CGImageDestinationFinalize(destination)
                    }
                }
            } else {
                ULog.w(.parrotCloudFcrTag, "Cannot get metadata from image")
            }
        } else {
            ULog.d(.parrotCloudFcrTag, "Blur file already exists")
        }
    }

    /// Creates file containing picture details in JSON format.
    ///
    /// - Parameters:
    ///     - originalFile: URL of original file
    ///     - descriptor: flight camera record anonymization descriptor
    private func createJson(originalFile: URL, descriptor: FcrAnonymizationDescriptor) {
        ULog.d(.parrotCloudFcrTag, "Create JSON file")
        if let jsonUrl = originalFile.jsonUrl, !FileManager.default.fileExists(atPath: jsonUrl.path) {
            var data: Data?
            do {
                data = try Data(contentsOf: originalFile)
            } catch {
                ULog.d(.parrotCloudFcrTag, "Cannot get data from URL \(originalFile.absoluteString)")
                return
            }
            var imageSize: CGSize?
            if let imageSource = CGImageSourceCreateWithData(data! as CFData, nil) {
                if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? {
                    imageSize = CGSize(width: imageProperties[kCGImagePropertyPixelWidth] as! Int,
                                       height: imageProperties[kCGImagePropertyPixelHeight] as! Int)
                }
            }
            if let imageSize = imageSize {
                let json = generateJson(imageSize: imageSize, descriptor: descriptor)
                // Save JSON
                if !FileManager.default.fileExists(atPath: jsonUrl.path) {
                    do {
                        try json.write(to: jsonUrl, atomically: true, encoding: String.Encoding.utf8)
                        ULog.d(.parrotCloudFcrTag, "JSON file successfully created")
                    } catch {
                        ULog.d(.parrotCloudFcrTag, "Cannot create JSON for \(originalFile.absoluteString)")
                        return
                    }
                }
            } else {
                ULog.w(.parrotCloudFcrTag, "Image size is nil")
            }
        }
    }

    /// Generate json.
    ///
    /// - Parameters:
    ///     - imageSize: image size
    ///     - descriptor: flight camera record anonymization descriptor
    /// - Returns: a json string.
    public func generateJson(imageSize: CGSize, descriptor: FcrAnonymizationDescriptor) -> String {
        var json: String = "{\"faces\":["
        for frame in descriptor.faces {
            let width = imageSize.width != 0 ? frame.width / imageSize.width : 0
            let height = imageSize.height != 0 ? frame.height / imageSize.height : 0
            let left = imageSize.width != 0 ? frame.origin.x / imageSize.width : 0
            let top = imageSize.height != 0 ? frame.origin.y / imageSize.height : 0
                json.append("{\"BoundingBox\":{\"Width\": \(width), \"Height\": \(height), \"Left\": \(left),"
                    + " \"Top\": \(top)}},")
        }
        if descriptor.faces.count > 0 {
            json.removeLast()
        }
        json.append("],\"texts\":[")
        for text in descriptor.texts {
            let width = imageSize.width != 0 ? text.width / imageSize.width : 0
            let height = imageSize.height != 0 ? text.height / imageSize.height : 0
            let left = imageSize.width != 0 ? text.origin.x / imageSize.width : 0
            let top = imageSize.height != 0 ? text.origin.y / imageSize.height : 0
                json.append("{\"BoundingBox\":{\"Width\": \(width), \"Height\": \(height), \"Left\": \(left),"
                    + " \"Top\": \(top)}},")
        }
        if descriptor.texts.count > 0 {
            json.removeLast()
        }

        json.append("]}")
        return json
    }
}

/// Private extension to URL that adds FlightRecordCameraReport url creation
extension URL {
    /// Blur Url.
    var blurUrl: URL? {
        return URL(string: self.absoluteString
            .replacingOccurrences(of: "." + self.pathExtension, with: "-blur." + self.pathExtension))
    }

    /// Json url
    var jsonUrl: URL? {
        return URL(string: self.absoluteString
            .replacingOccurrences(of: "." + self.pathExtension, with: "." + self.pathExtension + ".json"))
    }
}
