// Copyright (C) 2024 Parrot Drones SAS
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

/// An event that may be produced by a `RemoteControl.Model.skyCtrlUA2` gamepad input when grabbed.
///
/// The corresponding input has a button behavior, i.e. it can be either pressed or released, and an event is sent
/// each time that state changes, along with the current state.
public enum SkyCtrlUa2ButtonEvent: Int {

    /// Event sent when `SkyCtrlUa2Button.frontLeft1` is pressed or released.
    case frontLeft1Button

    /// Event sent when `SkyCtrlUa2Button.frontLeft2` is pressed or released.
    case frontLeft2Button

    /// Event sent when `SkyCtrlUa2Button.frontLeft3` is pressed or released.
    case frontLeft3Button

    /// Event sent when `SkyCtrlUa2Button.frontLeft4` is pressed or released.
    case frontLeft4Button

    /// Event sent when `SkyCtrlUa2Button.frontRight1` is pressed or released.
    case frontRight1Button

    /// Event sent when `SkyCtrlUa2Button.frontRight2` is pressed or released.
    case frontRight2Button

    /// Event sent when `SkyCtrlUa2Button.rearLeft` is pressed or released.
    case rearLeftButton

    /// Event sent when `SkyCtrlUa2Button.rearRight` is pressed or released.
    case rearRightButton

    /// Debug description.
    public var description: String {
        switch self {
        case .frontLeft1Button:   return "frontLeft1Button"
        case .frontLeft2Button:   return "frontLeft2Button"
        case .frontLeft3Button:   return "frontLeft3Button"
        case .frontLeft4Button:   return "frontLeft4Button"
        case .frontRight1Button:  return "frontRight1Button"
        case .frontRight2Button:  return "frontRight2Button"
        case .rearLeftButton:    return "rearLeftButton"
        case .rearRightButton:   return "rearRightButton"
        }
    }
}

/// State of a `SkyCtrlUa2ButtonEvent`.
public enum SkyCtrlUa2ButtonEventState: Int {
    /// Button is pressed.
    case pressed

    /// Button is released.
    case released

    /// Debug description.
    public var description: String {
        switch self {
        case .pressed:  return "pressed"
        case .released: return "released"
        }
    }
}
