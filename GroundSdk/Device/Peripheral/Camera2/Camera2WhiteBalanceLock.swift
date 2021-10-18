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

/// Camera white balance lock mode.
public enum Camera2WhiteBalanceLockMode: String, CustomStringConvertible, CaseIterable {
    /// White balance is not locked.
    case unlocked
    /// White balance is locked.
    case locked

    /// Debug description.
    public var description: String { rawValue }
}

/// Camera white balance lock component.
public protocol Camera2WhiteBalanceLock: Component {
    /// Whether the mode has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported modes.
    var supportedModes: Set<Camera2WhiteBalanceLockMode> { get }

    /// White balance lock mode.
    var mode: Camera2WhiteBalanceLockMode { get set }
}

/// :nodoc:
/// Camera2WhiteBalanceLock description.
public class Camera2WhiteBalanceLockDesc: NSObject, Camera2ComponentClassDesc {
    public typealias ApiProtocol = Camera2WhiteBalanceLock
    public let uid = Camera2ComponentUid.whiteBalanceLock.rawValue
    public let parent: ComponentDescriptor? = nil
}
