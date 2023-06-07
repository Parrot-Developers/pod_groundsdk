// Copyright (C) 2023 Parrot Drones SAS
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

/// Wifi indoor/outdoor environment modes.
public enum Environment: Int, CustomStringConvertible, CaseIterable {
    /// Wifi is configured for indoor use.
    case indoor
    /// Wifi is configured for outdoor use.
    case outdoor

    /// Debug description.
    public var description: String {
        switch self {
        case .indoor:   return "indoor"
        case .outdoor:  return "outdoor"
        }
    }
}

/// Setting providing access to the Wifi environment setup.
public protocol EnvironmentSetting: AnyObject {

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Tells whether the setting can be altered by the application.
    ///
    /// Depending on the device, the current environment setup may not be changed.
    /// For instance, on remote control devices, the environment is hard wired to the currently
    /// or most recently connected drone, if any, and cannot be changed by the application.
    var mutable: Bool { get }

    /// Current environment mode of the access point.
    ///
    /// - Note: Altering this setting may change the set of available channels, and even result in a device
    /// disconnection since the channel currently in use might not be allowed with the new environment setup.
    var value: Environment { get set }
}
