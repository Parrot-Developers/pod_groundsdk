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

/// Camera configuration parameter descriptor.
///
/// `V` is the parameter value type.
public class Camera2Param<V> {

    /// Parameter identifier.
    var id: Camera2ParamId

    /// Constructor.
    ///
    /// - Parameter id: parameter identifier
    init(_ id: Camera2ParamId) {
        self.id = id
    }
}

/// Camera configuration parameters.
public class Camera2Params {

    /// Camera operating mode.
    public static let mode = Camera2Param<Camera2Mode>(.mode)

    /// Photo capture mode.
    public static let photoMode = Camera2Param<Camera2PhotoMode>(.photoMode)

    /// Photo dynamic range.
    public static let photoDynamicRange = Camera2Param<Camera2DynamicRange>(.photoDynamicRange)

    /// Photo capture resolution.
    public static let photoResolution = Camera2Param<Camera2PhotoResolution>(.photoResolution)

    /// Photo capture format.
    public static let photoFormat = Camera2Param<Camera2PhotoFormat>(.photoFormat)

    /// Photo capture file format.
    public static let photoFileFormat = Camera2Param<Camera2PhotoFileFormat>(.photoFileFormat)

    /// Photo digital signature.
    public static let photoDigitalSignature = Camera2Param<Camera2DigitalSignature>(.photoDigitalSignature)

    /// Bracketing value when photo mode is `bracketing`.
    public static let photoBracketing = Camera2Param<Camera2BracketingValue>(.photoBracketing)

    /// Photo burst value when photo mode is `burst`.
    public static let photoBurst = Camera2Param<Camera2BurstValue>(.photoBurst)

    /// Time-lapse interval when the photo mode is `timeLapse`, in seconds.
    public static let photoTimelapseInterval = Camera2Param<Double>(.photoTimelapseInterval)

    /// GPS-lapse interval when the photo mode is `gpsLapse`, in meters.
    public static let photoGpslapseInterval = Camera2Param<Double>(.photoGpslapseInterval)

    /// Photo streaming mode during photo capture.
    public static let photoStreamingMode = Camera2Param<Camera2PhotoStreamingMode>(.photoStreamingMode)

    /// Video recording mode.
    public static let videoRecordingMode = Camera2Param<Camera2VideoRecordingMode>(.videoRecordingMode)

    /// Video recording dynamic range.
    public static let videoRecordingDynamicRange = Camera2Param<Camera2DynamicRange>(.videoRecordingDynamicRange)

    /// Video recording codec.
    public static let videoRecordingCodec = Camera2Param<Camera2VideoCodec>(.videoRecordingCodec)

    /// Video recording resolution.
    public static let videoRecordingResolution = Camera2Param<Camera2RecordingResolution>(.videoRecordingResolution)

    /// Video recording framerate.
    public static let videoRecordingFramerate = Camera2Param<Camera2RecordingFramerate>(.videoRecordingFramerate)

    /// Video recording bitrate.
    public static let videoRecordingBitrate = Camera2Param<UInt>(.videoRecordingBitrate)

    /// Audio recording mode.
    public static let audioRecordingMode = Camera2Param<Camera2AudioRecordingMode>(.audioRecordingMode)

    /// Automatic recording mode.
    public static let autoRecordMode = Camera2Param<Camera2AutoRecordMode>(.autoRecordMode)

    /// Exposure mode.
    public static let exposureMode = Camera2Param<Camera2ExposureMode>(.exposureMode)

    /// Exposure maximum automatic ISO sensitivity.
    public static let maximumIsoSensitivity = Camera2Param<Camera2Iso>(.maximumIsoSensitivity)

    /// Exposure manual ISO sensitivity.
    public static let isoSensitivity = Camera2Param<Camera2Iso>(.isoSensitivity)

    /// Exposure manual shutter speed.
    public static let shutterSpeed = Camera2Param<Camera2ShutterSpeed>(.shutterSpeed)

    /// Exposure compensation.
    public static let exposureCompensation = Camera2Param<Camera2EvCompensation>(.exposureCompensation)

    /// White balance mode.
    public static let whiteBalanceMode = Camera2Param<Camera2WhiteBalanceMode>(.whiteBalanceMode)

    /// Custom white balance temperature.
    public static let whiteBalanceTemperature = Camera2Param<Camera2WhiteBalanceTemperature>(.whiteBalanceTemperature)

    /// Image style.
    public static let imageStyle = Camera2Param<Camera2Style>(.imageStyle)

    /// Image contrast.
    public static let imageContrast = Camera2Param<Double>(.imageContrast)

    /// Image saturation.
    public static let imageSaturation = Camera2Param<Double>(.imageSaturation)

    /// Image sharpness.
    public static let imageSharpness = Camera2Param<Double>(.imageSharpness)

    /// Zoom maximum speed, in tan(degree)/second.
    public static let zoomMaxSpeed = Camera2Param<Double>(.zoomMaxSpeed)

    /// Zoom quality mode for velocity control.
    public static let zoomVelocityControlQualityMode
        = Camera2Param<Camera2ZoomVelocityControlQualityMode>(.zoomVelocityControlQualityMode)

    /// Alignment offset applied to the pitch axis, in degrees.
    public static let alignmentOffsetPitch = Camera2Param<Double>(.alignmentOffsetPitch)

    /// Alignment offset applied to the roll axis, in degrees.
    public static let alignmentOffsetRoll = Camera2Param<Double>(.alignmentOffsetRoll)

    /// Alignment offset applied to the yaw axis, in degrees.
    public static let alignmentOffsetYaw = Camera2Param<Double>(.alignmentOffsetYaw)

    /// Auto exposure metering mode.
    public static let autoExposureMeteringMode =
        Camera2Param<Camera2AutoExposureMeteringMode>(.autoExposureMeteringMode)

    /// Storage policy for media files.
    public static let storagePolicy = Camera2Param<Camera2StoragePolicy>(.storagePolicy)
}

/// Identifiers of camera configuration parameters.
public enum Camera2ParamId: Int, CaseIterable {
    case mode, photoMode, photoDynamicRange, photoResolution, photoFormat, photoFileFormat,
    photoDigitalSignature, photoBracketing, photoBurst, photoTimelapseInterval, photoGpslapseInterval,
    photoStreamingMode, videoRecordingMode, videoRecordingDynamicRange, videoRecordingCodec,
    videoRecordingResolution, videoRecordingFramerate, videoRecordingBitrate,
    audioRecordingMode, autoRecordMode, exposureMode, maximumIsoSensitivity,
    isoSensitivity, shutterSpeed, exposureCompensation, whiteBalanceMode, whiteBalanceTemperature, imageStyle,
    imageContrast, imageSaturation, imageSharpness, zoomMaxSpeed, zoomVelocityControlQualityMode,
    alignmentOffsetPitch, alignmentOffsetRoll, alignmentOffsetYaw, autoExposureMeteringMode, storagePolicy
}

/// Base class for camera configuration parameter.
public class Camera2ParamBase<T: Hashable> {

    /// Overall supported values for this parameter,
    /// disregarding any constraints imposed by the current values of other parameters.
    public var overallSupportedValues: Set<T> { [] }

    /// Supported values for this parameter in the current configuration,
    /// with regard to the current values of all other config parameters.
    ///
    /// When empty, this parameter is not supported in the current configuration,
    /// and the corresponding `value` should be considered irrelevant.
    public var currentSupportedValues: Set<T> { [] }
}

/// Immutable camera configuration parameter.
public class Camera2ImmutableParam<T: Hashable>: Camera2ParamBase<T> {

    /// Current parameter value.
    ///
    /// When `currentSupportedValues` is empty, this value is random and should be considered irrelevant.
    public let value: T

    /// Constructor.
    ///
    /// - Parameter value: parameter value
    init(value: T) {
        self.value = value
    }
}

/// Mutable camera configuration parameter.
public class Camera2EditableParam<T: Hashable>: Camera2ParamBase<T> {

    /// Current parameter value, or `nil` if the parameter is cleared.
    ///
    /// Setting this value:
    /// - outside of `overallSupportedValues` does nothing,
    /// - outside of `currentSupportedValues` is accepted, however any conflicting parameters will be cleared,
    /// - to `nil` clears this parameter.
    public var value: T?
}

/// Base class for camera configuration parameter of type `Double`.
public class Camera2DoubleBase {

    /// Overall supported values for this parameter,
    /// disregarding any constraints imposed by the current values of other parameters.
    public var overallSupportedValues: ClosedRange<Double>? { nil }

    /// Supported values for this parameter in the current configuration,
    /// with regard to the current values of all other config parameters.
    ///
    /// When `nil`, this parameter is not supported in the current configuration,
    /// and the corresponding `value` should be considered irrelevant.
    public var currentSupportedValues: ClosedRange<Double>? { nil }
}

/// Immutable camera configuration parameter of type `Double`.
public class Camera2Double: Camera2DoubleBase {

    /// Current parameter value.
    ///
    /// When `currentSupportedValues` is `nil`, this value is random and should be considered irrelevant.
    public let value: Double

    /// Constructor.
    ///
    /// - Parameter value: parameter value
    init(value: Double) {
        self.value = value
    }
}

/// Mutable camera configuration parameter of type `Double`.
public class Camera2EditableDouble: Camera2DoubleBase {

    /// Current parameter value, or `nil` if the parameter is cleared.
    ///
    /// Setting this value:
    /// - outside of `overallSupportedValues` does nothing,
    /// - outside of `currentSupportedValues` is accepted, however any conflicting parameters will be cleared,
    /// - to `nil` clears this parameter.
    public var value: Double?
}

/// Camera configuration editor.
public protocol Camera2Editor {

    /// Provides access to an editable configuration parameter of type `V`.
    ///
    /// - Parameter param: configuration parameter descriptor
    /// - Returns: the configuration parameter or `nil` if not supported by the drone
    subscript<V>(_ param: Camera2Param<V>) -> Camera2EditableParam<V>? { get }

    /// Provides access to an editable configuration parameter of type `Double`.
    ///
    /// - Parameter param: configuration parameter descriptor
    /// - Returns: the configuration parameter or `nil` if not supported by the drone
    subscript(_ param: Camera2Param<Double>) -> Camera2EditableDouble? { get }

    /// Whether the configuration is complete.
    ///
    /// The configuration is complete when each of the supported parameters either:
    /// - has a defined value (not `nil`) within the currently supported values for this parameter,
    /// - there are no currently supported values for this parameter.
    ///
    /// A configuration can only be commited when complete.
    var complete: Bool { get }

    /// Automatically completes this configuration.
    ///
    /// For each currently undefined parameter, sets a valid value if possible, so that the
    /// configuration is `complete` and may be committed.
    ///
    /// - Returns: `self`, to allow call chaining
    @discardableResult
    func autoComplete() -> Camera2Editor

    /// Clears current configuration.
    ///
    /// All supported parameters are cleared (their value is set to `nil`).
    ///
    /// - Returns: `self`, to allow call chaining
    @discardableResult
    func clear() -> Camera2Editor

    /// Commits this configuration.
    ///
    /// In case the current configuration is `complete`, it is applied to the camera and sent
    /// to the drone if connected.
    ///
    /// - Returns: `true` if the configuration has been successfully committed, otherwise `false`
    func commit() -> Bool
}

/// Camera configuration.
public protocol Camera2Config {
    /// Whether the configuration has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Identifiers of configuration parameters supported by the camera.
    var supportedParams: Set<Camera2ParamId> { get }

    /// Provides access to a configuration parameter of type `V`.
    ///
    /// - Parameter param: configuration parameter descriptor
    /// - Returns: the configuration parameter or `nil` if not supported by the drone
    subscript<V>(_ param: Camera2Param<V>) -> Camera2ImmutableParam<V>? { get }

    /// Provides access to a configuration parameter of type `Double`.
    ///
    /// - Parameter param: configuration parameter descriptor
    /// - Returns: the configuration parameter or `nil` if not supported by the drone
    subscript(_ param: Camera2Param<Double>) -> Camera2Double? { get }

    /// Edits camera configuration.
    ///
    /// - Parameter fromScratch: when `true` all parameters in the returned `Camera2Editor` are clearer;
    /// when `false` all parameters in the returned `Camera2Editor` hold the current camera configuration value
    /// - Returns: a configuration editor
    func edit(fromScratch: Bool) -> Camera2Editor
}
