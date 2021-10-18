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

/// Camera2 backend.
public protocol Camera2Backend: AnyObject {
    /// Changes camera configuration.
    ///
    /// - Parameter config: new configuration
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func configure(config: Camera2ConfigCore.Config) -> Bool

    /// Changes exposure lock mode.
    ///
    /// - Parameters:
    ///   - exposureLockMode: requested exposure lock mode
    ///   - centerX: horizontal position of lock exposure region when `exposureLockMode` is `region`
    ///   - centerY: vertical position of lock exposure region when `exposureLockMode` is `region`
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(exposureLockMode: Camera2ExposureLockMode, centerX: Double?, centerY: Double?) -> Bool

    /// Changes white balance lock mode.
    ///
    /// - Parameter whiteBalanceLock: requested white balance lock mode
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(whiteBalanceLock: Camera2WhiteBalanceLockMode) -> Bool

    /// Changes media metadata.
    ///
    /// - Parameter mediaMedata: media metadata
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(mediaMetadata: [Camera2MediaMetadataType: String]) -> Bool

    /// Starts taking photo(s).
    ///
    /// - Returns: true if the command has been sent, false otherwise
    func startPhotoCapture() -> Bool

    /// Stops taking photo(s).
    ///
    /// - Returns: true if the command has been sent, false otherwise
    func stopPhotoCapture() -> Bool

    /// Starts recording.
    ///
    /// - Returns: true if the command has been sent, false otherwise
    func startRecording() -> Bool

    /// Stops recording.
    ///
    /// - Returns: true if the command has been sent, false otherwise
    func stopRecording() -> Bool

    /// Controls zoom.
    ///
    /// Unit of the `target` depends on `mode` parameter:
    ///    - `.level`: target is in zoom level.1 means no zoom.
    ///               This value will be clamped to the `maxLevel` if it is greater than this value.
    ///    - `.velocity`: value is in signed ratio (from -1 to 1) of `Camera2Params.zoomMaxSpeed` setting value.
    ///                   Negative values will produce a zoom out, positive value will zoom in.
    ///
    /// - Parameters:
    ///   - mode: mode that should be used to control zoom
    ///   - target: either level or velocity zoom target
    func control(mode: Camera2ZoomControlMode, target: Double)

    /// Resets zoom level.
    ///
    /// The camera will reset the zoom level to 1, as fast as it can.
    func resetZoomLevel()
}

/// Camera2 peripheral implementation.
public class Camera2Core: PeripheralCore, Camera2 {

    /// Implementation backend.
    private unowned let backend: Camera2Backend

    /// Store where camera components are stored.
    private var componentStore = ComponentStoreCore()

    /// Whether this camera is active.
    public private(set) var isActive: Bool = false

    /// Camera configuration.
    public var config: Camera2Config { _config }

    /// Intenal property for camera configuration.
    private var _config: Camera2ConfigCore!

    /// Exposure indicator component.
    public var exposureIndicator: Camera2ExposureIndicatorCore!

    /// Exposure lock component.
    public var exposureLock: Camera2ExposureLockCore!

    /// Media metadata component.
    public var mediaMetadata: Camera2MediaMetadataCore!

    /// Photo capture component.
    public var photoCapture: Camera2PhotoCaptureCore!

    /// Photo progress indicator component.
    public var photoProgressIndicator: Camera2PhotoProgressIndicatorCore!

    /// Video recording component.
    public var recording: Camera2RecordingCore!

    /// White balance lock component.
    public var whiteBalanceLock: Camera2WhiteBalanceLockCore!

    /// Zoom component.
    public var zoom: Camera2ZoomCore!

    /// Constructor.
    ///
    /// - Parameters:
    ///   - desc: component descriptor
    ///   - store: store where this peripheral will be stored
    ///   - backend: Camera2 backend
    ///   - initialConfig: initial camera configuration
    ///   - capabilities: camera capabilities
    public init(_ desc: ComponentDescriptor, store: ComponentStoreCore, backend: Camera2Backend,
                initialConfig: Camera2ConfigCore.Config, capabilities: Camera2ConfigCore.Capabilities) {
        self.backend = backend
        super.init(desc: desc, store: store)
        createComponents()
        _config = Camera2ConfigCore(initialConfig: initialConfig, capabilities: capabilities,
                                    didChangeDelegate: self) { [unowned self] config in
            return self.backend.configure(config: config)
        }
    }

    public func getComponent<Desc>(_ desc: Desc) -> Desc.ApiProtocol? where Desc: Camera2ComponentClassDesc {
        return componentStore.get(desc)
    }

    public func getComponent<Desc>(_ desc: Desc, observer: @escaping Ref<Desc.ApiProtocol>.Observer)
        -> Ref<Desc.ApiProtocol> where Desc: Camera2ComponentClassDesc {
        return ComponentRefCore(store: componentStore, desc: desc, observer: observer)
    }

    /// Creates camera components.
    private func createComponents() {
        exposureIndicator = Camera2ExposureIndicatorCore(store: componentStore)
        exposureLock = Camera2ExposureLockCore(store: componentStore) { [unowned self] mode, centerX, centerY in
            self.backend.set(exposureLockMode: mode, centerX: centerX, centerY: centerY)
        }
        mediaMetadata = Camera2MediaMetadataCore(store: componentStore) { [unowned self] mediaMetadata in
            self.backend.set(mediaMetadata: mediaMetadata)
        }
        photoCapture = Camera2PhotoCaptureCore(store: componentStore, backend: self)
        photoProgressIndicator = Camera2PhotoProgressIndicatorCore(store: componentStore)
        recording = Camera2RecordingCore(store: componentStore, backend: self)
        whiteBalanceLock = Camera2WhiteBalanceLockCore(store: componentStore) { [unowned self] mode in
            self.backend.set(whiteBalanceLock: mode)
        }
        zoom = Camera2ZoomCore(store: componentStore, backend: self)
    }
}

/// Backend callback methods.
extension Camera2Core {

    /// Changes active camera flag.
    ///
    /// - Parameters:
    ///   - isActive: whether camera is active
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func update(isActive newIsActive: Bool) -> Camera2Core {
        if isActive != newIsActive {
            isActive = newIsActive
            markChanged()
        }
        return self
    }

    /// Changes capabilities.
    ///
    /// - Parameters:
    ///   - capabilities: new camera capabilities
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func update(capabilities: Camera2ConfigCore.Capabilities) -> Camera2Core {
        if _config.update(capabilities: capabilities) {
            markChanged()
        }
        return self
    }

    /// Changes confifguration.
    ///
    /// - Parameters:
    ///   - config: new camera configuration
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func update(config: Camera2ConfigCore.Config) -> Camera2Core {
        if _config.update(config: config) {
            markChanged()
        }
        return self
    }

    /// Cancels any pending rollback.
    ///
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func cancelRollback() -> Camera2Core {
        if _config.cancelRollback() {
            markChanged()
        }
        photoCapture.cancelRollback()
        recording.cancelRollback()
        exposureLock.cancelRollback()
        whiteBalanceLock.cancelRollback()
        return self
    }
}

// MARK: - Camera2ZoomBackend
/// Camera zoom backend implementation.
extension Camera2Core: Camera2ZoomBackend {
    func control(mode: Camera2ZoomControlMode, target: Double) {
        backend.control(mode: mode, target: target)
    }

    func resetLevel() {
        backend.resetZoomLevel()
    }
}

// MARK: - Camera2PhotoCaptureBackend
/// Camera photo capture backend implementation.
extension Camera2Core: Camera2PhotoCaptureBackend {
    func startPhotoCapture() -> Bool {
        return backend.startPhotoCapture()
    }

    func stopPhotoCapture() -> Bool {
        return backend.stopPhotoCapture()
    }
}

// MARK: - Camera2RecordingBackend
/// Camera recording backend implementation.
extension Camera2Core: Camera2RecordingBackend {
    func startRecording() -> Bool {
        return backend.startRecording()
    }

    func stopRecording() -> Bool {
        return backend.stopRecording()
    }
}
