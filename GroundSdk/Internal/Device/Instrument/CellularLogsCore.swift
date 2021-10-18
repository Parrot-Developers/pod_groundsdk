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

/// CellularLogs instrument implementation.
public class CellularLogsCore: InstrumentCore, CellularLogs {

    /// Log messages related to cellular network.
    private(set) public var messages: [String] = []

    /// Debug description
    public override var description: String {
        return "CellularLogsCore: cellular count \(messages.count)"
    }

    /// Constructor.
    ///
    /// - Parameter store: component store owning this component
    public init(store: ComponentStoreCore) {
        super.init(desc: Instruments.cellularLogs, store: store)
    }
}

/// Backend callback methods.
extension CellularLogsCore {

    /// Updates log messages related to cellular network.
    ///
    /// - Parameter messages: new log messages
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(messages newValue: [String]) -> CellularLogsCore {
        if messages != newValue {
            markChanged()
            messages = newValue
        }
        return self
    }
}
