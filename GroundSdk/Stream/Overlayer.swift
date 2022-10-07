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

/// Histogram data.
@objc(GSHistogram)
public protocol Histogram {

    /// Histogram channel red.
    var histogramRed: [Float32]? {get}

    /// Histogram channel green.
    var histogramGreen: [Float32]? {get}

    /// Histogram channel blue.
    var histogramBlue: [Float32]? {get}

    /// Histogram channel luma.
    var histogramLuma: [Float32]? {get}
}

/// Overlay context data.
@objc(GSOverlayContext)
public protocol OverlayContext {
    /// Area where the frame was rendered (including any padding introduced by scaling).
    var renderZone: CGRect {get}

    /// Render zone handle; pointer to const struct pdraw_rect.
    var renderZoneHandle: UnsafeRawPointer {get}

    /// Area where frame content was rendered (excluding any padding introduced by scaling).
    var contentZone: CGRect {get}

    /// Content zone handle; pointer to const struct pdraw_rect.
    var contentZoneHandle: UnsafeRawPointer {get}

    /// Media info handle; pointer to const struct pdraw_media_info.
    var mediaInfoHandle: UnsafeRawPointer {get}

    /// Frame metadata handle; pointer to const struct struct vmeta_frame.
    var frameMetadataHandle: UnsafeRawPointer? {get}

    /// Histogram.
    var histogram: Histogram? {get}
}

/// Listener for rendering an overlay over a stream.
///
/// Such a listener can be passed to a 'StreamView' by setting 'StreamView.overlayer'.
@objc(GSOverlayer)
public protocol Overlayer {

    /// Called to render a GL overlay over a stream frame.
    ///
    /// - Parameters:
    ///    - overlayContext: Overlay context
    func overlay(overlayContext: OverlayContext)
}
