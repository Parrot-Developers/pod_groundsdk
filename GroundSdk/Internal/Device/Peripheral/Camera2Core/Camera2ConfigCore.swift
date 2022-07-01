// Copyright (C) 2020 Parrot Drones SAS
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

/// Protocol for configuration parameters.
private protocol ConfigParam: AnyObject {
    /// Checks if parameter value conforms to a rule.
    ///
    /// - Parameter rule: rule against which parameter value is checked
    /// - Returns: `true` if the value is not defined or if the value is contains
    /// in the parameter domain defined by the rule, `false` otherwise
    func check(rule: Camera2Rule) -> Bool
}

/// Protocol for editable configuration parameters.
private protocol EditableConfigParam: ConfigParam {
    /// `true`if parameter value is defined  or no possible value in the current configuration.
    var configured: Bool { get }

    /// Gets parameter value as ParamValueBase, `nil` if value is not defined.
    var paramValue: ParamValueBase? { get }

    /// Clears parameter value if not supported in current configuration.
    func fix()

    /// Sets parameter value to first supported value in current configuration.
    func autoComplete()

    /// Clears parameter value.
    func clear()
}

/// Camera2ImmutableParam implementation.
class Camera2ImmutableParamCore<T: Hashable>: Camera2ImmutableParam<T>, ConfigParam {

    /// Parameter descriptor.
    private let desc: Camera2Param<T>

    /// Editor holding rules and parameters.
    private unowned let editor: Camera2EditorCore

    override var overallSupportedValues: Set<T> {
        editor[desc]?.overallSupportedValues ?? []
    }

    override var currentSupportedValues: Set<T> {
        editor[desc]?.currentSupportedValues ?? []
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - param: parameter descriptor
    ///   - value: parameter value
    ///   - editor: editor holding rules and parameters
    init(_ desc: Camera2Param<T>, _ value: T, editor: Camera2EditorCore) {
        self.desc = desc
        self.editor = editor
        super.init(value: value)
    }

    public func check(rule: Camera2Rule) -> Bool {
        (editor[desc] as? Camera2EditableParamCore<T>)?.check(rule: rule) ?? true
    }
}

/// Camera2DoubleCore implementation.
class Camera2DoubleCore: Camera2Double, ConfigParam {

    /// Parameter descriptor.
    private let desc: Camera2Param<Double>

    /// Editor holding rules and parameters.
    private unowned let editor: Camera2EditorCore

    override var overallSupportedValues: ClosedRange<Double>? {
        editor[desc]?.overallSupportedValues
    }

    override var currentSupportedValues: ClosedRange<Double>? {
        editor[desc]?.currentSupportedValues
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - param: parameter descriptor
    ///   - value: parameter value
    ///   - editor: editor holding rules and parameters
    init(_ desc: Camera2Param<Double>, _ value: Double, editor: Camera2EditorCore) {
        self.desc = desc
        self.editor = editor
        super.init(value: value)
    }

    func check(rule: Camera2Rule) -> Bool {
        (editor[desc] as? Camera2EditableDoubleCore)?.check(rule: rule) ?? true
    }
}

/// Camera2EditableParam implementation.
class Camera2EditableParamCore<T: Hashable>: Camera2EditableParam<T>, EditableConfigParam {

    /// Editor holding rules and parameters.
    private unowned let editor: Camera2EditorCore

    /// Function called to get parameter domain from a given rule.
    private let selectDomain: ((Camera2Rule) -> Set<T>?)

    override var overallSupportedValues: Set<T> {
        Set(editor.rules.compactMap {selectDomain($0)?.compactMap {$0}}.joined())
    }

    override var currentSupportedValues: Set<T> {
        editor.rules.reduce(Set<T>()) { values, rule in
            let valid = editor.sortedParams.allSatisfy { $0 === self || $0.check(rule: rule) }
            if valid, let domain = selectDomain(rule) {
                return values.union(domain)
            } else {
                return values
            }
        }
    }

    override var value: T? {
        get {
            _value
        }
        set {
            if _value != newValue {
                if newValue == nil {
                    _value = nil
                } else if currentSupportedValues.contains(newValue!) {
                    _value = newValue
                } else if overallSupportedValues.contains(newValue!) {
                    _value = newValue
                    editor.sortedParams.forEach {
                        if $0 !== self { $0.fix() }
                    }
                }
            }
        }
    }
    var _value: T?

    var configured: Bool {
        _value != nil || currentSupportedValues.isEmpty
    }

    var paramValue: ParamValueBase? {
        if let value = value {
            return ParamValue<T>(value)
        }
        return nil
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - value: parameter value
    ///   - editor: editor holding rules and parameters
    ///   - selectDomain: called to get parameter domain from a given rule
    init(_ value: T?, editor: Camera2EditorCore, selectDomain: @escaping ((Camera2Rule) -> Set<T>?)) {
        self.editor = editor
        self.selectDomain = selectDomain
        _value = value
        super.init()
    }

    func check(rule: Camera2Rule) -> Bool {
        if let value = value,
            let domain = selectDomain(rule) {
            return domain.contains(value)
        }
        return true
    }

    func fix() {
        if let value = value,
            !currentSupportedValues.contains(value) {
            _value = nil
        }
    }

    func autoComplete() {
        if value == nil {
            _value = currentSupportedValues.first
        }
    }

    func clear() {
        _value = nil
    }
}

/// Camera2EditableDouble implementation.
class Camera2EditableDoubleCore: Camera2EditableDouble, EditableConfigParam {

    /// Editor holding rules and parameters.
    private unowned let editor: Camera2EditorCore

    /// Function called to get parameter domain from a given rule.
    private let selectDomain: ((Camera2Rule) -> ClosedRange<Double>?)

    override var overallSupportedValues: ClosedRange<Double>? { getRange(rules: editor.rules) }

    override var currentSupportedValues: ClosedRange<Double>? {
        let validRules = editor.rules.filter { rule in
            editor.sortedParams.allSatisfy { $0 === self || $0.check(rule: rule) }
        }
        return getRange(rules: validRules)
    }

    override var value: Double? {
        get {
            _value
        }
        set {
            if _value != newValue {
                if newValue == nil {
                    _value = nil
                } else if let currentSupportedValues = currentSupportedValues,
                    currentSupportedValues.contains(newValue!) {
                    _value = newValue
                } else if let overallSupportedValues = overallSupportedValues,
                    overallSupportedValues.contains(newValue!) {
                    _value = newValue
                    editor.sortedParams.forEach {
                        if $0 !== self { $0.fix() }
                    }
                }
            }
        }
    }
    var _value: Double?

    var configured: Bool {
        _value != nil || currentSupportedValues == nil
    }

    var paramValue: ParamValueBase? {
        if let value = value {
            return ParamValue<Double>(value)
        }
        return nil
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - value: parameter value
    ///   - editor: editor holding rules and parameters
    ///   - selectDomain: called to get parameter domain from a given rule
    init(_ value: Double?, editor: Camera2EditorCore, selectDomain: @escaping ((Camera2Rule) -> ClosedRange<Double>?)) {
        self.editor = editor
        self.selectDomain = selectDomain
        _value = value
        super.init()
    }

    func check(rule: Camera2Rule) -> Bool {
        if let value = value,
            let domain = selectDomain(rule) {
            return domain.contains(value)
        }
        return true
    }

    func fix() {
        if let value = value,
            currentSupportedValues == nil || !currentSupportedValues!.contains(value) {
            _value = nil
        }
    }

    func autoComplete() {
        if !configured {
            _value = currentSupportedValues?.lowerBound
        }
    }

    func clear() {
        _value = nil
    }

    /// Computes range of supported values in a collection of rules.
    ///
    /// - Parameter rules: rules
    /// - Returns: range of supported values in rules
    private func getRange(rules: [Camera2Rule]) -> ClosedRange<Double>? {
        if let lower = rules.compactMap({selectDomain($0)?.lowerBound}).min(),
            let upper = rules.compactMap({selectDomain($0)?.upperBound}).max() {
            return lower...upper
        } else {
            return nil
        }
    }
}

/// Base class for configuration parameter value.
public class ParamValueBase: Equatable {

    /// Equatable concordance.
    public static func == (lhs: ParamValueBase, rhs: ParamValueBase) -> Bool {
        lhs.isEqual(other: rhs)
    }

    /// Compares with another ParamValueBase instance.
    ///
    /// - Parameter other: ParamValueBase instance to compare with
    /// - Returns: `true` if the two instances are equal, `false` otherwise
    /// - Note: Subclasses should override this function.
    public func isEqual(other: ParamValueBase?) -> Bool {
        other === self
    }
}

/// Configuration parameter value.
public class ParamValue<V: Equatable>: ParamValueBase {

    /// Parameter value.
    let value: V

    /// Constructor.
    ///
    /// - Parameter value: parameter value
    init(_ value: V) {
        self.value = value
    }

    /// Equatable concordance.
    public static func == (lhs: ParamValue<V>, rhs: ParamValue<V>) -> Bool {
        lhs.isEqual(other: rhs)
    }

    /// Compares with another ParamValueBase instance.
    ///
    /// - Parameter other: ParamValueBase instance to compare with
    /// - Returns: `true` if the two instances are equal, `false` otherwise
    override public func isEqual(other: ParamValueBase?) -> Bool {
        if let other = other as? ParamValue<V> {
            return value == other.value
        }
        return false
    }
}

/// Base class for configuration parameter domain.
public class ParamDomainBase: Equatable {

    /// Equatable concordance.
    public static func == (lhs: ParamDomainBase, rhs: ParamDomainBase) -> Bool {
        lhs.isEqual(other: rhs)
    }

    /// Compares with another ParamDomainBase instance.
    ///
    /// - Parameter other: ParamDomainBase instance to compare with
    /// - Returns: `true` if the two instances are equal, `false` otherwise
    /// - Note: Subclasses should override this function.
    public func isEqual(other: ParamDomainBase?) -> Bool {
        other === self
    }
}

/// Configuration parameter domain.
public class ParamDomain<D: Equatable>: ParamDomainBase {

    /// Parameter domain.
    let domain: D

    /// Constructor.
    ///
    /// - Parameter domain: parameter domain
    init(_ domain: D) {
        self.domain = domain
    }

    /// Equatable concordance.
    public static func == (lhs: ParamDomain<D>, rhs: ParamDomain<D>) -> Bool {
        lhs.domain == rhs.domain
    }

    /// Compares with another ParamDomainBase instance.
    ///
    /// - Parameter other: ParamDomainBase instance to compare with
    /// - Returns: `true` if the two instances are equal, `false` otherwise
    override public func isEqual(other: ParamDomainBase?) -> Bool {
        if let other = other as? ParamDomain<D> {
            return domain == other.domain
        }
        return false
    }
}

/// Camera rule.
public struct Camera2Rule: Equatable {

    /// Rule index.
    public let index: Int

    /// Parameters domains by identifiers.
    private var domains: [Camera2ParamId: ParamDomainBase] = [:]

    /// Provides access to the domain of a parameter.
    ///
    /// - Parameter paramDesc: configuration parameter descriptor
    /// - Returns: the parameter domain or `nil` if not defined in that rule
    public subscript<V: Hashable>(_ paramDesc: Camera2Param<V>) -> Set<V>? {
        get {
            (domains[paramDesc.id] as? ParamDomain<Set<V>>)?.domain
        }
        set {
            if let domain = newValue {
                let param = ParamDomain<Set<V>>(domain)
                domains[paramDesc.id] = param
            } else {
                domains.removeValue(forKey: paramDesc.id)
            }
        }
    }

    /// Provides access to the domain of a parameter of type `Double`.
    ///
    /// - Parameter paramDesc: configuration parameter descriptor
    /// - Returns: the parameter domain or `nil` if not defined in that rule
    public subscript<Double>(_ paramDesc: Camera2Param<Double>) -> ClosedRange<Double>? {
        get {
            (domains[paramDesc.id] as? ParamDomain<ClosedRange<Double>>)?.domain
        }
        set {
            if let domain = newValue {
                let param = ParamDomain<ClosedRange<Double>>(domain)
                domains[paramDesc.id] = param
            } else {
                domains.removeValue(forKey: paramDesc.id)
            }
        }
    }

    /// Constructor.
    ///
    /// - Parameter index: rule index
    public init(index: Int) {
        self.index = index
    }

    /// Equatable concordance.
    public static func == (lhs: Camera2Rule, rhs: Camera2Rule) -> Bool {
        lhs.domains == rhs.domains
    }
}

/// Camera2Editor implementation.
class Camera2EditorCore: Camera2Editor {

    /// Closure to call to change the configuration.
    private let backend: ((Camera2ConfigCore.Config) -> Bool)

    /// Configuration rules.
    fileprivate var rules: [Camera2Rule]!

    /// Configuration parameters by identifiers.
    private var params: [Camera2ParamId: EditableConfigParam] = [:]

    /// Configurations parameters sorted by parameter id.
    fileprivate var sortedParams: [EditableConfigParam]!

    /// Constructor.
    ///
    /// - Parameters:
    ///   - rules: configuration rules
    ///   - config: initial configuration or `nil` if starting configuration from scratch
    ///   - backend: closure to call to change the configuration
    fileprivate init(rules: [Int: Camera2Rule],
                     config: Camera2ConfigCore.Config?,
                     backend: @escaping ((Camera2ConfigCore.Config) -> Bool)) {
        self.backend = backend

        self.rules = rules.sorted { $0.0 > $1.0 }.compactMap { $0.value }

        params[.mode] = param(Camera2Params.mode, config: config)
        params[.photoMode] = param(Camera2Params.photoMode, config: config)
        params[.photoDynamicRange] = param(Camera2Params.photoDynamicRange, config: config)
        params[.photoResolution] = param(Camera2Params.photoResolution, config: config)
        params[.photoFormat] = param(Camera2Params.photoFormat, config: config)
        params[.photoFileFormat] = param(Camera2Params.photoFileFormat, config: config)
        params[.photoDigitalSignature] = param(Camera2Params.photoDigitalSignature, config: config)
        params[.photoBracketing] = param(Camera2Params.photoBracketing, config: config)
        params[.photoBurst] = param(Camera2Params.photoBurst, config: config)
        params[.photoTimelapseInterval] = param(Camera2Params.photoTimelapseInterval, config: config)
        params[.photoGpslapseInterval] = param(Camera2Params.photoGpslapseInterval, config: config)
        params[.photoStreamingMode] = param(Camera2Params.photoStreamingMode, config: config)
        params[.videoRecordingMode] = param(Camera2Params.videoRecordingMode, config: config)
        params[.videoRecordingDynamicRange] = param(Camera2Params.videoRecordingDynamicRange, config: config)
        params[.videoRecordingCodec] = param(Camera2Params.videoRecordingCodec, config: config)
        params[.videoRecordingResolution] = param(Camera2Params.videoRecordingResolution, config: config)
        params[.videoRecordingFramerate] = param(Camera2Params.videoRecordingFramerate, config: config)
        params[.videoRecordingBitrate] = param(Camera2Params.videoRecordingBitrate, config: config)
        params[.audioRecordingMode] = param(Camera2Params.audioRecordingMode, config: config)
        params[.autoRecordMode] = param(Camera2Params.autoRecordMode, config: config)
        params[.exposureMode] = param(Camera2Params.exposureMode, config: config)
        params[.maximumIsoSensitivity] = param(Camera2Params.maximumIsoSensitivity, config: config)
        params[.isoSensitivity] = param(Camera2Params.isoSensitivity, config: config)
        params[.shutterSpeed] = param(Camera2Params.shutterSpeed, config: config)
        params[.exposureCompensation] = param(Camera2Params.exposureCompensation, config: config)
        params[.whiteBalanceMode] = param(Camera2Params.whiteBalanceMode, config: config)
        params[.whiteBalanceTemperature] = param(Camera2Params.whiteBalanceTemperature, config: config)
        params[.imageStyle] = param(Camera2Params.imageStyle, config: config)
        params[.imageContrast] = param(Camera2Params.imageContrast, config: config)
        params[.imageSaturation] = param(Camera2Params.imageSaturation, config: config)
        params[.imageSharpness] = param(Camera2Params.imageSharpness, config: config)
        params[.zoomMaxSpeed] = param(Camera2Params.zoomMaxSpeed, config: config)
        params[.zoomVelocityControlQualityMode] = param(Camera2Params.zoomVelocityControlQualityMode, config: config)
        params[.alignmentOffsetPitch] = param(Camera2Params.alignmentOffsetPitch, config: config)
        params[.alignmentOffsetRoll] = param(Camera2Params.alignmentOffsetRoll, config: config)
        params[.alignmentOffsetYaw] = param(Camera2Params.alignmentOffsetYaw, config: config)
        params[.autoExposureMeteringMode] = param(Camera2Params.autoExposureMeteringMode, config: config)
        params[.storagePolicy] = param(Camera2Params.storagePolicy, config: config)

        sortedParams = params.sorted { $0.0.rawValue > $1.0.rawValue }.compactMap { $0.value }
    }

    /// Edited configuration.
    fileprivate var config: Camera2ConfigCore.Config {
        var configParams = [Camera2ParamId: ParamValueBase]()
        for (paramId, param) in params {
            if let param = param.paramValue {
                configParams[paramId] = param
            }
        }
        return Camera2ConfigCore.Config(params: configParams)
    }

    var complete: Bool {
        sortedParams.allSatisfy { $0.configured }
    }

    func autoComplete() -> Camera2Editor {
        sortedParams.forEach { $0.autoComplete() }
        return self
    }

    func clear() -> Camera2Editor {
        sortedParams.forEach { $0.clear() }
        return self
    }

    func commit() -> Bool {
        if complete {
            return backend(config)
        }
        return false
    }

    subscript<V: Hashable>(_ paramDesc: Camera2Param<V>) -> Camera2EditableParam<V>? {
        params[paramDesc.id] as? Camera2EditableParamCore<V>
    }

    subscript(_ paramDesc: Camera2Param<Double>) -> Camera2EditableDouble? {
        params[paramDesc.id] as? Camera2EditableDouble
    }

    /// Creates an editable configuration parameter of type `V`.
    ///
    /// - Parameters:
    ///   - param: configuration parameter descriptor
    ///   - config: configuration holding parameter value or `nil` if parameter value shall not be initialized
    /// - Returns: created configuration parameter
    private func param<V: Hashable>(_ param: Camera2Param<V>,
                                    config: Camera2ConfigCore.Config?) -> EditableConfigParam {
        Camera2EditableParamCore<V>(config?[param], editor: self) { $0[param] }
    }

    /// Creates an editable configuration parameter of type `Double`.
    ///
    /// - Parameters:
    ///   - param: configuration parameter descriptor
    ///   - config: configuration holding parameter value or `nil` if parameter value shall not be initialized
    /// - Returns: created configuration parameter
    private func param(_ param: Camera2Param<Double>,
                       config: Camera2ConfigCore.Config?) -> EditableConfigParam {
        Camera2EditableDoubleCore(config?[param], editor: self) { $0[param] }
    }
}

/// Camera2Config implementation.
public class Camera2ConfigCore: Camera2Config {

    /// Camera configuration.
    public struct Config: Equatable {

        /// Parameters values by identifiers.
        public var params: [Camera2ParamId: ParamValueBase]

        /// Constructor.
        ///
        /// - Parameter params: parameters values by identifiers
        public init(params: [Camera2ParamId: ParamValueBase]) {
            self.params = params
        }

        /// Provides access to a parameter value.
        ///
        /// - Parameter param: configuration parameter descriptor
        /// - Returns: the parameter value or `nil` if not defined
        public subscript<V>(_ paramDesc: Camera2Param<V>) -> V? where V: Equatable {
            get {
                (params[paramDesc.id] as? ParamValue<V>)?.value
            }
            set {
                if let value = newValue {
                    let param = ParamValue<V>(value)
                    params[paramDesc.id] = param
                } else {
                    params.removeValue(forKey: paramDesc.id)
                }
            }
        }

        /// Equatable concordance.
        public static func == (lhs: Camera2ConfigCore.Config, rhs: Camera2ConfigCore.Config) -> Bool {
            lhs.params == rhs.params
        }

        /// Creates a new config with differences from this config to another config.
        ///
        /// - Parameter other: the other config
        /// - Returns: a new config with differences from this config to the other config
        public func diffFrom(_ other: Config) -> Config {
            var diffParams = [Camera2ParamId: ParamValueBase]()
            params.forEach {
                if !$0.value.isEqual(other: other.params[$0.key]) {
                    diffParams[$0.key] = $0.value
                }
            }
            return Config(params: diffParams)
        }
    }

    /// Camera capabilities.
    public final class Capabilities: Equatable {

        /// Configuration rules by index.
        public let rules: [Int: Camera2Rule]

        /// Constructor.
        ///
        /// - Parameter rules: configuration rules by index
        public init(rules: [Int: Camera2Rule]) {
            self.rules = rules
        }

        /// Merges rules with another capabilties rules.
        /// Rules of the other capabilities will override existing rules.
        ///
        /// - Parameter other: capabilities to merge
        /// - Returns: merged capabilities
        public func overriddenBy(other: Capabilities) -> Capabilities {
            var mergedRules = rules
            mergedRules.merge(other.rules, uniquingKeysWith: { (_, new) in new })
            return Capabilities(rules: mergedRules)
        }

        /// Equatable concordance.
        public static func == (lhs: Capabilities, rhs: Capabilities) -> Bool {
            lhs.rules == rhs.rules
        }
    }

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Tells if the setting value has been changed and is waiting for change confirmation
    public var updating: Bool { timeout.isScheduled }

    /// Delegate called when the configuration is commited by the user.
    private unowned let didChangeDelegate: SettingChangeDelegate

    /// Closure to call to change the configuration.
    private let backend: ((Config) -> Bool)

    public var supportedParams: Set<Camera2ParamId> {
        [.mode, .photoMode, .photoDynamicRange, .photoResolution, .photoFormat, .photoFileFormat,
         .photoDigitalSignature, .photoBracketing, .photoBurst, .photoTimelapseInterval, .photoGpslapseInterval,
         .photoStreamingMode, .videoRecordingMode, .videoRecordingDynamicRange, .videoRecordingCodec,
         .videoRecordingResolution, .videoRecordingFramerate, .videoRecordingBitrate,
         .audioRecordingMode, .autoRecordMode, .exposureMode, .maximumIsoSensitivity,
         .isoSensitivity, .shutterSpeed, .exposureCompensation, .whiteBalanceMode, .whiteBalanceTemperature,
         .imageStyle, .imageContrast, .imageSaturation, .imageSharpness, .zoomMaxSpeed,
         .zoomVelocityControlQualityMode, .alignmentOffsetPitch, .alignmentOffsetRoll, .alignmentOffsetYaw,
         .autoExposureMeteringMode, .storagePolicy]
    }

    /// Current configuration.
    private var config: Config {
        didSet {
            validator = Camera2EditorCore(rules: capabilities.rules, config: config) { _ in return false }
        }
    }

    /// Current capabilities.
    private var capabilities: Capabilities {
        didSet {
            validator = Camera2EditorCore(rules: capabilities.rules, config: config) { _ in return false }
        }
    }

    /// Validator for current configuration and capabilities.
    private var validator: Camera2EditorCore

    /// Constructor.
    ///
    /// - Parameters:
    ///   - initialConfig: camera configuration
    ///   - capabilities: camera capabilities
    ///   - didChangeDelegate: delegate called when the configuration is commited by the user
    ///   - backend: closure to call to change the configuration
    init(initialConfig: Config,
         capabilities: Capabilities,
         didChangeDelegate: SettingChangeDelegate,
         backend: @escaping (Config) -> Bool) {
        config = initialConfig
        self.capabilities = capabilities
        self.didChangeDelegate = didChangeDelegate
        self.backend = backend

        validator = Camera2EditorCore(rules: capabilities.rules, config: config) { _ in return false }
    }

    public subscript<V>(_ paramDesc: Camera2Param<V>) -> Camera2ImmutableParam<V>? {
        if let value = config[paramDesc] {
            return Camera2ImmutableParamCore<V>(paramDesc, value, editor: validator)
        } else {
            return nil
        }
    }

    public subscript(_ paramDesc: Camera2Param<Double>) -> Camera2Double? {
        if let value = config[paramDesc] {
            return Camera2DoubleCore(paramDesc, value, editor: validator)
        } else {
            return nil
        }
    }

    public func edit(fromScratch: Bool) -> Camera2Editor {
        Camera2EditorCore(rules: capabilities.rules,
                          config: fromScratch ? nil : validator.config) { [unowned self] config in
                            return self.set(config: config)
        }
    }

    /// Changes configuration from the api.
    ///
    /// - Parameter newConfig: new configuration
    /// - Returns: true if the config has been commited, false otherwise
    private func set(config newConfig: Config) -> Bool {
        if config != newConfig {
            if backend(newConfig) {
                let oldConfig = config
                // configuration sent to the backend, update configuration and mark it updating
                config = newConfig
                timeout.schedule { [weak self] in
                    if let `self` = self, self.update(config: oldConfig) {
                        self.didChangeDelegate.userDidChangeSetting()
                    }
                }
                didChangeDelegate.userDidChangeSetting()
            }
        }
        return true
    }

    /// Changes the current configuration.
    ///
    /// - Parameter newConfig: new configuration
    /// - Returns: true if the configuration has been changed, false otherwise
    public func update(config newConfig: Config) -> Bool {
        if updating || config != newConfig {
            config = newConfig
            timeout.cancel()
            return true
        }
        return false
    }

    /// Changes the current capabilities.
    ///
    /// - Parameter newCapabilities: new capabilities
    /// - Returns: true if the capabilities have been changed, false otherwise
    public func update(capabilities newCapabilties: Capabilities) -> Bool {
        if capabilities != newCapabilties {
            capabilities = newCapabilties
            return true
        }
        return false
    }

    /// Cancels any pending rollback.
    ///
    /// - Returns: true if a rollback was pending, false otherwise
    @discardableResult
    public func cancelRollback() -> Bool {
        if timeout.isScheduled {
            timeout.cancel()
            return true
        }
        return false
    }
}

/// Extension implementing debug description.
extension Camera2ConfigCore.Config: CustomStringConvertible {
    /// Debug description.
    public var description: String {
        var params: [String] = []
        self[Camera2Params.mode].map { params.append("mode: \($0.description)") }
        self[Camera2Params.photoMode].map { params.append("photoMode: \($0.description)") }
        self[Camera2Params.photoDynamicRange].map { params.append("photoDynamicRange: \($0.description)") }
        self[Camera2Params.photoResolution].map { params.append("photoResolution: \($0.description)") }
        self[Camera2Params.photoFormat].map { params.append("photoFormat: \($0.description)") }
        self[Camera2Params.photoFileFormat].map { params.append("photoFileFormat: \($0.description)") }
        self[Camera2Params.photoDigitalSignature].map { params.append("photoDigitalSignature: \($0.description)") }
        self[Camera2Params.photoBracketing].map { params.append("photoBracketing: \($0.description)") }
        self[Camera2Params.photoBurst].map { params.append("photoBurst: \($0.description)") }
        self[Camera2Params.photoTimelapseInterval].map { params.append("photoTimelapseInterval: \($0.description)") }
        self[Camera2Params.photoGpslapseInterval].map { params.append("photoGpslapseInterval: \($0.description)") }
        self[Camera2Params.photoStreamingMode].map { params.append("photoStreamingMode: \($0.description)") }
        self[Camera2Params.videoRecordingMode].map { params.append("videoRecordingMode: \($0.description)") }
        self[Camera2Params.videoRecordingDynamicRange].map {
            params.append("videoRecordingDynamicRange: \($0.description)")
        }
        self[Camera2Params.videoRecordingCodec].map { params.append("videoRecordingCodec: \($0.description)") }
        self[Camera2Params.videoRecordingResolution].map {
            params.append("videoRecordingResolution: \($0.description)")
        }
        self[Camera2Params.videoRecordingFramerate].map { params.append("videoRecordingFramerate: \($0.description)") }
        self[Camera2Params.videoRecordingBitrate].map { params.append("videoRecordingBitrate: \($0.description)") }
        self[Camera2Params.audioRecordingMode].map { params.append("audioRecordingMode: \($0.description)") }
        self[Camera2Params.autoRecordMode].map { params.append("autoRecordMode: \($0.description)") }
        self[Camera2Params.exposureMode].map { params.append("exposureMode: \($0.description)") }
        self[Camera2Params.maximumIsoSensitivity].map { params.append("maximumIsoSensitivity: \($0.description)") }
        self[Camera2Params.isoSensitivity].map { params.append("isoSensitivity: \($0.description)") }
        self[Camera2Params.shutterSpeed].map { params.append("shutterSpeed: \($0.description)") }
        self[Camera2Params.exposureCompensation].map { params.append("exposureCompensation: \($0.description)") }
        self[Camera2Params.whiteBalanceMode].map { params.append("whiteBalanceMode: \($0.description)") }
        self[Camera2Params.whiteBalanceTemperature].map { params.append("whiteBalanceTemperature: \($0.description)") }
        self[Camera2Params.imageStyle].map { params.append("imageStyle: \($0.description)") }
        self[Camera2Params.imageContrast].map { params.append("imageContrast: \($0.description)") }
        self[Camera2Params.imageSaturation].map { params.append("imageSaturation: \($0.description)") }
        self[Camera2Params.imageSharpness].map { params.append("imageSharpness: \($0.description)") }
        self[Camera2Params.zoomMaxSpeed].map { params.append("zoomMaxSpeed: \($0.description)") }
        self[Camera2Params.zoomVelocityControlQualityMode].map {
            params.append("zoomVelocityControlQualityMode: \($0.description)")
        }
        self[Camera2Params.alignmentOffsetPitch].map { params.append("alignmentOffsetPitch: \($0.description)") }
        self[Camera2Params.alignmentOffsetRoll].map { params.append("alignmentOffsetRoll: \($0.description)") }
        self[Camera2Params.alignmentOffsetYaw].map { params.append("alignmentOffsetYaw: \($0.description)") }
        self[Camera2Params.autoExposureMeteringMode].map {
            params.append("autoExposureMeteringMode: \($0.description)")
        }
        self[Camera2Params.storagePolicy].map { params.append("storagePolicy: \($0.description)") }
        return "{ \(params.joined(separator: ", ")) }"
    }
}
