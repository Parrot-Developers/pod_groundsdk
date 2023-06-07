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

/// Base protocol for enumerations of camera configuration parameters.
public protocol Camera2ConfigEnum: Hashable, CustomStringConvertible, CaseIterable {
}

/// Camera mode.
public enum Camera2Mode: String, Camera2ConfigEnum {
    /// Camera mode that is best suited to record videos.
    /// - Note: Depending on the device, it may also be possible to take photos while in this mode.
    case recording
    /// Camera mode that is best suited to take photos.
    case photo

    /// Debug description.
    public var description: String { rawValue }
}

/// Photo modes.
public enum Camera2PhotoMode: String, Camera2ConfigEnum {
    /// Photo mode that allows to take a single photo.
    case single
    /// Photo mode that allows to take a burst of multiple photos, each using different EV compensation values.
    case bracketing
    /// Photo mode that allows to take a burst of photos.
    case burst
    /// Photo mode that allows to take frames at a regular time interval.
    case timeLapse
    /// Photo mode that allows to take frames at a regular GPS position interval.
    case gpsLapse

    /// Debug description.
    public var description: String { rawValue }
}

/// Photo resolution.
public enum Camera2PhotoResolution: String, Camera2ConfigEnum {
    /// 48 mega pixels.
    case res48MegaPixels
    /// 12 mega pixels.
    case res12MegaPixels

    /// Debug description.
    public var description: String { rawValue }
}

/// Photo formats.
public enum Camera2PhotoFormat: String, Camera2ConfigEnum {
    /// Uses a rectilinear projection, de-warped.
    case rectilinear
    /// Uses full sensor resolution, not de-warped.
    case fullFrame
    /// Uses full sensor resolution, stabilized.
    case fullFrameStabilized

    /// Debug description.
    public var description: String { rawValue }
}

/// Photo file formats.
public enum Camera2PhotoFileFormat: String, Camera2ConfigEnum {
    /// Photo stored in JPEG format.
    case jpeg
    /// Photo stored in both DNG and JPEG formats.
    case dngAndJpeg

    /// Debug description.
    public var description: String { rawValue }
}

/// Burst value when photo mode is `burst`.
public enum Camera2BurstValue: String, Camera2ConfigEnum {
    /// Takes 14 different photos regularly over 4 seconds.
    case burst14Over4s
    /// Takes 14 different photos regularly over 2 seconds.
    case burst14Over2s
    /// Takes 14 different photos regularly over 1 seconds.
    case burst14Over1s
    /// Takes 10 different photos regularly over 4 seconds.
    case burst10Over4s
    /// Takes 10 different photos regularly over 2 seconds.
    case burst10Over2s
    /// Takes 10 different photos regularly over 1 seconds.
    case burst10Over1s
    /// Takes 4 different photos regularly over 4 seconds.
    case burst4Over4s
    /// Takes 4 different photos regularly over 3 seconds.
    case burst4Over2s
    /// Takes 4 different photos regularly over 1 seconds.
    case burst4Over1s

    /// Debug description.
    public var description: String { rawValue }
}

/// Bracketing value when photo mode is `bracketing`.
public enum Camera2BracketingValue: String, Camera2ConfigEnum {
    /// Takes 3 pictures applying, in order, -1 EV, 0 EV and +1 EV exposure compensation values.
    case preset1ev
    /// Takes 3 pictures applying, in order, -2 EV, 0 EV and +2 EV exposure compensation values.
    case preset2ev
    /// Takes 3 pictures applying, in order, -3 EV, 0 EV and +3 EV exposure compensation values.
    case preset3ev
    /// Takes 5 pictures applying, in order, -2 EV, -1 EV, 0 EV, +1 EV, and +2 EV exposure compensation values.
    case preset1ev2ev
    /// Takes 5 pictures applying, in order, -3 EV, -1 EV, 0 EV, +1 EV, and +3 EV exposure compensation values.
    case preset1ev3ev
    /// Takes 5 pictures applying, in order, -3 EV, -2 EV, 0 EV, +2 EV, and +3 EV exposure compensation values.
    case preset2ev3ev
    /// Takes 7 pictures applying, in order, -3 EV, -2 EV, -1 EV, 0 EV, +1 EV, +2 EV, and +3 EV exposure
    /// compensation values.
    case preset1ev2ev3ev

    /// Debug description.
    public var description: String { rawValue }
}

/// Photo streaming mode.
public enum Camera2PhotoStreamingMode: String, Camera2ConfigEnum {
    /// Photo capture does not interrupt streaming.
    case continuous
    /// Streaming is interrupted whenever a photo is captured.
    case interrupted

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera video recording modes.
public enum Camera2VideoRecordingMode: String, Camera2ConfigEnum {
    /// Standard recording mode.
    case standard

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera recording resolutions.
public enum Camera2RecordingResolution: String, Camera2ConfigEnum {
    /// 3840x2160 pixels (UHD 4K).
    case resUhd4k
    /// 1920x1080 pixels (Full HD).
    case res1080p

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera recording frame rates.
public enum Camera2RecordingFramerate: String, Camera2ConfigEnum {
    /// 8.6 fps
    case fps9
    /// 23.97 fps.
    case fps24
    /// 25 fps.
    case fps25
    /// 29.97 fps.
    case fps30
    /// 48 fps.
    case fps48
    /// 50 fps.
    case fps50
    /// 59.94 fps.
    case fps60
    /// 95.88 fps.
    case fps96
    /// 100 fps.
    case fps100
    /// 120 fps.
    case fps120

    /// Debug description.
    public var description: String { rawValue }
}

/// Audio recording modes.
public enum Camera2AudioRecordingMode: String, Camera2ConfigEnum {
    /// Audio recording is disabled.
    case mute
    /// Record audio from drone.
    case drone

    /// Debug description.
    public var description: String { rawValue }
}

/// Automatic recording modes.
public enum Camera2AutoRecordMode: String, Camera2ConfigEnum {
    /// Automatic recording is disabled.
    case disabled
    /// Recording starts (resp. stops) automatically when the drone takes off (resp. lands).
    case recordFlight

    /// Debug description.
    public var description: String { rawValue }
}

/// Digital signature.
public enum Camera2DigitalSignature: String, Camera2ConfigEnum {
    /// Do not sign media.
    case none
    /// Sign media using drone embedded digital signature.
    case drone

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera dynamic range.
public enum Camera2DynamicRange: String, Camera2ConfigEnum {
    /// Standard dynamic range.
    case sdr
    /// High dynamic range, 8-bit color depth.
    case hdr8
    /// High dynamic range, 10-bit color depth.
    case hdr10

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera streaming codec.
public enum Camera2VideoCodec: String, Camera2ConfigEnum {
    /// H.264 codec.
    case h264
    /// H.265 codec.
    case h265

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera image styles.
public enum Camera2Style: String, Camera2ConfigEnum {
    /// Custom style, allowing custom contrast, saturation and sharpness.
    case custom
    /// Natural look style.
    case standard
    /// Parrot Log, produce flat and desaturated images, best for post-processing.
    case plog
    /// Intense look style, providing bright colors, warm shade and high contrast.
    case intense
    /// Pastel look style, providing soft colors, cold shade and low contrast.
    case pastel
    /// Style specifically tailored for photogrammetry missions.
    case photogrammetry

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera exposure mode.
public enum Camera2ExposureMode: String, Camera2ConfigEnum {
    /// Automatic exposure mode balanced.
    ///
    /// Both shutter speed and ISO sensitivity are automatically configured by the camera, with respect to some
    /// manually configured maximum ISO sensitivity value.
    case automatic

    /// Automatic exposure mode, prefer increasing iso sensitivity.
    ///
    /// Both shutter speed and ISO sensitivity are automatically configured by the camera, with respect to some
    /// manually configured maximum ISO sensitivity value. Prefer increasing iso sensitivity over using low
    /// shutter speed. This mode provides better results when the drone is moving dynamically.
    case automaticPreferIsoSensitivity

    /// Automatic exposure mode, prefer reducing shutter speed.
    ///
    /// Both shutter speed and ISO sensitivity are automatically configured by the camera, with respect to some
    /// manually configured maximum ISO sensitivity value. Prefer reducing shutter speed over using high iso
    /// sensitivity. This mode provides better results when the when the drone is moving slowly.
    case automaticPreferShutterSpeed

    /// Manual ISO sensitivity mode.
    ///
    /// Allows to configure ISO sensitivity manually. Shutter speed is automatically configured by the camera
    /// accordingly.
    case manualIsoSensitivity

    /// Manual shutter speed mode.
    ///
    /// Allows to configure shutter speed manually. ISO sensitivity is automatically configured by the camera
    /// accordingly.
    case manualShutterSpeed

    /// Manual mode.
    ///
    /// Allows to manually configure both the camera's shutter speed and the ISO sensitivity.
    case manual

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera exposure compensation values.
public enum Camera2EvCompensation: String, Camera2ConfigEnum {
    /// -3.00 EV.
    case evMinus3_00 = "-3.00 ev"
    /// -2.67 EV.
    case evMinus2_67 = "-2.67 ev"
    /// -2.33 EV.
    case evMinus2_33 = "-2.33 ev"
    /// -2.00 EV.
    case evMinus2_00 = "-2.00 ev"
    /// -1.67 EV.
    case evMinus1_67 = "-1.67 ev"
    /// -1.33 EV.
    case evMinus1_33 = "-1.33 ev"
    /// -1.00 EV.
    case evMinus1_00 = "-1.00 ev"
    /// -0.67 EV.
    case evMinus0_67 = "-0.67 ev"
    /// -0.33 EV.
    case evMinus0_33 = "-0.33 ev"
    /// 0.00 EV.
    case ev0_00 = "0.00 ev"
    /// +0.33 EV.
    case ev0_33 = "+0.33 ev"
    /// +0.67 EV.
    case ev0_67 = "+0.67 ev"
    /// +1.00 EV.
    case ev1_00 = "+1.00 ev"
    /// +1.33 EV.
    case ev1_33 = "+1.33 ev"
    /// +1.67 EV.
    case ev1_67 = "+1.67 ev"
    /// +2.00 EV.
    case ev2_00 = "+2.00 ev"
    /// +2.33 EV.
    case ev2_33 = "+2.33 ev"
    /// +2.67 EV.
    case ev2_67 = "+2.67 ev"
    /// +3.00 EV.
    case ev3_00 = "+3.00 ev"

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera shutter speed values.
public enum Camera2ShutterSpeed: String, Camera2ConfigEnum {
    /// 1/10000 s
    case oneOver10000 = "1/10000s"
    /// 1/8000 s
    case oneOver8000 = "1/8000s"
    /// 1/6400 s
    case oneOver6400 = "1/6400s"
    /// 1/5000 s
    case oneOver5000 = "1/5000s"
    /// 1/4000 s
    case oneOver4000 = "1/4000s"
    /// 1/3200 s
    case oneOver3200 = "1/3200s"
    /// 1/2500 s
    case oneOver2500 = "1/2500s"
    /// 1/2000 s
    case oneOver2000 = "1/2000s"
    /// 1/1600 s
    case oneOver1600 = " 1/1600s"
    /// 1/1000 s
    case oneOver1250 = "1/1250s"
    /// 1/1250 s
    case oneOver1000 = "1/1000s"
    /// 1/800 s
    case oneOver800 = "1/800s"
    /// 1/640 s
    case oneOver640 = "1/640s"
    /// 1/500 s
    case oneOver500 = "1/500s"
    /// 1/400 s
    case oneOver400 = "1/400s"
    /// 1/320 s
    case oneOver320 = "1/320s"
    /// 1/240 s
    case oneOver240 = "1/240s"
    /// 1/200 s
    case oneOver200 = "1/200s"
    /// 1/160 s
    case oneOver160 = "1/160s"
    /// 1/120 s
    case oneOver120 = "1/120s"
    /// 1/100 s
    case oneOver100 = "1/100s"
    /// 1/60 s
    case oneOver60 = "1/60s"
    /// 1/80 s
    case oneOver80 = "1/80s"
    /// 1/50 s
    case oneOver50 = "1/50s"
    /// 1/40 s
    case oneOver40 = "1/40s"
    /// 1/30 s
    case oneOver30 = "1/30s"
    /// 1/25 s
    case oneOver25 = "1/25s"
    /// 1/15 s
    case oneOver15 = "1/15s"
    /// 1/10 s
    case oneOver10 = "1/10s"
    /// 1/8 s
    case oneOver8 = "1/8s"
    /// 1/6 s
    case oneOver6 = "1/6s"
    /// 1/4 s
    case oneOver4 = "1/4s"
    /// 1/3 s
    case oneOver3 = "1/3s"
    /// 1/2 s
    case oneOver2 = "1/2s"
    /// 1/1.5 s
    case oneOver1_5 = "1/5s"
    /// 1 s
    case one = "1s"

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera exposure ISO sensitivity.
public enum Camera2Iso: String, Camera2ConfigEnum {
    /// 25 ISO.
    case iso25
    /// 50 ISO.
    case iso50
    /// 64 ISO.
    case iso64
    /// 80 ISO.
    case iso80
    /// 100 ISO.
    case iso100
    /// 125 ISO.
    case iso125
    /// 160 ISO.
    case iso160
    /// 200 ISO.
    case iso200
    /// 250 ISO.
    case iso250
    /// 320 ISO.
    case iso320
    /// 400 ISO.
    case iso400
    /// 500 ISO.
    case iso500
    /// 640 ISO.
    case iso640
    /// 800 ISO.
    case iso800
    /// 1000 ISO.
    case iso1000
    /// 1200 ISO.
    case iso1200
    /// 1600 ISO.
    case iso1600
    /// 2000 ISO.
    case iso2000
    /// 2500 ISO.
    case iso2500
    /// 3200 ISO.
    case iso3200
    /// 4000 ISO.
    case iso4000
    /// 5000 ISO.
    case iso5000
    /// 6400 ISO.
    case iso6400
    /// 8000 ISO.
    case iso8000
    /// 10000 ISO.
    case iso10000
    /// 12800 ISO.
    case iso12800
    /// 16000 ISO.
    case iso16000
    /// 20000 ISO.
    case iso20000
    /// 25600 ISO.
    case iso25600
    /// 32000 ISO.
    case iso32000
    /// 40000 ISO.
    case iso40000
    /// 51200 ISO.
    case iso51200

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera white balance modes.
public enum Camera2WhiteBalanceMode: String, Camera2ConfigEnum {
    /// White balance is automatically configured based on the current environment.
    case automatic
    /// Predefined white balance mode for environments lighted by candles.
    case candle
    /// Predefined white balance mode for use sunset lighted environments.
    case sunset
    /// Predefined white balance mode for environments lighted by incandescent light.
    case incandescent
    /// Predefined white balance mode for environments lighted by warm white fluorescent light.
    case warmWhiteFluorescent
    /// Predefined white balance mode for environments lighted by halogen light.
    case halogen
    /// Predefined white balance mode for environments lighted by fluorescent light.
    case fluorescent
    /// Predefined white balance mode for environments lighted by cool white fluorescent light.
    case coolWhiteFluorescent
    /// Predefined white balance mode for environments lighted by a flash light.
    case flash
    /// Predefined white balance mode for use in day light.
    case daylight
    /// Predefined white balance mode for use in sunny weather.
    case sunny
    /// Predefined white balance mode for use in cloudy weather.
    case cloudy
    /// Predefined white balance mode for use in snowy environment.
    case snow
    /// Predefined white balance mode for use in hazy environment.
    case hazy
    /// Predefined white balance mode for use in shaded environment.
    case shaded
    /// Predefined white balance mode for green foliage images.
    case greenFoliage
    /// Predefined white balance mode for blue sky images.
    case blueSky
    /// Custom white balance. White temperature can be configured manually in this mode.
    case custom

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera white balance temperature for custom white balance mode.
public enum Camera2WhiteBalanceTemperature: String, Camera2ConfigEnum {
    /// 1500 K.
    case k1500 = "1500"
    /// 1750 K.
    case k1750 = "1750"
    /// 2000 K.
    case k2000 = "2000"
    /// 2250 K.
    case k2250 = "2250"
    /// 2500 K.
    case k2500 = "2500"
    /// 2750 K.
    case k2750 = "2750"
    /// 3000 K.
    case k3000 = "3000"
    /// 3250 K.
    case k3250 = "3250"
    /// 3500 K.
    case k3500 = "3500"
    /// 3750 K.
    case k3750 = "3750"
    /// 4000 K.
    case k4000 = "4000"
    /// 4250 K.
    case k4250 = "4250"
    /// 4500 K.
    case k4500 = "4500"
    /// 4750 K.
    case k4750 = "4750"
    /// 5000 K.
    case k5000 = "5000"
    /// 5250 K.
    case k5250 = "5250"
    /// 5500 K.
    case k5500 = "5500"
    /// 5750 K.
    case k5750 = "5750"
    /// 6000 K.
    case k6000 = "6000"
    /// 6250 K.
    case k6250 = "6250"
    /// 6500 K.
    case k6500 = "6500"
    /// 6750 K.
    case k6750 = "6750"
    /// 7000 K.
    case k7000 = "7000"
    /// 7250 K.
    case k7250 = "7250"
    /// 7500 K.
    case k7500 = "7500"
    /// 7750 K.
    case k7750 = "7750"
    /// 8000 K.
    case k8000 = "8000"
    /// 8250 K.
    case k8250 = "8250"
    /// 8500 K.
    case k8500 = "8500"
    /// 8750 K.
    case k8750 = "8750"
    /// 9000 K.
    case k9000 = "9000"
    /// 9250 K.
    case k9250 = "9250"
    /// 9500 K.
    case k9500 = "9500"
    /// 9750 K.
    case k9750 = "9750"
    /// 10000 K.
    case k10000 = "10000"
    /// 10250 K.
    case k10250 = "10250"
    /// 10500
    case k10500 = "10500"
    /// 10750 K.
    case k10750 = "10750"
    /// 11000 K.
    case k11000 = "11000"
    /// 11250 K.
    case k11250 = "11250"
    /// 11500 K.
    case k11500 = "11500"
    /// 11750 K.
    case k11750 = "11750"
    /// 12000 K.
    case k12000 = "12000"
    /// 12250 K.
    case k12250 = "12250"
    /// 12500 K.
    case k12500 = "12500"
    /// 12750 K.
    case k12750 = "12750"
    /// 13000 K.
    case k13000 = "13000"
    /// 13250 K.
    case k13250 = "13250"
    /// 13500 K.
    case k13500 = "13500"
    /// 13750 K.
    case k13750 = "13750"
    /// 14000 K.
    case k14000 = "14000"
    /// 14250 K.
    case k14250 = "14250"
    /// 14500 K.
    case k14500 = "14500"
    /// 14750 K.
    case k14750 = "14750"
    /// k15000 K.
    case k15000 = "15000"

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera zoom quality mode for velocity control.
public enum Camera2ZoomVelocityControlQualityMode: String, Camera2ConfigEnum {
    /// Allows zoom level to go past `Camera2Zoom.maxLossLessLevel` when the zoom is controlled in `.velocity` mode.
    case allowDegrading
    /// Stops zoom before level go past `Camera2Zoom.maxLossLessLevel` when the zoom is controlled in `.velocity` mode.
    case stopBeforeDegrading

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera auto exposure metering mode.
public enum Camera2AutoExposureMeteringMode: String, Camera2ConfigEnum {
    /// Standard auto exposure metering mode.
    case standard

    /// Center top auto exposure metering mode.
    case centerTop

    /// Debug description.
    public var description: String { rawValue }
}

/// Storage policy for media files.
public enum Camera2StoragePolicy: String, Camera2ConfigEnum {
    /// Storage where media files are stored is automatically chosen by the drone.
    case automatic

    /// Store media files in internal drone storage.
    case `internal`

    /// Store media files in removable storage.
    case removable

    /// Debug description.
    public var description: String { rawValue }
}
