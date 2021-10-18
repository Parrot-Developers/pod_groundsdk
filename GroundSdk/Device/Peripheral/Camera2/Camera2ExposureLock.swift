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

/// Camera exposure lock mode.
public enum Camera2ExposureLockMode: Int, CustomStringConvertible {
    /// Exposure is not lock.
    case none
    /// Exposure is locked on current values.
    case currentValues
    /// Exposure is locked on a given region of interest (taken from the video stream).
    case region

    /// Debug description.
    public var description: String {
        switch self {
        case .none:             return "none"
        case .currentValues:    return "currentValues"
        case .region:           return "region"
        }
    }
}

/// Camera exposure lock component.
///
///  Allows to lock/unlock the exposure according to a given mode.
public protocol Camera2ExposureLock: Component {
    /// Whether the mode has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported modes.
    var supportedModes: Set<Camera2ExposureLockMode> { get }

    /// Current exposure lock mode.
    var mode: Camera2ExposureLockMode { get }

    /// Locks exposure on current exposure values.
    func lockOnCurrentValues()

    /// Locks exposure on a given region of interest defined by its center (taken from the video stream).
    ///
    /// - Parameters:
    ///   - centerX: horizontal position in the video (relative position, from left (0.0) to right (1.0))
    ///   - centerY: vertical position in the video (relative position, from bottom (0.0) to top (1.0))
    func lockOnRegion(centerX: Double, centerY: Double)

    /// Unlocks exposure.
    func unlock()
}

/// :nodoc:
/// Camera2ExposureLock description.
public class Camera2ExposureLockDesc: NSObject, Camera2ComponentClassDesc {
    public typealias ApiProtocol = Camera2ExposureLock
    public let uid = Camera2ComponentUid.exposureLock.rawValue
    public let parent: ComponentDescriptor? = nil
}
