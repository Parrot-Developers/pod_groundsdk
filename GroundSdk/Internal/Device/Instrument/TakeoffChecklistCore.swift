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

/// Internal takeoff checklist instrument implementation
public class TakeoffChecklistCore: InstrumentCore, TakeoffChecklist {

    /// Takeoff checklist alarms indexed by kind
    private var takeoffChecklist: [TakeoffAlarm.Kind: TakeoffAlarm] = [:]

    /// Debug description
    public override var description: String {
        return "TakeoffChecklistCore \(takeoffChecklist)"
    }

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: component store owning this component
    public init(store: ComponentStoreCore) {
        super.init(desc: Instruments.takeoffChecklist, store: store)
    }

    public func getAlarm(kind: TakeoffAlarm.Kind) -> TakeoffAlarm {
        return takeoffChecklist[kind] ?? TakeoffAlarm(kind: kind, level: .notAvailable)
    }
}

/// Backend callback methods
extension TakeoffChecklistCore {
    /// Changes the level of a given alarm.
    ///
    /// - Parameters:
    ///    - level: the level of the alarm
    ///    - forAlarm: kind of the alarm
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(level: TakeoffAlarm.Level,
        forAlarm kind: TakeoffAlarm.Kind) -> TakeoffChecklistCore {

        let alarm = getAlarm(kind: kind)
        if alarm.level != level {
            alarm.level = level
            takeoffChecklist[kind] = alarm
            markChanged()
        }

        return self
    }
}
