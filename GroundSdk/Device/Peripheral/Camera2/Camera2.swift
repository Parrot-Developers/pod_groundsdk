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

/// Base protocol for camera components.
public protocol Camera2Component: Component {
}

/// Camera component descriptor.
public protocol Camera2ComponentClassDesc: ComponentApiDescriptor {
    /// Protocol of the component.
    associatedtype ApiProtocol = Camera2Component
}

/// Camera components.
public class Camera2Components {

    /// Exposure indicator component.
    public static let exposureIndicator = Camera2ExposureIndicatorDesc()

    /// Exposure lock component.
    public static let exposureLock = Camera2ExposureLockDesc()

    /// Media metadata component.
    public static let mediaMetadata = Camera2MediaMetadataDesc()

    /// Photo capture component.
    public static let photoCapture = Camera2PhotoCaptureDesc()

    /// Photo progress indicator component.
    public static let photoProgressIndicator = Camera2PhotoProgressIndicatorDesc()

    /// Recording component.
    public static let recording = Camera2RecordingDesc()

    /// White balance lock component.
    public static let whiteBalanceLock = Camera2WhiteBalanceLockDesc()

    /// Zoom component.
    public static let zoom = Camera2ZoomDesc()
}

/// Camera components unique identifier.
enum Camera2ComponentUid: Int {
    case exposureIndicator
    case exposureLock
    case mediaMetadata
    case photoCapture
    case photoProgressIndicator
    case recording
    case whiteBalanceLock
    case zoom
}

/// Camera2 protocol.
///
/// Provides access to the device's camera in order to take pictures and to record videos.
/// Also provides access to various camera settings, such as:
/// - Exposure,
/// - EV compensation,
/// - White balance,
/// - Zoom,
/// - Recording mode, resolution and framerate selection,
/// - Photo mode, format and file format selection.
public protocol Camera2 {

    /// Whether the camera is active.
    var isActive: Bool { get }

    /// Camera configuration.
    var config: Camera2Config { get }

    /// Gets a camera component.
    ///
    /// - Parameters:
    ///    - desc: requested component. See `Camera2Components` for available descriptors instances
    /// - Returns: the requested component or `nil` if not available
    func getComponent<Desc: Camera2ComponentClassDesc>(_ desc: Desc) -> Desc.ApiProtocol?

    /// Gets a camera component and registers an observer notified each time it changes.
    ///
    /// - Parameters:
    ///    - desc: requested component. See `Camera2Components` for available descriptors instances
    ///    - observer: observer to notify when the component changes
    /// - Returns: reference to the requested component
    func getComponent<Desc: Camera2ComponentClassDesc>(_ desc: Desc,
                    observer: @escaping Ref<Desc.ApiProtocol>.Observer) -> Ref<Desc.ApiProtocol>
}
