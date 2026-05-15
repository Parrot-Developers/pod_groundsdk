// Copyright (C) 2024 Parrot Drones SAS
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

/// Engine that manages stream sharing.
class StreamSharingEngine: EngineBaseCore {

    /// Stream sharing facility.
    private var facility: StreamSharingCore!

    /// Stream sharing manager utility.
    private var manager: StreamSharingManager?

    /// Monitor of the stream sharing changes.
    private var streamSharingMonitor: MonitorCore?

    /// Name of the directory in which the stream sharing private files should be stored.
    private let privateDirName = "stream_sharing"

    /// File system directory to write private files to (used notably for recovery).
    private let privateDir: URL

    /// Constructor.
    ///
    /// - Parameter enginesController: engines controller
    public required init(enginesController: EnginesControllerCore) {
        let cacheDirUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        privateDir = cacheDirUrl.appendingPathComponent(privateDirName, isDirectory: true)

        super.init(enginesController: enginesController)

        facility = StreamSharingCore(store: enginesController.facilityStore, backend: self)
    }

    override func startEngine() {
        do {
            try FileManager.default.createDirectory(at: privateDir, withIntermediateDirectories: true)
        } catch let err {
            ULog.e(.streamSharingTag, "Failed to create folder at \(privateDir.path): \(err)")
        }

        manager = utilities.getUtility(Utilities.streamSharingManager)

        streamSharingMonitor = manager?.startMonitoring(
            didEnable: {},
            serviceDidStart: {},
            recordingStateDidChange: { [weak self] state, file, reason in
                self?.facility._recording.update(state: state).update(file: file).update(stopReason: reason)
                self?.facility.notifyUpdated()
            },
            streamingStateDidChange: { [weak self] state, error, url in
                self?.facility._streaming.update(state: state).update(error: error).update(url: url)
                self?.facility.notifyUpdated()
            }
        )

        facility.publish()
    }

    override func stopEngine() {
        streamSharingMonitor?.stop()
        facility.unpublish()
    }
}

// Extension of the engine that implements the StreamSharing backend.
extension StreamSharingEngine: StreamSharingBackend {
    func enableStreaming(enable: Bool) {
        if enable {
            manager?.start()
        } else {
            manager?.stop()
        }
    }

    func startRecording(directory: URL, resolution: StreamSharingResolution, bitrate: Int, overlay: Bool,
                        unitSystem: OverlayUnitSystem, coordinateSystem: OverlayCoordinateSystem) {
        manager?.startRecording(mediaDir: directory, privateDir: privateDir, resolution: resolution,
                                bitrate: bitrate, overlay: overlay, unitSystem: unitSystem,
                                coordinateSystem: coordinateSystem)
    }

    func stopRecording() {
        manager?.stopRecording()
    }

    func startStreaming(url: URL, resolution: StreamSharingResolution, maxBitrate: Int, overlay: Bool,
                        unitSystem: OverlayUnitSystem, coordinateSystem: OverlayCoordinateSystem,
                        rtspTransport: StreamSharingRtspTransport) {
        manager?.startStreaming(url: url, resolution: resolution, maxBitrate: maxBitrate, overlay: overlay,
                                unitSystem: unitSystem, coordinateSystem: coordinateSystem,
                                rtspTransport: rtspTransport)
    }

    func stopStreaming() {
        manager?.stopStreaming()
    }
}
