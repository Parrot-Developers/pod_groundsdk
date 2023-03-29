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

public protocol GlRenderSinkBackend: SinkBackend {

    /// Rendering area.
    var renderZone: CGRect {get set}

    /// Rendering scale type.
    var scaleType: GlRenderSinkScaleType {get set}

    /// Rendering padding mode.
    var paddingFill: GlRenderSinkPaddingFill {get set}

    /// Enables zebras of overexposure image zones.
    /// 'true' to enable the zebras of overexposure zone, otherwise no zebras.
    /// Must be called in the GL thread.
    /// see setZebrasThreshold(float)
    var zebrasEnabled: Bool {get set}

    /// Sets overexposure threshold for zebras.
    ///  Must be called in the GL thread.
    ///
    /// @param threshold: threshold of overexposure used by zebras, in range [0.0, 1.0].
    /// '0.0' for the maximum of zebras and '1.0' for the minimum.
    ///
    /// see enableZebras(BOOL)
    var zebrasThreshold: Double {get set}

    /// Enables Histograms computing.
    /// Must be called in the GL thread.
    /// `true` to enable histograms computing.
    var histogramsEnabled: Bool {get set}

    /// Rendering overlayer.
    /// `nil` to disable rendering overlay
    var overlayer: Overlayer? {get set}

    /// Texture loader to use for custom texture loading, `nil` to disable custom texture loading.
    var textureLoader: TextureLoader? {get set}

    /// Starts renderer.
    ///
    /// - Returns `true` if the renderer could be started, otherwise `false`
    func start() -> Bool

    /// Stops renderer.
    ///
    /// - Returns `true` if the renderer could be stopped, otherwise `false`
    func stop() -> Bool

    /// Render a frame.
    func renderFrame()
}

/// Core class for GlRenderSink.
public class GlRenderSinkCore: SinkCore, GlRenderSink {

    /// Sink configuration.
    public class Config: SinkCoreConfig {

        /// Renderer listener.
        public weak var listener: GlRenderSinkListener?

        /// Constructor
        ///
        /// - Parameter listener: renderer listener
        init(listener: GlRenderSinkListener) {
            self.listener = listener
        }
    }

    /// Sink config.
    private let config: Config

    /// Internal renderer.
    private var renderSinkBackend: GlRenderSinkBackend!

    /// Rendering area.
    public var renderZone: CGRect {
        get {
            return renderSinkBackend.renderZone
        }
        set {
            renderSinkBackend.renderZone = newValue
        }
    }

    /// Rendering scale type.
    public var scaleType: GlRenderSinkScaleType {
        get {
            return renderSinkBackend.scaleType
        }
        set {
            renderSinkBackend.scaleType = newValue
        }
    }

    /// Rendering padding mode.
    public var paddingFill: GlRenderSinkPaddingFill {
        get {
            return renderSinkBackend.paddingFill
        }
        set {
            renderSinkBackend.paddingFill = newValue
        }
    }

    /// Whether zebras are enabled.
    public var zebrasEnabled: Bool {
        get {
            return renderSinkBackend.zebrasEnabled
        }
        set {
            renderSinkBackend.zebrasEnabled = newValue
        }
    }

    /// Zebras overexposure threshold, from 0.0 to 1.0.
    public var zebrasThreshold: Double {
        get {
            return renderSinkBackend.zebrasThreshold
        }
        set {
            renderSinkBackend.zebrasThreshold = newValue
        }
    }

    /// Whether histograms are enabled.
    public var histogramsEnabled: Bool {
        get {
            return renderSinkBackend.histogramsEnabled
        }
        set {
            renderSinkBackend.histogramsEnabled = newValue
        }
    }

    /// Texture loader to render custom GL texture.
    public weak var textureLoader: TextureLoader? {
        get {
            return renderSinkBackend.textureLoader
        }
        set {
            renderSinkBackend.textureLoader = newValue
        }
    }

    /// Listener for overlay rendering.
    public weak var overlayer: Overlayer? {
        get {
            return renderSinkBackend.overlayer
        }
        set {
            renderSinkBackend.overlayer = newValue
        }
    }

    /// Overlay context.
    private var overlayContext: OverlayContextCore?

    /// Constructor.
    ///
    /// - Parameters:
    ///    - config: sink configuration
    ///    - backend: Gl render sink backend
    public init(config: Config, backend: GlRenderSinkBackend) {
        self.config = config
        super.init()
        renderSinkBackend = backend
        self.backend = backend
    }

    /// Start renderer.
    ///
    /// - Returns: 'true' on success, 'false' otherwise
    public func start() -> Bool {
        return renderSinkBackend.start()
    }

    /// Stop renderer.
    ///
    /// - Returns: 'true' on success, 'false' otherwise
    public func stop() -> Bool {
        return renderSinkBackend.stop()
    }

    /// Render a frame.
    public func renderFrame() {
        renderSinkBackend.renderFrame()
    }

    /// Creates a new GLRendererSink config.
    ///
    /// - Parameter listener: listener notified of sink events.
    ///
    /// - Returns: a new GLRendererSink config.
    static public func config(listener: GlRenderSinkListener) -> StreamSinkConfig {
        return Config(listener: listener)
    }
}

// Backend callback
extension GlRenderSinkCore {

    public func onRenderingMayStart() {
        config.listener?.onRenderingMayStart(renderer: self)
    }

    public func onRenderingMustStop() {
        config.listener?.onRenderingMustStop(renderer: self)
    }

    public func onPreferredFpsChanged(_ fps: Float) {
        config.listener?.onPreferredFpsChanged(renderer: self, fps: fps)
    }

    public func onFrameReady() {
        config.listener?.onFrameReady(renderer: self)
    }

    public func onContentZoneChange(_ zone: CGRect) {
        config.listener?.onContentZoneChange(contentZone: zone)
    }
}
