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

/// Point'n'fly piloting interface backend.
public protocol PointAndFlyPilotingItfBackend: ActivablePilotingItfBackend {
    /// Executes the given *point* or *fly* directive.
    ///
    /// - Parameter directive: point'n'fly directive
    func execute(directive: PointAndFlyDirective)

    /// Sets the current pitch value.
    ///
    /// - Parameter pitch: the new pitch value to set
    func set(pitch: Int)

    /// Sets the current roll value.
    ///
    /// - Parameter roll: the new roll value to set
    func set(roll: Int)

    /// Sets the current vertical speed value during a *point* execution.
    ///
    /// - Parameter verticalSpeed: the new vertical speed value to set
    func set(verticalSpeed: Int)
}

/// Internal point'n'fly piloting interface implementation.
public class PointAndFlyPilotingItfCore: ActivablePilotingItfCore, PointAndFlyPilotingItf {

    public private(set) var unavailabilityReasons: Set<PointAndFlyIssue> = []

    public private(set) var currentDirective: PointAndFlyDirective?

    public private(set) var executionStatus: PointAndFlyExecutionStatus?

    /// Super class backend as PointAndFlyPilotingItfBackend
    public var pointAndFlyBackend: PointAndFlyPilotingItfBackend {
        return backend as! PointAndFlyPilotingItfBackend
    }

    /// Constructor
    ///
    /// - Parameters:
    ///   - store: store where this interface will be stored
    ///   - backend: PointAndFlyPilotingItfBackend backend
    public init(store: ComponentStoreCore, backend: PointAndFlyPilotingItfBackend) {
        super.init(desc: PilotingItfs.pointAndFly, store: store, backend: backend)
    }

    public func execute(directive: PointAndFlyDirective) {
        if state != .unavailable {
            pointAndFlyBackend.execute(directive: directive)
        }
    }

    public func set(pitch: Int) {
        pointAndFlyBackend.set(pitch: signedPercentInterval.clamp(pitch))
    }

    public func set(roll: Int) {
        pointAndFlyBackend.set(roll: signedPercentInterval.clamp(roll))
    }

    public func set(verticalSpeed: Int) {
        pointAndFlyBackend.set(verticalSpeed: signedPercentInterval.clamp(verticalSpeed))
    }

    override func reset() {
        super.reset()
        unavailabilityReasons = []
        currentDirective = nil
        executionStatus = nil
    }
}

extension PointAndFlyPilotingItfCore {
    /// Updates the unavailability reasons.
    ///
    /// - Parameter unavailabilityReasons: new set of unavailability reasons
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(unavailabilityReasons newValue: Set<PointAndFlyIssue>) -> PointAndFlyPilotingItfCore {
        if unavailabilityReasons != newValue {
            unavailabilityReasons = newValue
            markChanged()
        }
        return self
    }

    /// Updates current point'n'fly directive.
    ///
    /// - Parameter currentDirective: new point'n'fly directive
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(currentDirective newValue: PointAndFlyDirective?) -> PointAndFlyPilotingItfCore {
        if currentDirective != newValue {
            currentDirective = newValue
            markChanged()
        }
        return self
    }

    /// Updates *point* or *fly* execution status.
    ///
    /// - Parameter executionStatus: new execution status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(executionStatus newValue: PointAndFlyExecutionStatus?) -> PointAndFlyPilotingItfCore {
        if executionStatus != newValue {
            executionStatus = newValue
            markChanged()
        }
        return self
    }
}
