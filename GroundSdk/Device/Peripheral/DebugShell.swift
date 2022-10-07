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

/// Debug shell state.
public enum DebugShellState: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    /// The debug shell is disabled.
    case disabled
    /// The debug shell is enabled for the given public key.
    case enabled(publicKey: String)

    public var description: String {
        switch self {
        case .enabled(let key): return "enabled publicKey: \"\(key.prefix(3))...\(key.suffix(3))\""
        case .disabled: return "disabled"
        }
    }

    public var debugDescription: String {
        switch self {
        case .enabled(let key): return "enabled publicKey: \"\(key)\""
        case .disabled: return "disabled"
        }
    }
}

/// Setting providing access to the DebugShellState.
public protocol DebugShellStateSetting: AnyObject {
    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Debug shell state value.
    var value: DebugShellState { get set }
}

/// DebugShell peripheral interface.
///
/// This peripheral provides access to DebugShell settings.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.debugShell)
/// ```
public protocol DebugShell: Peripheral {
    /// DebugShell state setting.
    var state: DebugShellStateSetting { get }
}

/// :nodoc:
/// DebugShell description
public class DebugShellDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = DebugShell
    public let uid = PeripheralUid.debugShell.rawValue
    public let parent: ComponentDescriptor? = nil
}
