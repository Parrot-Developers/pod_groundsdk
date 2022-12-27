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
public protocol VideoFormat {
    /// Video format description
    var format: VideoFormatDescriptor { get }
    /// Video frame resolution (in pixels)
    var resolution: VideoFormatResolution { get }
    /// Video framerate
    var framerate: VideoFormatFramerate { get }
    /// Bit depth
    var bitDepth: UInt32 { get }
    /// `true` for full color range, otherwise `false`
    var fullColorRange: Bool { get }
    /// Color primaries, or `nil` if not available
    var colorPrimaries: VideoFormatColorPrimaries? { get }
    /// Transfer function, or `nil` if not available
    var transferFunction: VideoFormatTransferFunction? { get }
    /// Matrix coefficients, or `nil` if not available
    var matrixCoefficients: VideoFormatMatrixCoefficients? { get }
    /// Dynamic range, or `nil` if not available
    var dynamicRange: VideoFormatDynamicRange? { get }
    /// Tone mapping, or `nil` if not available
    var toneMapping: VideoFormatToneMapping? { get }
    /// Sample aspect ratio
    var sampleAspectRatio: VideoFormatAspectRatio { get }
    /// Mastering display color volume, or `nil` if not available
    var masteringDisplayColorVolume: VideoFormatMasteringDisplayColorVolume? { get }
    /// Content light level, or `nil` if not available
    var contentLightLevel: VideoFormatContentLightLevel? { get }
}

/// Describes a video format.
public protocol VideoFormatDescriptor {
}

/// Describes a raw video format.
public protocol VideoFormatRaw: VideoFormatDescriptor {
    /// Pixel format, or `nil` if not available
    var pixelFormat: VideoFormatRawPixelFormat? { get }
    /// Pixel order, or `nil` if not available
    var pixelOrder: VideoFormatRawPixelOrder? { get }
    /// Pixel layout, or `nil` if not available
    var pixelLayout: VideoFormatRawPixelLayout? { get }
    /// Pixel value size in bits (excluding padding)
    var pixelSize: UInt32 { get }
    /// Data layout, or `nil` if not available
    var dataLayout: VideoFormatRawDataLayout? { get }
    /// Data padding
    var dataPadding: VideoFormatRawDataPadding { get }
    /// Data endianness
    var dataEndianness: VideoFormatRawDataEndianness { get }
    /// Data size in bits including padding
    var dataSize: UInt32 { get }
}

/// Raw pixel format.
public enum VideoFormatRawPixelFormat {
    /// YUV/YCbCr 4:2:0 pixel format.
    case yuv420

    /// YUV/YCbCr 4:2:2 pixel format.
    case yuv422

    /// YUV/YCbCr 4:4:4 pixel format.
    case yuv444

    /// Gray pixel format.
    case gray

    /// RGB pixel format.
    case rgb24

    /// RGB + alpha pixel format.
    case rgba32

    /// Bayer pixel format.
    case bayer

    /// Depth map pixel format.
    case depth

    /// Depth map (float data) pixel format.
    case depthFloat
}

/// Raw pixel ordering.
public enum VideoFormatRawPixelOrder {
    case ABCD
    case ABDC
    case ACBD
    case ACDB
    case ADBC
    case ADCB

    case BACD
    case BADC
    case BCAD
    case BCDA
    case BDAC
    case BDCA

    case CABD
    case CADB
    case CBAD
    case CBDA
    case CDAB
    case CDBA

    case DABC
    case DACB
    case DBAC
    case DBCA
    case DCAB
    case DCBA
}

/// Raw pixel layout.
public enum VideoFormatRawPixelLayout {

    /// Linear pixel layout.
    case linear

    /// HiSilicon tiled pixel layout (tiles of 64x16).
    case hiSiliconTile64X16

    /// HiSilicon tiled pixel layout (tiles of 64x16) - compressed.
    case hiSiliconTile64X16Ccompressed
}

/// Raw data layout.
public enum VideoFormatRawDataLayout {

    /// Packed data layout.
    case packed

    /// Planar data layout.
    case planar

    /// Semi-planar data layout.
    case semiPlanar

    /// Interleaved data layout.
    case interleaved

    /// Opaque data layout.
    case opaque
}

/// Data padding.
public enum VideoFormatRawDataPadding {

    /// Padding in lower bits.
    case low

    /// Padding in higher bits.
    case high
}

/// Data endianness.
public enum VideoFormatRawDataEndianness {
    /// Little endian.
    case little
    /// Big endian.
    case big
}

/// Represents a video resolution.
public protocol VideoFormatResolution {
    /// width in pixels
    var width: UInt64 { get }
    /// height in pixels
    var height: UInt64 { get }
}

/// Represents a framerate.
public protocol VideoFormatFramerate {
    /// frames framerate numerator: number of frames occurring over time [period]
    var frames: UInt64 { get }
    /// period framerate denominator: time period, in seconds
    var period: UInt64 { get }
}

/// Color primaries.
public enum VideoFormatColorPrimaries {

    /// Rec. ITU-R BT.601-7 525-line color primaries.
    case bt601x525

    /// Rec. ITU-R BT.601-7 625-line color primaries.
    case bt601x625

    /// Rec. ITU-R BT.709-6 / IEC 61966-2-1 sRGB color primaries.
    case bt709

    /// Rec. ITU-R BT.2020-2 / Rec. ITU-R BT.2100-1 color primaries.
    case bt2020

    /// SMPTE RP 431-2 "DCI-P3" color primaries.
    case dciP3

    /// SMPTE RP 432-1 "Display-P3" color primaries.
    case displayP3

    /// Unknown color primaries.
    case custom(whitePoint: VideoFormatChromaticityCoordinates,
                red: VideoFormatChromaticityCoordinates,
                green: VideoFormatChromaticityCoordinates,
                blue: VideoFormatChromaticityCoordinates)

}

/// Color primaries chromaticity coordinates.
public protocol VideoFormatChromaticityCoordinates {
    /// coordinate on the x axis
    var x: Double { get }
    /// coordinate on the y axis
    var y: Double { get }
}

/// Transfer function.
public enum VideoFormatTransferFunction {

    /// Rec. ITU-R BT.601-7 525-line or 625-line transfer function.
    case bt601

    /// Rec. ITU-R BT.709-6 transfer function.
    case bt709

    /// Rec. ITU-R BT.2020-2 transfer function.
    case bt2020

    /// SMPTE ST 2084 / Rec. ITU-R BT.2100-1 perceptual quantization transfer function.
    case pq

    /// Rec. ITU-R BT.2100-1 hybrid log-gamma transfer function.
    case hlg

    /// IEC 61966-2-1 sRGB transfer function.
    case srgb
}

/// Matrix coefficients.
public enum VideoFormatMatrixCoefficients {

    /// Identity / IEC 61966-2-1 sRGB matrix coefficients.
    case identity

    /// Rec. ITU-R BT.601-7 525-line matrix coefficients.
    case bt601x525

    /// Rec. ITU-R BT.601-7 625-line matrix coefficients.
    case bt601x625

    /// Rec. ITU-R BT.709-6 matrix coefficients.
    case bt709

    /// Rec. ITU-R BT.2020 non-constant luminance system.
    case bt2020NonCst

    /// Rec. ITU-R BT.2020 constant luminance system.
    case bt2020Cst
}

/// Dynamic range.
public enum VideoFormatDynamicRange {

    /// Standard dynamic range.
    case sdr

    /// High dynamic range: Parrot 8bit HDR.
    case hdr8

    /// High dynamic range: standard 10bit HDR10.
    ///
    /// Rec. ITU-R BT.2020 color primaries, SMPTE ST 2084 perceptual quantization transfer
    /// function and SMPTE ST 2086 metadata.
    case hdr10
}

/// Tone mapping.
public enum VideoFormatToneMapping {

    /// Standard tone mapping.
    case standard

    /// Parrot P-log tone mapping.
    case pLog
}

/// Represents an aspect ratio.
public protocol VideoFormatAspectRatio {
    /// aspect ratio width, without unit
    var width: UInt64 { get }
    /// aspect ratio height, without unit
    var height: UInt64 { get }
}

/// Mastering display color volume.
public protocol VideoFormatMasteringDisplayColorVolume {
    /// color primaries
    var colorPrimaries: VideoFormatColorPrimaries { get }
    /// luminance range (in cd/m²)
    var luminanceRange: ClosedRange<Double> { get }
}

/// Content light level.
public protocol VideoFormatContentLightLevel {
    /// maximum content light level (in cd/m²)
    var maxContentLightLevel: Int64 { get }
    /// maximum frame average light level (in cd/m²)
    var maxFrameAverageLightLevel: Int64 { get }
}
