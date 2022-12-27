// Copyright (C) 2022 Parrot Drones SAS
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

/// Video format information.
public class VideoFormatCore: VideoFormat {
    /// Video format description
    public let format: VideoFormatDescriptor
    /// Video frame resolution (in pixels)
    public let resolution: VideoFormatResolution
    /// Video framerate
    public let framerate: VideoFormatFramerate
    /// Bit depth
    public let bitDepth: UInt32
    /// `true` for full color range, otherwise `false`
    public let fullColorRange: Bool
    /// Color primaries, or `nil` if not available
    public let colorPrimaries: VideoFormatColorPrimaries?
    /// Transfer function, or `nil` if not available
    public let transferFunction: VideoFormatTransferFunction?
    /// Matrix coefficients, or `nil` if not available
    public let matrixCoefficients: VideoFormatMatrixCoefficients?
    /// Dynamic range, or `nil` if not available
    public let dynamicRange: VideoFormatDynamicRange?
    /// Tone mapping, or `nil` if not available
    public let toneMapping: VideoFormatToneMapping?
    /// Sample aspect ratio
    public let sampleAspectRatio: VideoFormatAspectRatio
    /// Mastering display color volume, or `nil` if not available
    public let masteringDisplayColorVolume: VideoFormatMasteringDisplayColorVolume?
    /// Content light level, or `nil` if not available
    public let contentLightLevel: VideoFormatContentLightLevel?

    /// Constructor
    ///
    /// - Parameters:
    ///    - format: Video format description
    ///    - resolution: Video frame resolution (in pixels)
    ///    - framerate: Video framerate
    ///    - bitDepth: Bit depth
    ///    - fullColorRange: `true` for full color range, otherwise `false`
    ///    - colorPrimaries: Color primaries, or `nil` if not available
    ///    - transferFunction: Transfer function, or `nil` if not available
    ///    - matrixCoefficients: Matrix coefficients, or `nil` if not available
    ///    - dynamicRange: Dynamic range, or `nil` if not available
    ///    - toneMapping: Tone mapping, or `nil` if not available
    ///    - sampleAspectRatio: Sample aspect ratio
    ///    - masteringDisplayColorVolume: Mastering display color volume, or `nil` if not available
    ///    - contentLightLevel: Content light level, or `nil` if not available
    public init(format: VideoFormatDescriptor,
                resolution: VideoFormatResolution,
                framerate: VideoFormatFramerate,
                bitDepth: UInt32,
                fullColorRange: Bool,
                colorPrimaries: VideoFormatColorPrimaries?,
                transferFunction: VideoFormatTransferFunction?,
                matrixCoefficients: VideoFormatMatrixCoefficients?,
                dynamicRange: VideoFormatDynamicRange?,
                toneMapping: VideoFormatToneMapping?,
                sampleAspectRatio: VideoFormatAspectRatio,
                masteringDisplayColorVolume: VideoFormatMasteringDisplayColorVolume?,
                contentLightLevel: VideoFormatContentLightLevel?) {

        self.format = format
        self.resolution = resolution
        self.framerate = framerate
        self.bitDepth = bitDepth
        self.fullColorRange = fullColorRange
        self.colorPrimaries = colorPrimaries
        self.transferFunction = transferFunction
        self.matrixCoefficients = matrixCoefficients
        self.dynamicRange = dynamicRange
        self.toneMapping = toneMapping
        self.sampleAspectRatio = sampleAspectRatio
        self.masteringDisplayColorVolume = masteringDisplayColorVolume
        self.contentLightLevel = contentLightLevel
    }
}

/// Represents a video resolution.
public class VideoFormatResolutionCore: VideoFormatResolution {
    /// width in pixels
    public let width: UInt64
    /// height in pixels
    public let height: UInt64

    /// Constructor
    ///
    /// - Parameters:
    ///    - width: width in pixels
    ///    - height: height in pixels
    public init(width: UInt64, height: UInt64) {
        self.width = width
        self.height = height
    }
}

/// Represents a framerate.
public class VideoFormatFramerateCore: VideoFormatFramerate {
    /// frames framerate numerator: number of frames occurring over time `period`
    public let frames: UInt64
    /// period framerate denominator: time period, in seconds
    public let period: UInt64

    /// Constructor
    ///
    /// - Parameters:
    ///    - frames: frames framerate numerator: number of frames occurring over time `period`
    ///    -  period: period framerate denominator: time period, in seconds
    public init(frames: UInt64, period: UInt64) {
        self.frames = frames
        self.period = period
    }
}

/// Represents an aspect ratio.
public class VideoFormatAspectRatioCore: VideoFormatAspectRatio {
    /// aspect ratio width, without unit
    public let width: UInt64
    /// aspect ratio height, without unit
    public let height: UInt64

    /// Constructor
    ///
    /// - Parameters:
    ///    - width: aspect ratio width, without unit
    ///    - height: aspect ratio height, without unit
    public init(width: UInt64, height: UInt64) {
        self.width = width
        self.height = height
    }
}

/// Mastering display color volume.
// swiftlint:disable:next type_name
public class VideoFormatMasteringDisplayColorVolumeCore: VideoFormatMasteringDisplayColorVolume {
    /// color primaries
    public let colorPrimaries: VideoFormatColorPrimaries
    /// luminance range (in cd/m²)
    public let luminanceRange: ClosedRange<Double>

    /// Constructor
    ///
    /// - Parameters:
    ///    - colorPrimaries: color primaries
    ///    - luminanceRange: luminance range (in cd/m²)
    public init(colorPrimaries: VideoFormatColorPrimaries, luminanceRange: ClosedRange<Double>) {
        self.colorPrimaries = colorPrimaries
        self.luminanceRange = luminanceRange
    }
}

/// Content light level.
public class VideoFormatContentLightLevelCore: VideoFormatContentLightLevel {
    /// maximum content light level (in cd/m²)
    public let maxContentLightLevel: Int64
    /// maximum frame average light level (in cd/m²)
    public let maxFrameAverageLightLevel: Int64

    /// Constructor
    ///
    /// - Parameters:
    ///    - maxContentLightLevel: maximum content light level (in cd/m²)
    ///    - maxFrameAverageLightLevel: maximum frame average light level (in cd/m²)
    public init(maxContentLightLevel: Int64, maxFrameAverageLightLevel: Int64) {
        self.maxContentLightLevel = maxContentLightLevel
        self.maxFrameAverageLightLevel = maxFrameAverageLightLevel
    }
}

/// Color primaries chromaticity coordinates.
public class VideoFormatChromaticityCoordinatesCore: VideoFormatChromaticityCoordinates {
    /// coordinate on the x axis
    public let x: Double
    /// coordinate on the y axis
    public let y: Double

    /// Constructor
    ///
    /// - Parameters:
    ///    - x: coordinate on the x axis
    ///    - y: coordinate on the y axis
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Describes a raw video format.
public class VideoFormatRawCore: VideoFormatRaw {
    /// Pixel format, or `nil` if not available
    public let pixelFormat: VideoFormatRawPixelFormat?
    /// Pixel order, or `nil` if not available
    public let pixelOrder: VideoFormatRawPixelOrder?
    /// Pixel layout, or `nil` if not available
    public let pixelLayout: VideoFormatRawPixelLayout?
    /// Pixel value size in bits (excluding padding)
    public let pixelSize: UInt32
    /// Data layout, or `nil` if not available
    public let dataLayout: VideoFormatRawDataLayout?
    /// Data padding
    public let dataPadding: VideoFormatRawDataPadding
    /// Data endianness
    public let dataEndianness: VideoFormatRawDataEndianness
    /// Data size in bits including padding
    public let dataSize: UInt32

    /// Constructor
    ///
    /// - Parameters:
    ///    - pixelFormat: Pixel format, or `nil` if not available
    ///    - pixelOrder: Pixel order, or `nil` if not available
    ///    - pixelLayout: Pixel layout, or `nil` if not available
    ///    - pixelSize: Pixel value size in bits (excluding padding)
    ///    - dataLayout: Data layout, or `nil` if not available
    ///    - dataPadding: Data padding
    ///    - dataEndiannes: Data endianness
    ///    - dataSize: Data size in bits including padding
    public init(pixelFormat: VideoFormatRawPixelFormat?,
                pixelOrder: VideoFormatRawPixelOrder?,
                pixelLayout: VideoFormatRawPixelLayout?,
                pixelSize: UInt32,
                dataLayout: VideoFormatRawDataLayout?,
                dataPadding: VideoFormatRawDataPadding,
                dataEndianness: VideoFormatRawDataEndianness,
                dataSize: UInt32) {

        self.pixelFormat = pixelFormat
        self.pixelOrder = pixelOrder
        self.pixelLayout = pixelLayout
        self.pixelSize = pixelSize
        self.dataLayout = dataLayout
        self.dataPadding = dataPadding
        self.dataEndianness = dataEndianness
        self.dataSize = dataSize
    }
}
