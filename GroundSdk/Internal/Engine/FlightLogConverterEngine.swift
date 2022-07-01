//    Copyright (C) 2021 Parrot Drones SAS
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

/// FlightLogConverter engine.
class FlightLogConverterEngine: FlightLogEngineBase {

    /// Name of the directory in which the converted logs should be stored
    private let flightLogsConverterLocalDirName = "FlightLogConverter"

    /// Gutma storage utility
    private var gutmaLogStorage: GutmaLogStorageCore!

    /// Flight log storage utility
    private var flightLogStorage: FlightLogStorageCore!

    /// Extension of GUTMAs log files
    private var outFileExtension = "gutma"

    /// Extension of processing log files
    private var processingExtension = "converting"

    /// Queue for converting flight logs to gutma
    private let queue = DispatchQueue(label: "com.parrot.gsdk.flightLogConverter")

    /// Constructor
    ///
    /// - Parameter enginesController: engines controller
    public required init(enginesController: EnginesControllerCore) {
        ULog.d(.flightLogConverterEngineTag, "Loading FlightLogConverterEngine.")
        super.init(enginesController: enginesController, engineDirName: flightLogsConverterLocalDirName)
        publishUtility(FlightLogConverterStorageCoreImpl(engine: self))
    }

    public override func startEngine() {
        super.startEngine()
        ULog.d(.flightLogConverterEngineTag, "Starting FlightLogConverterEngine.")
        gutmaLogStorage =  utilities.getUtility(Utilities.gutmaLogStorage)
        flightLogStorage =  utilities.getUtility(Utilities.flightLogStorage)
    }

    public override func stopEngine() {
        ULog.d(.flightLogConverterEngineTag, "Stopping FlightLogConverterEngine.")
        super.stopEngine()
    }

    override func queueForProcessing() {
        convertNextFlightLog()
    }

    /// Convert next flight log to gutma.
    func convertNextFlightLog() {
        // create directory to store the output GUTMA file & move to flight log storage
        do {
            if !FileManager.default.fileExists(atPath: flightLogStorage.workDir.absoluteString) {
                try FileManager.default.createDirectory(
                    at: flightLogStorage.workDir, withIntermediateDirectories: true, attributes: nil)
            }
            if !FileManager.default.fileExists(atPath: gutmaLogStorage.workDir.absoluteString) {
                try FileManager.default.createDirectory(
                    at: gutmaLogStorage.workDir, withIntermediateDirectories: true, attributes: nil)
            }
        } catch let err {
            ULog.e(.flightLogConverterEngineTag, "Failed to create folder at"
                    + "\(self.flightLogStorage.workDir.path): \(err)")
            ULog.e(.flightLogConverterEngineTag, "Failed to create folder at"
                    + "\(self.gutmaLogStorage.workDir.path): \(err)")
            return
        }

        guard let flightLog = pendingFlightLogUrls.first else {
            return
        }

        // getting the filename of the output GUTMA file
        // by changing the extension of the input flight log to the GUTMA extension
        let processingFlightLog = flightLog
            .deletingPathExtension()
            .appendingPathExtension(processingExtension)

        do {
            try FileManager.default.moveItem(at: flightLog, to: processingFlightLog)
        } catch {
            ULog.e(.fileManagerExtensionTag, "Failed to rename flight log to processing file :"
                    + "\(flightLog.absoluteString)")
            if !pendingFlightLogUrls.isEmpty {
                pendingFlightLogUrls.removeFirst()
                convertNextFlightLog()
            }
            return
        }

        let gutmaLogFileName = flightLog
            .deletingPathExtension()
            .appendingPathExtension(outFileExtension)
            .lastPathComponent
        let gutmaLog = URL(fileURLWithPath: gutmaLogFileName, relativeTo: gutmaLogStorage.workDir)

        // Call the SDKCore to convert the file
        queue.async {
            let res = FileConverterAPI.convert(processingFlightLog.path, outFile: gutmaLog.path, format: .gutma)
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                // move file in flight log storage
                let finalFlightLog = URL(fileURLWithPath: flightLog.lastPathComponent,
                                            relativeTo: strongSelf.flightLogStorage.workDir)
                    do {
                        try FileManager.default.moveItem(at: processingFlightLog, to: finalFlightLog)
                        strongSelf.flightLogStorage.notifyFlightLogReady(flightLogUrl: finalFlightLog)
                    } catch {
                        ULog.e(.fileManagerExtensionTag, "Failed to rename processing to flight log"
                                + "file :\(processingFlightLog.absoluteString)")
                        strongSelf.flightLogStorage.notifyFlightLogReady(flightLogUrl: processingFlightLog)
                    }
                switch res {
                case .STATUS_OK:
                    ULog.d(.flightLogConverterEngineTag, "flight log converted \(flightLog.lastPathComponent)")
                    strongSelf.gutmaLogStorage.notifyGutmaLogReady(gutmaLogUrl: gutmaLog)
                case .STATUS_NOFLIGHT:
                    ULog.d(.flightLogConverterEngineTag, "Flight log containing no flight was not converted to GUTMA"
                           + "\(flightLog.lastPathComponent)")
                case .STATUS_ERROR:
                    ULog.w(.flightLogConverterEngineTag, "Flight log conversion failed (status = STATUS_ERROR) for:"
                           + "\(flightLog.lastPathComponent)")
                    GroundSdkCore.logEvent(
                        message: "EVT:GUTMA;event='convert';file='\(gutmaLog.lastPathComponent)';result='error'"
                        + "code='\(res)'")
                default:
                    break
                }
                if !strongSelf.pendingFlightLogUrls.isEmpty {
                    strongSelf.pendingFlightLogUrls.removeFirst()
                    strongSelf.convertNextFlightLog()
                }
            }
        }
    }
}
