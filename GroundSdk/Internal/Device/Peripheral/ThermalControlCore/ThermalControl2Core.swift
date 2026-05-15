// Copyright (C) 2026 Parrot Drones SAS
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

/// Thermal control 2 backend.
public protocol ThermalControl2CoreBackend: ThermalControlBaseBackend {
    /// Set current palette.
    ///
    /// - Parameter palette: palette
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(palette: ThermalPalette2) -> Bool

    /// Set current rendering mixing mode.
    ///
    /// - Parameter mixingMode: rendering mixing mode
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(mixingMode: ThermalMixingMode) -> Bool

    /// Set current rendering edge coefficient.
    ///
    /// - Parameter edgeCoefficient: rendering edge coefficient
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(edgeCoefficient: Double) -> Bool

    /// Set current rendering minimum colorization threshold.
    ///
    /// - Parameter minColorizationThreshold: rendering minimum colorization threshold
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(minColorizationThreshold: Double) -> Bool

    /// Set current rendering maximum colorization threshold.
    ///
    /// - Parameter maxColorizationThreshold: rendering maximum colorization threshold
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(maxColorizationThreshold: Double) -> Bool

    /// Set current rendering range locked.
    ///
    /// - Parameter rangeLocked: rendering range locked
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(rangeLocked: Bool) -> Bool
}

/// Thermal palette 2 setting implementation
class ThermalPalette2SettingCore: ThermalPalette2Setting, CustomDebugStringConvertible {

    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    /// Current palette
    var palette: ThermalPalette2 {
        get {
            return _palette
        }
        set {
            if _palette != newValue {
                if backend(newValue) {
                    let oldValue = _palette
                    // value sent to the backend, update setting value and mark it updating
                    _palette = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(palette: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                }
                didChangeDelegate.userDidChangeSetting()
            }
        }
    }

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (ThermalPalette2) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, change the current palette
    ///
    /// - Parameters:
    ///   - palette: the new palette
    /// - Returns: true if the setting has been changed, false otherwise
    func update(palette newPalette: ThermalPalette2) -> Bool {
        if self.updating || _palette != newPalette {
            _palette = newPalette
            timeout.cancel()
            return true
        }
        return false
    }

    /// Implementation backend
    private let backend: ((ThermalPalette2) -> Bool)

    /// Thermal palette
    private var _palette = ThermalPalette2(colors: [])

    /// Cancels any pending rollback.
    ///
    /// - Parameter completionClosure: block that will be called if a rollback was pending
    func cancelRollback(completionClosure: () -> Void) {
        if timeout.isScheduled {
            timeout.cancel()
            completionClosure()
        }
    }

    /// Debug description
    var debugDescription: String {
        return "palette settings updating: [\(updating)] colors [\(palette.colors)]"
    }
}

/// Thermal control 2 peripheral implementation
public class ThermalControl2Core: ThermalControlBaseCore, ThermalControl2 {

    /// Thermal palette
    public var paletteSetting: ThermalPalette2Setting {
        return _paletteSetting
    }
    private var _paletteSetting: ThermalPalette2SettingCore!

    /// Rendering mixing mode
    public var mixingMode: EnumSetting<ThermalMixingMode> {
        return _mixingMode
    }
    private var _mixingMode: EnumSettingCore<ThermalMixingMode>!

    /// Rendering edge coefficient
    public var edgeCoefficient: DoubleSetting {
        return _edgeCoefficient
    }
    private var _edgeCoefficient: DoubleSettingCore!

    /// Rendering minimum colorization threshold
    public var minColorizationThreshold: DoubleSetting {
        return _minColorizationThreshold
    }
    private var _minColorizationThreshold: DoubleSettingCore!

    /// Rendering maximum colorization threshold
    public var maxColorizationThreshold: DoubleSetting {
        return _maxColorizationThreshold
    }
    private var _maxColorizationThreshold: DoubleSettingCore!

    /// Rendering range locked
    public var rangeLocked: BoolSetting {
        return _rangeLocked
    }
    private var _rangeLocked: BoolSettingCore!

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: thermal control 2 backend
    public init(store: ComponentStoreCore, backend: ThermalControl2CoreBackend) {
        super.init(desc: Peripherals.thermalControl2, store: store, backend: backend)

        _paletteSetting = ThermalPalette2SettingCore(didChangeDelegate: self, backend: { [unowned self] value in
            return (self.backend as? ThermalControl2CoreBackend)?.set(palette: value) ?? false}
        )

        _mixingMode = EnumSettingCore(defaultValue: .fullThermal, supportedValues: [.blended, .fullThermal],
                                      didChangeDelegate: self) { [unowned self] value in
            return (self.backend as? ThermalControl2CoreBackend)?.set(mixingMode: value) ?? false
        }

        _edgeCoefficient = DoubleSettingCore(didChangeDelegate: self,
                                               backend: { [unowned self] value in
            return (self.backend as? ThermalControl2CoreBackend)?.set(edgeCoefficient: value) ?? false
        })

        _minColorizationThreshold = DoubleSettingCore(didChangeDelegate: self,
                                               backend: { [unowned self] value in
            return (self.backend as? ThermalControl2CoreBackend)?.set(minColorizationThreshold: value) ?? false
        })

        _maxColorizationThreshold = DoubleSettingCore(didChangeDelegate: self,
                                                      backend: { [unowned self] value in
            return (self.backend as? ThermalControl2CoreBackend)?.set(maxColorizationThreshold: value) ?? false
        })

        _rangeLocked = BoolSettingCore(didChangeDelegate: self,
                                       backend: { [unowned self] value in
            return (self.backend as? ThermalControl2CoreBackend)?.set(rangeLocked: value) ?? false
        })
    }
}

/// Backend callback methods
extension ThermalControl2Core {
    /// Called by the backend, change the current rendering mixing mode
    ///
    /// - Parameter mixingMode: new mixing mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(mixingMode newMixingMode: ThermalMixingMode) -> ThermalControl2Core {
        if _mixingMode!.update(value: newMixingMode) {
            markChanged()
        }
        return self
    }

    /// Called by the backend, change the current rendering edge coefficient
    ///
    /// - Parameter edgeCoefficient: new edge coefficient
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(edgeCoefficient newEdgeCoefficient: Double) -> ThermalControl2Core {
        if _edgeCoefficient!.update(min: 0, value: newEdgeCoefficient, max: 1) {
            markChanged()
        }
        return self
    }

    /// Called by the backend, change the current rendering minimum colorization threshold
    ///
    /// - Parameter minColorizationThreshold: new minimum colorization threshold
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(minColorizationThreshold newMinColorizationThreshold: Double)
        -> ThermalControl2Core {
        if _minColorizationThreshold!.update(min: 0, value: newMinColorizationThreshold, max: 1) {
            markChanged()
        }
        return self
    }

    /// Called by the backend, change the current rendering maximum colorization threshold
    ///
    /// - Parameter maxColorizationThreshold: new maximum colorization threshold
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(maxColorizationThreshold newMaxColorizationThreshold: Double)
        -> ThermalControl2Core {
        if _maxColorizationThreshold!.update(min: 0, value: newMaxColorizationThreshold, max: 1) {
            markChanged()
        }
        return self
    }

    /// Called by the backend, change the current rendering range locked
    ///
    /// - Parameter rangeLocked: new range locked
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(rangeLocked newRangeLocked: Bool) -> ThermalControl2Core {
        if _rangeLocked!.update(value: newRangeLocked) {
            markChanged()
        }
        return self
    }

    /// Called by the backend, change the current palette
    ///
    /// - Parameter palette: new palette
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(palette newPalette: ThermalPalette2) -> ThermalControl2Core {
        if _paletteSetting!.update(palette: newPalette) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @objc @discardableResult override public func cancelSettingsRollback() -> ThermalControl2Core {
        super.cancelSettingsRollback()
        _paletteSetting.cancelRollback { markChanged() }
        _mixingMode.cancelRollback { markChanged() }
        _minColorizationThreshold.cancelRollback { markChanged() }
        _maxColorizationThreshold.cancelRollback { markChanged() }
        _edgeCoefficient.cancelRollback { markChanged() }
        _rangeLocked.cancelRollback { markChanged() }
        return self
    }
}
