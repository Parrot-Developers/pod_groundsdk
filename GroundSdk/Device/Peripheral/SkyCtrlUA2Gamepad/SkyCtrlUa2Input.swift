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
//

import Foundation

/// A physical button that can be grabbed on a `RemoteControl.Model.skyCtrlUA2` gamepad.
public enum SkyCtrlUa2Button: Int {

    /// Top-most button on the left of the controller front, immediately below left joystick, featuring a plus sign `+`
    /// icon print.
    /// Produces `SkyCtrlUa2ButtonEvent.frontLeft1Button` events when grabbed.
    case frontLeft1

    /// Button on the left of the controller front, immediately below `frontLeft1`, featuring a minus sign `-` icon
    /// print.
    /// Produces `SkyCtrlUa2ButtonEvent.frontLeft2Button` events when grabbed.
    case frontLeft2

    /// Button on the left of the controller front, immediately below `frontLeft2`, featuring a thermal camera
    /// activation icon print.
    /// Produces `SkyCtrlUa2ButtonEvent.frontLeft3Button` events when grabbed.
    case frontLeft3

    /// Bottom-most button on the left of the controller front, immediately below `frontLeft3`, featuring a screenshot
    /// icon print.
    /// Produces `SkyCtrlUa2ButtonEvent.frontLeft4Button` events when grabbed.
    case frontLeft4

    /// Button on the right of the controller front, immediately below power-on button, featuring a return-home
    /// icon print.
    /// Produces `SkyCtrlUa2ButtonEvent.frontRight1Button` events when grabbed.
    case frontRight1

    /// Bottom-most button on the right of the controller front, immediately below `frontRight1` button,
    /// featuring a takeoff icon print.
    /// Produces `SkyCtrlUa2ButtonEvent.frontRight2Button` events when grabbed.
    case frontRight2

    /// Left button on the rear of the controller, immediately above AxisLeftSlider, featuring a centering icon
    /// print.
    /// Produces `SkyCtrlUa2ButtonEvent.rearLeftButton` events when grabbed
    case rearLeft

    /// Right button on the rear of the controller, immediately above AxisRightSlider, featuring a
    /// record icon print.
    /// Produces `SkyCtrlUa2ButtonEvent.rearRightButton` events when grabbed
    case rearRight

    /// Set containing all possible buttons.
    public static let allCases: Set<SkyCtrlUa2Button> = [
        .frontLeft1, .frontLeft2, .frontLeft3, .frontLeft4, .frontRight1, .frontRight2, .rearLeft, .rearRight]

    /// Debug description.
    public var description: String {
        switch self {
        case .frontLeft1:   return "frontLeft1"
        case .frontLeft2:   return "frontLeft2"
        case .frontLeft3:   return "frontLeft3"
        case .frontLeft4:   return "frontLeft4"
        case .frontRight1:  return "frontRight1"
        case .frontRight2:  return "frontRight2"
        case .rearLeft:    return "rearLeft"
        case .rearRight:   return "rearRight"
        }
    }
}

/// A physical axis that can be grabbed on a `RemoteControl.Model.skyCtrlUA2` gamepad.
public enum SkyCtrlUa2Axis: Int {
    /// Horizontal (left/right) axis of the left control stick.
    /// Produces  `SkyCtrlUa2AxisEvent.leftStickHorizontal` event when grabbed
    case leftStickHorizontal

    /// Vertical (down/up) axis of the left control stick.
    /// Produces `SkyCtrlUa2AxisEvent.leftStickVertical` event when grabbed
    case leftStickVertical

    /// Horizontal (left/right) axis of the right control stick.
    /// Produces `SkyCtrlUa2AxisEvent.rightStickHorizontal` event when grabbed
    case rightStickHorizontal

    /// Vertical (down/up) axis of the right control stick.
    /// Produces `SkyCtrlUa2AxisEvent.rightStickVertical`  event when grabbed
    case rightStickVertical

    /// Slider on the rear, to the left of the controller, immediately below rearLeftButton, featuring a gimbal icon
    /// print.
    /// Produces `SkyCtrlUa2AxisEvent.leftSlider` event when grabbed
    case leftSlider

    /// Slider on the rear, to the right of the controller, immediately below rearRightButton, featuring a zoom icon
    /// print.
    /// Produces `SkyCtrlUa2AxisEvent.rightSlider` event when grabbed
    case rightSlider

    /// Set containing all possible axes.
    public static let allCases: Set<SkyCtrlUa2Axis> = [
        .leftStickHorizontal, .leftStickVertical, .rightStickHorizontal, .rightStickVertical, .leftSlider, .rightSlider]

    /// Debug description.
    public var description: String {
        switch self {
        case .leftStickHorizontal:  return "leftStickHorizontal"
        case .leftStickVertical:    return "leftStickVertical"
        case .rightStickHorizontal: return "rightStickHorizontal"
        case .rightStickVertical:   return "rightStickVertical"
        case .leftSlider:           return "leftSlider"
        case .rightSlider:          return "rightSlider"
        }
    }
}
