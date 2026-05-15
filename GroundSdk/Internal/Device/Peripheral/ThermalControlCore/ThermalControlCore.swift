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

public protocol ThermalControlCoreBackend: ThermalControlBaseBackend {
    /// Sets thermal control mode
    ///
    /// - Parameter mode: the new thermal control mode
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(mode: ThermalControlMode) -> Bool

    /// Sets sensitivity range
    ///
    /// - Parameter range: the new sensitivity range
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(range: ThermalSensitivityRange) -> Bool

    /// Sets emissivity
    ///
    /// - Parameter emissivity: the new emissivity
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(emissivity: Double) -> Bool

    /// Set current palette configuration.
    ///
    /// - Parameter palette: palette configuration
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(palette: ThermalPalette) -> Bool

    /// Set background temperature
    ///
    /// - Parameter backgroundTemperature: background temperature (Kelvin)
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(backgroundTemperature: Double) -> Bool

    /// Set rendering
    ///
    /// - Parameter rendering: rendering configuration
    /// - Returns: true if the command has been sent, false if not connected and the value has been changed immediately
    func set(rendering: ThermalRendering) -> Bool
}

/// Thermal palette setting implementation
class ThermalPaletteSettingCore: ThermalPaletteSetting, CustomDebugStringConvertible {

    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    /// Current palette
    var palette: ThermalPalette {
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
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (ThermalPalette) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, change the current palette
    ///
    /// - Parameters:
    ///   - palette: the new palette
    ///   - updated: whether the update is over or not
    /// - Returns: true if the setting has been changed, false otherwise
    func update(palette newPalette: ThermalPalette, updated: Bool = true) -> Bool {
        if self.updating || _palette != newPalette {
            _palette = newPalette
            if updated {
                timeout.cancel()
            }
            return true
        }
        return false
    }

    /// Called by the backend, change the current colors of the palette
    ///
    /// - Parameters:
    ///   - colors: the new colors
    ///   - updated: whether the update is over or not
    /// - Returns: true if the setting has been changed, false otherwise
    func update(colors newColors: [ThermalColor], updated: Bool = true) -> Bool {
        if self.updating || _palette.colors != newColors {
            _palette.colors = newColors
            if updated {
                timeout.cancel()
            }
            return true
        }
        return false
    }

    /// Implementation backend
    private let backend: ((ThermalPalette) -> Bool)

    /// Thermal palette
    private var _palette: ThermalPalette = ThermalPalette(colors: [ThermalColor.init(0, 0, 0, 0)],
                                                          type: ThermalPaletteType.spot(type: .cold, threshold: 1.0))

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
        return "palette settings updating: [\(updating)]"
    }
}

/// Rendering setting peripheral implementation
class ThermalRenderingSettingCore: ThermalRenderingSetting, CustomDebugStringConvertible {
    var rendering: ThermalRendering {
        get {
            return _rendering
        }
        set {
            if _rendering != newValue && supportedModes.contains(_rendering.mode) {
                if backend(newValue) {
                    let oldValue = _rendering
                    // value sent to the backend, update setting value and mark it updating
                    _rendering = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(rendering: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }

    private var _rendering: ThermalRendering = ThermalRendering(mode: .visible, blendingRate: 0)

    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    /// Supported rendering modes
    var supportedModes: Set<ThermalRenderingMode> = [.visible, .thermal, .blended, .monochrome]

    /// closure to call to change the value
    private let backend: ((ThermalRendering) -> Bool)

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (ThermalRendering) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, change the current rendering
    ///
    /// - Parameter range: new rendering
    /// - Returns: true if the setting has been changed, false otherwise
    func update(rendering newRendering: ThermalRendering) -> Bool {
        if updating || _rendering != newRendering {
            _rendering = newRendering
            timeout.cancel()
            return true
        }
        return false
    }

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
        return "rendering: mode \(rendering.mode) blending rate: \(rendering.blendingRate)" +
               "supported: \(supportedModes) updating: [\(updating)]"
    }
}

/// Thermal control setting implementation
class ThermalControlSettingCore: ThermalControlSetting, CustomDebugStringConvertible {

    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    /// Supported modes
    private(set) var supportedModes: Set<ThermalControlMode> = []

    /// Current mode
    var mode: ThermalControlMode {
        get {
            return _mode
        }
        set {
            if _mode != newValue && supportedModes.contains(newValue) {
                if backend(newValue) {
                    let oldValue = _mode
                    // value sent to the backend, update setting value and mark it updating
                    _mode = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(mode: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }
    /// Thermal control mode
    private var _mode: ThermalControlMode = .disabled

    /// Closure to call to change the value
    private let backend: ((ThermalControlMode) -> Bool)

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (ThermalControlMode) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, sets supported modes
    func update(supportedModes newSupportedModes: Set<ThermalControlMode>) -> Bool {
        if supportedModes != newSupportedModes {
            supportedModes = newSupportedModes
            return true
        }
        return false
    }

    /// Called by the backend, change the current mode
    ///
    /// - Parameter mode: new thermal control mode
    /// - Returns: true if the setting has been changed, false otherwise
    func update(mode newMode: ThermalControlMode) -> Bool {
        if updating || _mode != newMode {
            _mode = newMode
            timeout.cancel()
            return true
        }
        return false
    }

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
        return "mode: \(_mode) \(supportedModes) updating: [\(updating)]"
    }
}

/// Sensitivity range peripheral implementation
class SensitivityRangeSettingCore: ThermalSensitivityRangeSetting, CustomDebugStringConvertible {

    /// Delegate called when the setting value is changed by setting properties
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    var updating: Bool { return timeout.isScheduled }

    /// Supported sensitivity ranges
    var supportedSensitivityRanges: Set<ThermalSensitivityRange> = [.low, .high]

    /// closure to call to change the value
    private let backend: ((ThermalSensitivityRange) -> Bool)

    /// Sensitivity range
    var sensitivityRange: ThermalSensitivityRange {
        get {
            return _sensitivityRange
        }
        set {
            if _sensitivityRange != newValue && supportedSensitivityRanges.contains(newValue) {
                if backend(newValue) {
                    let oldValue = _sensitivityRange
                    // value sent to the backend, update setting value and mark it updating
                    _sensitivityRange = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(range: oldValue) {
                            self.didChangeDelegate.userDidChangeSetting()
                        }
                    }
                    didChangeDelegate.userDidChangeSetting()
                }
            }
        }
    }

    private var _sensitivityRange: ThermalSensitivityRange = .high

    /// Constructor
    ///
    /// - Parameters:
    ///   - didChangeDelegate: delegate called when the setting value is changed by setting properties
    ///   - backend: closure to call to change the setting value
    init(didChangeDelegate: SettingChangeDelegate, backend: @escaping (ThermalSensitivityRange) -> Bool) {
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend
    }

    /// Called by the backend, change the current range
    ///
    /// - Parameter range: new range
    /// - Returns: true if the setting has been changed, false otherwise
    func update(range newRange: ThermalSensitivityRange) -> Bool {
        if updating || _sensitivityRange != newRange {
            _sensitivityRange = newRange
            timeout.cancel()
            return true
        }
        return false
    }

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
        return "sensitivity range: \(_sensitivityRange) \(supportedSensitivityRanges) updating: [\(updating)]"
    }
}

/// Main Camera peripheral implementation
public class ThermalControlCore: ThermalControlBaseCore, ThermalControl {

    /// Control mode setting
    public var modeSetting: ThermalControlSetting {
        return _modeSetting
    }
    private var _modeSetting: ThermalControlSettingCore!

    /// Sensitivity setting
    public var sensitivitySetting: ThermalSensitivityRangeSetting {
        return _sensitivitySetting
    }
    private var _sensitivitySetting: SensitivityRangeSettingCore!

    /// Rendering setting
    public var renderingSetting: ThermalRenderingSetting {
        return _renderingSetting
    }
    private var _renderingSetting: ThermalRenderingSettingCore!

    /// Palette seting
    public var paletteSetting: ThermalPaletteSetting {
        return _paletteSetting
    }
    private var _paletteSetting: ThermalPaletteSettingCore!

    /// Background temperature setting
    public var backgroundTemperatureSetting: DoubleSetting {
        return _backgroundTemperatureSetting
    }
    private var _backgroundTemperatureSetting: DoubleSettingCore!

    /// Emissivity setting
    public var emissivitySetting: DoubleSetting {
        return _emissivitySetting
    }
    private var _emissivitySetting: DoubleSettingCore!

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: Camera backend
    public init(store: ComponentStoreCore, backend: ThermalControlCoreBackend) {
        super.init(desc: Peripherals.thermalControl, store: store, backend: backend)

        _modeSetting = ThermalControlSettingCore(didChangeDelegate: self, backend: { [unowned self] mode in
            return (self.backend as? ThermalControlCoreBackend)?.set(mode: mode) ?? false})

        _sensitivitySetting = SensitivityRangeSettingCore(didChangeDelegate: self, backend: { [unowned self] range in
            return (self.backend as? ThermalControlCoreBackend)?.set(range: range) ?? false})

        _emissivitySetting = DoubleSettingCore(didChangeDelegate: self,
                                               backend: { [unowned self] emissivity in
            return (self.backend as? ThermalControlCoreBackend)?.set(emissivity: emissivity) ?? false})
        _ = _emissivitySetting!.update(min: 0.0, value: 0.0, max: 1.0)

        _backgroundTemperatureSetting = DoubleSettingCore(didChangeDelegate: self,
                                                          backend: { [unowned self] backgroundTempeature in
            return (self.backend as? ThermalControlCoreBackend)?
                .set(backgroundTemperature: backgroundTempeature) ?? false})
        _ = _backgroundTemperatureSetting!.update(min: 0.0, value: 0.0, max: Double.greatestFiniteMagnitude)

        _paletteSetting = ThermalPaletteSettingCore(didChangeDelegate: self, backend: { [unowned self] palette in
            return (self.backend as? ThermalControlCoreBackend)?.set(palette: palette) ?? false})

        _renderingSetting = ThermalRenderingSettingCore(didChangeDelegate: self,
                                                        backend: { [unowned self] rendering in
            return (self.backend as? ThermalControlCoreBackend)?.set(rendering: rendering) ?? false})
    }

    /// Debug description
    public override var description: String {
        return "ThermalControl : setting = \(modeSetting)]"
    }
}

/// Backend callback methods
extension ThermalControlCore {

    /// Updates supported modes.
    ///
    /// - Parameter supportedModes: new supported modes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(
        supportedModes newSupportedMode: Set<ThermalControlMode>) -> ThermalControlCore {
        if _modeSetting.update(supportedModes: newSupportedMode) {
            markChanged()
        }
        return self
    }

    /// Updates current mode.
    ///
    /// - Parameter mode: new thermal control mode
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(mode newMode: ThermalControlMode) -> ThermalControlCore {
        if _modeSetting.update(mode: newMode) {
            markChanged()
        }
        return self
    }

    /// Updates sensitivity range.
    ///
    /// - Parameter range: new sensitivity range
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(range newRange: ThermalSensitivityRange) -> ThermalControlCore {
        if _sensitivitySetting.update(range: newRange) {
            markChanged()
        }
        return self
    }

    /// Updates thermal camera background temperature.
    ///
    /// - Parameter backgroundTemperature: new background temperature
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(backgroundTemperature newBackgroundTemperature: Double)
        -> ThermalControlCore {
        if _backgroundTemperatureSetting!.update(min: 0.0,
                                                 value: newBackgroundTemperature,
                                                 max: Double.greatestFiniteMagnitude) {
            markChanged()
        }
        return self
    }

    /// Updates thermal camera emissivity.
    ///
    /// - Parameter emissivity: new emissivity
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(emissivity newEmissivity: Double) -> ThermalControlBaseCore {
        if _emissivitySetting!.update(min: 0.0, value: newEmissivity, max: 1.0) {
            markChanged()
        }
        return self
    }

    /// Updates thermal palette.
    ///
    /// - Parameters:
    ///   - palette: the new palette
    ///   - updated: whether it needs to be updated or not
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(
        palette newPalette: ThermalPalette, updated: Bool = true) -> ThermalControlCore {
        if _paletteSetting.update(palette: newPalette, updated: updated) && updated {
            markChanged()
        }
        return self
    }

    /// Updates thermal colors.
    ///
    /// - Parameters:
    ///   - colors: the new colors
    ///   - updating: whether it needs to be updated or not
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(
        colors newColors: [ThermalColor], updated: Bool = true) -> ThermalControlCore {
        if _paletteSetting.update(colors: newColors, updated: updated) && updated {
            markChanged()
        }
        return self
    }

    /// Updates thermal camera rendering.
    ///
    /// - Parameter rendering: new rendering
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(rendering newRendering: ThermalRendering) -> ThermalControlCore {
        if _renderingSetting.update(rendering: newRendering) {
            markChanged()
        }
        return self
    }

    /// Cancels all pending settings rollbacks.
    ///
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @objc override public func cancelSettingsRollback() -> ThermalControlCore {
        super.cancelSettingsRollback()
        _modeSetting.cancelRollback { markChanged() }
        _renderingSetting?.cancelRollback { markChanged() }
        _emissivitySetting?.cancelRollback { markChanged() }
        _backgroundTemperatureSetting?.cancelRollback { markChanged() }
        _paletteSetting?.cancelRollback { markChanged() }
        _sensitivitySetting?.cancelRollback { markChanged() }
        return self
    }
}
