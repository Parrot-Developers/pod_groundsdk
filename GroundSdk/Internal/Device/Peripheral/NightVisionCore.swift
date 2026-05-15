// Copyright (C) 2025 Parrot Drones SAS
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

/// Night vision backend part.
public protocol NightVisionBackend: AnyObject {

    /// Activates or deactivates the night vision module.
    ///
    /// - Parameters:
    ///    - value: `true` to activate the night vision module, `false` to deactivate.
    ///    - productId:  the product id
    /// - Returns: `true` if the command has been sent, `false` otherwise.
    func activate(value: Bool, productId: String) -> Bool
}

/// Night vision module implementation
class NightVisionModuleCore: NightVisionModule, CustomDebugStringConvertible {

    /// Product id.
    var productId: String

    /// Version.
    var version: String

    /// Activation setting.
    public var active: BoolSetting {
        return _active
    }

    /// Internal storage for activation setting
    fileprivate var _active: BoolSettingCore!

    /// Closure to call to change the value
    private let backend: NightVisionBackend

    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: night vision backend
    ///    - productId: the product id of the module
    ///    - version: the version id of the module
    public init(didChangeDelegate: SettingChangeDelegate, backend: NightVisionBackend,
                productId: String, version: String) {
        self.backend = backend
        self.didChangeDelegate = didChangeDelegate
        self.productId = productId
        self.version = version
        _active = BoolSettingCore(didChangeDelegate: didChangeDelegate) { [unowned self] value in
            return self.backend.activate(value: value, productId: productId)
        }
    }

    /// Debug description
    var debugDescription: String {
        return "product id:  \(productId) version: \(version) activate: \(_active.value) " +
               "updating: [\(_active.updating)]"
    }
}
/// Internal night vision peripheral implementation
public class NightVisionCore: PeripheralCore, NightVision {

    /// Night vision module.
    public var module: NightVisionModule? {
        _module
    }

    /// Internal storage night vision module.
    private var _module: NightVisionModuleCore?

    /// Implementation backend
    private unowned let backend: NightVisionBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: night vision backend
    public init(store: ComponentStoreCore, backend: NightVisionBackend) {
        self.backend = backend
        super.init(desc: Peripherals.nightVision, store: store)
    }
}

/// Backend callback methods
extension NightVisionCore {

    /// Updates the activation state of the night vision module
    /// - Parameter activate: the activation state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(active newValue: Bool) -> NightVisionCore {
        if _module?._active.update(value: newValue) == true {
            markChanged()
        }
        return self
    }

    /// Creates or updates the night vision module
    ///
    /// - Parameters:
    ///    - productId: the product id of the module
    ///    - version: the version of the module
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(productId: String, version: String) -> NightVisionCore {
        if let _module {
            if _module.productId != productId || _module.version != version {
                _module.productId = productId
                _module.version = version
                markChanged()
            }

        } else {
            _module = NightVisionModuleCore(didChangeDelegate: self,
                                            backend: backend,
                                            productId: productId,
                                            version: version)
            markChanged()
        }
        return self
    }

    /// Destroys the night vision module
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func destroyModule() -> NightVisionCore {
        if _module != nil {
            _module = nil
            markChanged()
        }
        return self
    }
}
