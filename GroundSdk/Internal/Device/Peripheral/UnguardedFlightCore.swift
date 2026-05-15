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

/// Engine-specific backend for UnguardedFlight.
public protocol UnguardedFlightBackend: AnyObject {

    /// Selects the unguarded flight elements.
    ///
    /// - Returns: `true` if the request was forwarded to the device, otherwise `false`
    func selectElements(elements: Set<UnguardedFlightElement>) -> Bool
}

/// Internal unguarded flight peripheral implementation
public class UnguardedFlightCore: PeripheralCore, UnguardedFlight {
    public var elements: EnumSetSetting<UnguardedFlightElement> {
        return _elements
    }

    /// Internal storage for unguarded flight setting.
    private var _elements: EnumSetSettingCore<UnguardedFlightElement>!

    /// Implementation backend
    private unowned let backend: UnguardedFlightBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: unguarded flight backend
    public init(store: ComponentStoreCore, backend: UnguardedFlightBackend) {
        self.backend = backend
        super.init(desc: Peripherals.unguardedFlight, store: store)
        _elements = EnumSetSettingCore(defaultValues: [], didChangeDelegate: self) {[unowned self] elements in
            return self.backend.selectElements(elements: elements)
        }
    }

    /// Updates elements.
    ///
    /// - Parameter elements: new elements
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(
        elements newElements: Set<UnguardedFlightElement>) -> UnguardedFlightCore {
            if _elements.update(values: newElements) {
                markChanged()
            }
            return self
    }

    /// Updates supported elements
    ///
    /// - Parameter supportedElements: new supported elements
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(supportedElements newSupportedElements: Set<UnguardedFlightElement>) -> UnguardedFlightCore {
        if _elements.update(supportedValues: newSupportedElements) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func cancelSettingsRollback() -> UnguardedFlightCore {
        _elements.cancelRollback { markChanged() }
        return self
    }
}
