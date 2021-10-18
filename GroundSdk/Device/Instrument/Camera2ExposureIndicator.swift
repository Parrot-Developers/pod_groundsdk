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

/// Camera exposure indicator component.
public protocol Camera2ExposureIndicator: Component {

    /// Current effective shutter speed.
    var shutterSpeed: Camera2ShutterSpeed { get }

    /// Current effective iso sensitivity.
    var isoSensitivity: Camera2Iso { get }

    /// Currrent exposure lock region if exposure is currenlty locked or `nil`.
    ///
    /// - Parameters:
    ///    - centerX: region horizontal center in frame, in linear range `[0, 1]`, where `0` is the left of the frame
    ///    - centerY: region vertical center in frame, in linear range `[0, 1]`, where `0` is the bottom of the frame
    ///    - width: region width, in linear range `[0, 1]`, where `1` represents the full frame width
    ///    - height: region height, in linear range `[0, 1]`, where `1` represents the full frame height
    var lockRegion: (centerX: Double, centerY: Double, width: Double, height: Double)? { get }
}

/// :nodoc:
/// Camera2ExposureIndicator description.
public class Camera2ExposureIndicatorDesc: NSObject, Camera2ComponentClassDesc {
    public typealias ApiProtocol = Camera2ExposureIndicator
    public let uid = Camera2ComponentUid.exposureIndicator.rawValue
    public let parent: ComponentDescriptor? = nil
}
