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

/// A physical button that can be grabbed on a `RemoteControl.Model.skyCtrl4` gamepad.
@objc(GSSkyCtrl4Button)
public enum SkyCtrl4Button: Int {

    /// Top-most button on the left of the controller front, immediately above power-on button, featuring
    /// a return-home icon print.
    /// Produces `SkyCtrl4ButtonEvent.frontLeftButton` events when grabbed.
    case frontLeft

    /// Button on the right of the controller front, featuring a takeoff icon print.
    /// icon print.
    /// Produces `SkyCtrl4ButtonEvent.frontRightButton` events when grabbed.
    case frontRight

    /// Left-most button on the rear of the controller, immediately above AxisLeftSlider, featuring a centering icon
    /// print.
    /// Produces:
    /// * `SkyCtrl4ButtonEvent.rearLeftButton` events when grabbed
    /// * `VirtualGamepadEvent.ok` events when `VirtualGamepad` peripheral is grabbed
    case rearLeft

    /// Right-most button on the rear of the controller, immediately above AxisRightSlider, featuring a
    /// take-photo/record icon print.
    /// Produces:
    /// * `SkyCtrl4ButtonEvent.rearRightButton` events when grabbed
    /// * `VirtualGamepadEvent.cancel` events when `VirtualGamepad` peripheral is grabbed
    case rearRight

    /// Set containing all possible buttons.
    public static let allCases: Set<SkyCtrl4Button> = [
        .frontLeft, .frontRight, .rearLeft, .rearRight]

    /// Debug description.
    public var description: String {
        switch self {
        case .frontLeft:   return "frontLeft"
        case .frontRight:  return "frontRight"
        case .rearLeft:    return "rearLeft"
        case .rearRight:   return "rearRight"
        }
    }
}

/// A physical axis that can be grabbed on a `RemoteControl.Model.skyCtrl4` gamepad.
@objc(GSSkyCtrl4Axis)
public enum SkyCtrl4Axis: Int {
    /// Horizontal (left/right) axis of the left control stick.
    /// Produces:
    /// * `SkyCtrl4ButtonEvent.leftStickLeft` and `SkyCtrl4ButtonEvent.leftStickRight` events when grabbed
    /// * `VirtualGamepadEvent.left` and `VirtualGamepadEvent.right` events when `VirtualGamepad` peripheral is grabbed
    case leftStickHorizontal

    /// Vertical (down/up) axis of the left control stick.
    /// Produces:
    /// * `SkyCtrl4ButtonEvent.leftStickDown` and `SkyCtrl4ButtonEvent.leftStickUp` events when grabbed
    /// * `VirtualGamepadEvent.down` and `VirtualGamepadEvent.up` events when `VirtualGamepad` peripheral is grabbed
    case leftStickVertical

    /// Horizontal (left/right) axis of the right control stick.
    /// Produces `SkyCtrl4ButtonEvent.rightStickLeft` and `SkyCtrl4ButtonEvent.rightStickRight` events when grabbed
    case rightStickHorizontal

    /// Vertical (down/up) axis of the right control stick.
    /// Produces `SkyCtrl4ButtonEvent.rightStickDown` and `SkyCtrl4ButtonEvent.rightStickUp` events when grabbed
    case rightStickVertical

    /// Slider on the rear, to the left of the controller, immediately below rearLeftButton, featuring a gimbal icon
    /// print.
    /// Produces `SkyCtrl4ButtonEvent.leftSliderUp` and `SkyCtrl4ButtonEvent.leftSliderDown` events when grabbed
    case leftSlider

    /// Slider on the rear, to the right of the controller, immediately below rearRightButton, featuring a zoom icon
    /// print.
    /// Produces `SkyCtrl4ButtonEvent.rightSliderUp` and `SkyCtrl4ButtonEvent.rightSliderDown` events when grabbed
    case rightSlider

    /// Set containing all possible axes.
    public static let allCases: Set<SkyCtrl4Axis> = [
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

/// Wrapper around a Set of `GSSkyCtrl4Button`.
/// This is only for Objective-C use.
@objcMembers
public class GSSkyCtrl4ButtonSet: NSObject {
    let set: Set<SkyCtrl4Button>

    /// Constructor.
    ///
    /// - Parameter buttons: list of all buttons
    init(buttons: SkyCtrl4Button...) {
        set = Set(buttons)
    }

    /// Swift Constructor.
    ///
    /// - Parameter buttonSet: set of all buttons
    init(buttonSet: Set<SkyCtrl4Button>) {
        set = buttonSet
    }

    /// Tells whether a given button is contained in the set.
    ///
    /// - Parameter button: the button
    /// - Returns: `true` if the set contains the button
    public func contains(_ button: SkyCtrl4Button) -> Bool {
        return set.contains(button)
    }
}

/// Wrapper around a Set of `GSSkyCtrl4AxisSet`.
/// This is only for Objective-C use.
@objcMembers
public class GSSkyCtrl4AxisSet: NSObject {
    let set: Set<SkyCtrl4Axis>

    /// Constructor.
    ///
    /// - Parameter axes: list of all axes
    init(axes: SkyCtrl4Axis...) {
        set = Set(axes)
    }

    /// Swift Constructor.
    ///
    /// - Parameter axisSet: set of all axes
    init(axisSet: Set<SkyCtrl4Axis>) {
        set = axisSet
    }

    /// Tells whether a given axis is contained in the set.
    ///
    /// - Parameter axis: the axis
    /// - Returns: `true` if the set contains the axis
    public func contains(_ axis: SkyCtrl4Axis) -> Bool {
        return set.contains(axis)
    }
}
