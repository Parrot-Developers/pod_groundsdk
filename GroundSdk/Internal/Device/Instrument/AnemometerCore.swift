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

/// Internal anemometer instrument implementation
public class AnemometerCore: InstrumentCore, Anemometer {

    /// Speed on the horizontal plan (in m/s)
    private(set) public var horizontalSpeed: Double?

    /// Speed along the north axis (in m/s)
    private(set) public var northSpeed: Double?

    /// Speed along the east axis (in m/s)
    private(set) public var eastSpeed: Double?

    /// Debug description
    public override var description: String {
        return "northSpeed: \(String(describing: northSpeed)) eastSpeed: \(String(describing: eastSpeed))"
            + " horizontalSpeed \(String(describing: horizontalSpeed))"
    }

    /// Constructor
    ///
    /// - Parameter store: component store owning this component
    public init(store: ComponentStoreCore) {
        super.init(desc: Instruments.anemometer, store: store)
    }
}

/// Backend callback methods
extension AnemometerCore {
    /// Changes the horizontal speed.
    ///
    /// - Parameter horizontalSpeed: the horizontal speed to set
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(horizontalSpeed newValue: Double?) -> AnemometerCore {
        if horizontalSpeed != newValue {
            markChanged()
            horizontalSpeed = newValue
        }
        return self
    }

    /// Changes the north speed.
    ///
    /// - Parameter northSpeed: the north speed to set
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(northSpeed newValue: Double?) -> AnemometerCore {
        if northSpeed != newValue {
            markChanged()
            northSpeed = newValue
        }
        return self
    }

    /// Changes the east speed.
    ///
    /// - Parameter eastSpeed: the east speed to set
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(eastSpeed newValue: Double?) -> AnemometerCore {
        if eastSpeed != newValue {
            markChanged()
            eastSpeed = newValue
        }
        return self
    }
}
