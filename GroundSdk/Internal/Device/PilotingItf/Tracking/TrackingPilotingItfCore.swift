// Copyright (C) 2018 Parrot Drones SAS
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

/// TrackingPilotingItf backend protocol
public protocol TrackingPilotingItfBackend: ActivablePilotingItfBackend {

    /// Sets the current pitch value.
    ///
    /// Expressed as a signed percentage of the max pitch/roll setting (`maxPitchRoll`), in range [-100, 100].
    /// * -100 corresponds to a pitch angle of max pitch/roll towards ground (copter will fly forward)
    /// * 100 corresponds to a pitch angle of max pitch/roll towards sky (copter will fly backward)
    ///
    /// - note: this value may be clamped if necessary, in order to respect the maximum supported physical tilt of
    /// the copter.
    ///
    /// - parameter pitch: the new pitch value to set
    func set(pitch: Int)

    /// Sets the current roll value.
    ///
    /// Expressed as a signed percentage of the max pitch/roll setting (`maxPitchRoll`), in range [-100, 100].
    /// * -100 corresponds to a roll angle of max pitch/roll to the left (copter will fly left)
    /// * 100 corresponds to a roll angle of max pitch/roll to the right (copter will fly right)
    ///
    /// - note: this value may be clamped if necessary, in order to respect the maximum supported physical tilt of
    /// the copter.
    ///
    /// - parameter roll: the new roll value to set
    func set(roll: Int)

    /// Sets the current vertical speed value.
    ///
    /// Expressed as a signed percentage of the max vertical speed setting (`maxVerticalSpeed`), in range [-100, 100].
    /// * -100 corresponds to max vertical speed towards ground
    /// * 100 corresponds to max vertical speed towards sky
    ///
    /// - parameter verticalSpeed: the new vertical speed value to set
    func set(verticalSpeed: Int)

    /// Activate this piloting interface
    /// - returns: false if it can't be activated
    func activate() -> Bool
}

/// Internal Tracking piloting interface implementation
public class TrackingPilotingItfCore: ActivablePilotingItfCore {

    /// The set of reasons that preclude this piloting interface from being available at present.
    public private(set) var availabilityIssues = Set<TrackingIssue>()

    /// Alerts about issues that currently hinders optimal behavior of this interface.
    public private(set) var qualityIssues = Set<TrackingIssue>()

    /// returns super class backend as TrackingPilotingItfBackend
    private var trackingBackend: TrackingPilotingItfBackend {
        return backend as! TrackingPilotingItfBackend
    }

    // MARK: API methods
    @objc(setPitch:)
    public func set(pitch: Int) {
        trackingBackend.set(pitch: signedPercentInterval.clamp(pitch))
    }

    @objc(setRoll:)
    public func set(roll: Int) {
        trackingBackend.set(roll: signedPercentInterval.clamp(roll))
    }

    @objc(setVerticalSpeed:)
    public func set(verticalSpeed: Int) {
        trackingBackend.set(verticalSpeed: signedPercentInterval.clamp(verticalSpeed))
    }

    /// Activate this piloting interface
    /// - returns: false if it can't be activated
    @objc
    public func activate() -> Bool {
        if state == .idle {
            return trackingBackend.activate()
        }
        return false
    }
}

/// Internal TrackingPilotingItfCore implementation for objectiveC
extension TrackingPilotingItfCore {
    @objc
    public func availabilityIssuesContains(_ issue: TrackingIssue) -> Bool {
        return availabilityIssues.contains(issue)
    }
    @objc
    public func qualityIssuesContains(_ issue: TrackingIssue) -> Bool {
        return qualityIssues.contains(issue)
    }

    @objc
    public func qualityIssuesIsEmpty() -> Bool {
        return qualityIssues.isEmpty
    }

    @objc
    public func availabilityIssuesIsEmpty() -> Bool {
        return availabilityIssues.isEmpty
    }
}

/// Backend callback methods
extension TrackingPilotingItfCore {
    /// Change availabilityIssues
    ///
    /// - parameter availabilityIssues: new set of availabilityIssues
    /// - returns: self to allow call chaining
    /// - note: changes are not notified until notifyUpdated() is called
    @discardableResult public func update(availabilityIssues value: Set<TrackingIssue>) -> TrackingPilotingItfCore {
        if availabilityIssues != value {
            availabilityIssues = value
            markChanged()
        }
        return self
    }

    /// Change qualityIssues
    ///
    /// - parameter qualityIssues: new set of qualityIssues
    /// - returns: self to allow call chaining
    /// - note: changes are not notified until notifyUpdated() is called
    @discardableResult public func update(qualityIssues value: Set<TrackingIssue>) -> TrackingPilotingItfCore {
        if qualityIssues != value {
            qualityIssues = value
            markChanged()
        }
        return self
    }
}
