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

/// Type of a mapping entry.
public enum SkyCtrlUa2MappingEntryType: Int {
    /// Entry of this type is a `SkyCtrlUa2ButtonsMappingEntry` and can be casted as such.
    case buttons

    /// Entry of this type is a `SkyCtrlUa2AxisMappingEntry` and can be casted as such.
    case axis

    /// Debug description.
    public var description: String {
        switch self {
        case .buttons:  return "buttons"
        case .axis:     return "axis"
        }
    }
}

/// Defines a mapping entry.
///
/// A mapping entry collects the drone model onto which the entry should apply, as well as the type of the entry which
/// defines the concrete subclass of the entry.
///
/// No instance of this class can be created, you must either create a `SkyCtrlUa2ButtonsMappingEntry` or a
/// `SkyCtrlUa2AxisMappingEntry`.

public class SkyCtrlUa2MappingEntry: NSObject {

    /// Associated drone model.
    public let droneModel: Drone.Model

    /// Entry type.
    public let type: SkyCtrlUa2MappingEntryType

    /// Constructor (private).
    ///
    /// - Parameters:
    ///   - droneModel: drone model onto which the entry should apply
    ///   - type: type of the entry
    fileprivate init(droneModel: Drone.Model, type: SkyCtrlUa2MappingEntryType) {
        self.droneModel = droneModel
        self.type = type
    }

    public override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? SkyCtrlUa2MappingEntry {
            return droneModel == object.droneModel && type == object.type
        }
        return false
    }

    public override var hash: Int {
        return 11 * type.rawValue + 9 * droneModel.rawValue
    }
}

/// A mapping entry that defines a `ButtonsMappableAction` to be triggered when the gamepad inputs produce a set of
/// `SkyCtrlUa2ButtonEvent` in the state `.pressed`.
public class SkyCtrlUa2ButtonsMappingEntry: SkyCtrlUa2MappingEntry {
    /// Action to be triggered.
    public let action: ButtonsMappableAction

    /// Set of button events that triggers the action when in the `.pressed` state.
    public let buttonEvents: Set<SkyCtrlUa2ButtonEvent>

    /// Set of button events that triggers the action when in the `.pressed` state as an Int set.
    ///
    /// - Note: This should be only used in Objective-C.
    public var buttonEventsAsInt: Set<Int> {
        return Set(buttonEvents.map({ $0.rawValue }))
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - droneModel: drone model onto which the entry should apply
    ///   - action: action to be triggered
    ///   - buttonEvents: event set that triggers the action
    public init(droneModel: Drone.Model, action: ButtonsMappableAction, buttonEvents: Set<SkyCtrlUa2ButtonEvent>) {
        self.action = action
        self.buttonEvents = buttonEvents
        super.init(droneModel: droneModel, type: .buttons)
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - droneModel: drone model onto which the entry should apply
    ///   - action: action to be triggered
    ///   - buttonEventsAsInt: event set that triggers the action
    ///
    /// - Note: This function is for Objective-C only.
    ///     Swift must use the function
    ///     `init(droneModel: Drone.Model, action: ButtonsMappableAction, buttonEvents: Set<SkyCtrlUa2ButtonEvent>)`
    public convenience init(droneModel: Drone.Model, action: ButtonsMappableAction, buttonEventsAsInt: Set<Int>) {
        let buttonEvents = Set(buttonEventsAsInt.map({ SkyCtrlUa2ButtonEvent(rawValue: $0)! }))
        self.init(droneModel: droneModel, action: action, buttonEvents: buttonEvents)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? SkyCtrlUa2ButtonsMappingEntry {
            return super.isEqual(object) && action == object.action && buttonEvents == object.buttonEvents
        }
        return false
    }

    public override var hash: Int {
        return super.hash + 7 * action.rawValue + buttonEvents.hashValue
    }
}

/// A mapping entry that defines a `AxisMappableAction` to be triggered when the gamepad inputs produce an
/// `SkyCtrlUa2AxisEvent`, and optionally in conjunction with a specific set of `SkyCtrlUa2ButtonEvent` in the
/// state `.pressed`.

public class SkyCtrlUa2AxisMappingEntry: SkyCtrlUa2MappingEntry {

    /// Action to be triggered.
    public let action: AxisMappableAction

    /// Axis event that triggers the action.
    public let axisEvent: SkyCtrlUa2AxisEvent

    /// Set of button events that triggers the action when in the `.pressed` state.
    public let buttonEvents: Set<SkyCtrlUa2ButtonEvent>

    /// Set of button events that triggers the action when in the `.pressed` state as an Int set.
    ///
    /// This should be only used in Objective-C
    public var buttonEventsAsInt: Set<Int> {
        return Set(buttonEvents.map({ $0.rawValue }))
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - droneModel: drone model onto which the entry should apply
    ///   - action: action to be triggered
    ///   - axisEvent: axis event that triggers the action
    ///   - buttonEvents: event set that triggers the action
    public init(droneModel: Drone.Model, action: AxisMappableAction, axisEvent: SkyCtrlUa2AxisEvent,
                buttonEvents: Set<SkyCtrlUa2ButtonEvent>) {
        self.action = action
        self.axisEvent = axisEvent
        self.buttonEvents = buttonEvents
        super.init(droneModel: droneModel, type: .axis)
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - droneModel: drone model onto which the entry should apply
    ///   - action: action to be triggered
    ///   - axisEvent: axis event that triggers the action
    ///   - buttonEventsAsInt: event set that triggers the action
    ///
    /// - Note: This function is for Objective-C only.
    ///     Swift must use the function
    ///     `init(droneModel: Drone.Model, action: ButtonsMappableAction, axisEvent: SkyCtrlUa2AxisEvent,
    ///     buttonEvents: Set<SkyCtrlUa2ButtonEvent>)`
    public convenience init(
        droneModel: Drone.Model, action: AxisMappableAction, axisEvent: SkyCtrlUa2AxisEvent,
        buttonEventsAsInt: Set<Int>) {
        let buttonEvents = Set(buttonEventsAsInt.map({ SkyCtrlUa2ButtonEvent(rawValue: $0)! }))
        self.init(droneModel: droneModel, action: action, axisEvent: axisEvent, buttonEvents: buttonEvents)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? SkyCtrlUa2AxisMappingEntry {
            return super.isEqual(object) && action == object.action && axisEvent == object.axisEvent &&
                buttonEvents == object.buttonEvents
        }
        return false
    }

    public override var hash: Int {
        return super.hash + 7 * action.rawValue + 5 * axisEvent.rawValue + buttonEvents.hashValue
    }
}
