// Copyright (C) 2021 Parrot Drones SAS
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

/// An event that may be produced by a `RemoteControl.Model.skyCtrl4` gamepad input when grabbed.
///
/// The corresponding input has a button behavior, i.e. it can be either pressed or released, and an event is sent
/// each time that state changes, along with the current state.
@objc(GSSkyCtrl4ButtonEvent)
public enum SkyCtrl4ButtonEvent: Int {

    /// Event sent when `SkyCtrl4Button.frontLeft` is pressed or released.
    case frontLeftButton

    /// Event sent when `SkyCtrl4Button.frontRight` is pressed or released.
    case frontRightButton

    /// Event sent when `SkyCtrl4Button.rearLeft` is pressed or released.
    case rearLeftButton

    /// Event sent when `SkyCtrl4Button.rearRight` is pressed or released.
    case rearRightButton

    /// Event sent when `SkyCtrl4Axis.leftStickHorizontal` reaches or quits the left stop of its course.
    case leftStickLeft

    /// Event sent when `SkyCtrl4Axis.leftStickHorizontal` reaches or quits the right stop of its course.
    case leftStickRight

    /// Event sent when `SkyCtrl4Axis.leftStickVertical` reaches or quits the top stop of its course.
    case leftStickUp

    /// Event sent when `SkyCtrl4Axis.leftStickVertical` reaches or quits the bottom stop of its course.
    case leftStickDown

    /// Event sent when `SkyCtrl4Axis.rightStickHorizontal` reaches or quits the left stop of its course.
    case rightStickLeft

    /// Event sent when `SkyCtrl4Axis.rightStickVertical` reaches or quits the right stop of its course.
    case rightStickRight

    /// Event sent when `SkyCtrl4Axis.rightStickVertical` reaches or quits the top stop of its course.
    case rightStickUp

    /// Event sent when `SkyCtrl4Axis.rightStickVertical` reaches or quits the bottom stop of its course.
    case rightStickDown

    /// Event sent when `SkyCtrl4Axis.leftSlider` reaches or quits the Up stop of its course.
    case leftSliderUp

    /// Event sent when `SkyCtrl4Axis.leftSlider` reaches or quits the Down stop of its course.
    case leftSliderDown

    /// Event sent when `SkyCtrl4Axis.rightSlider` reaches or quits the Up stop of its course.
    case rightSliderUp

    /// Event sent when `SkyCtrl4Axis.rightSlider` reaches or quits the Down stop of its course.
    case rightSliderDown

    /// Debug description.
    public var description: String {
        switch self {
        case .frontLeftButton:   return "frontLeftButton"
        case .frontRightButton:  return "frontRightButton"
        case .rearLeftButton:    return "rearLeftButton"
        case .rearRightButton:   return "rearRightButton"
        case .leftSliderUp:      return "leftSliderUp"
        case .leftSliderDown:    return "leftSliderDown"
        case .rightSliderUp:     return "rightSliderUp"
        case .rightSliderDown:   return "rightSliderDown"
        case .leftStickLeft:     return "leftStickLeft"
        case .leftStickRight:    return "leftStickRight"
        case .leftStickUp:       return "leftStickUp"
        case .leftStickDown:     return "leftStickDown"
        case .rightStickLeft:    return "rightStickLeft"
        case .rightStickRight:   return "rightStickRight"
        case .rightStickUp:      return "rightStickUp"
        case .rightStickDown:    return "rightStickDown"
        }
    }
}

/// State of a `SkyCtrl4ButtonEvent`.
@objc(GSSkyCtrl4ButtonEventState)
public enum SkyCtrl4ButtonEventState: Int {
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
