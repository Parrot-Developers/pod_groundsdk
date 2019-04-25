// Copyright (C) 2016-2018 Parrot Drones SAS
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

/// Delegate executing action on Device.
public protocol DeviceCoreDelegate: class {

    /// Removes the device from known devices list and clear all its stored data.
    ///
    /// - returns: true if the device has been forgotten.
    func forget() -> Bool

    /// Connects the device.
    ///
    /// - Parameters:
    ///    - connector: connector to use to establish the connection
    ///    - password: password to use for authentication, nil if password is not required
    /// - Returns: true if the connection process has started
    func connect(connector: DeviceConnector, password: String?) -> Bool

    /// Disconnects the device.
    ///
    /// This method can be used to disconnect the device when connected or to cancel the connection process if the
    /// device is currently connecting.
    ///
    /// - Returns: true if the disconnection process has started, false otherwise.
    func disconnect() -> Bool
}

/// Device Core implementation
public class DeviceCore: CustomStringConvertible, Equatable {
    /// Device unique identifier, persistant between sessions
    public let uid: String
    /// Model of this device
    public let deviceModel: DeviceModel
    /// Holder of the mutable device name, that notifies name changes
    public let nameHolder: NameHolderCore
    /// Holder of the mutable device state, that notifies state changes
    public let stateHolder: DeviceStateHolderCore
    /// Holder of the mutable device firmware version, that notifies firmware version changes
    public let firmwareVersionHolder: FirmwareVersionHolderCore
    /// Piloting interfaces store
    public let pilotingItfStore = ComponentStoreCore()
    /// Instruments store
    public let instrumentStore = ComponentStoreCore()
    /// Peripherals store
    public let peripheralStore = ComponentStoreCore()
    /// Delegate handling action on the device
    private unowned let delegate: DeviceCoreDelegate

    /// Description of the device.
    ///
    /// The description of the device is its uid.
    public var description: String {
        return "\(uid)"
    }

    /// Constructor
    ///
    /// - Parameters:
    ///   - uid: device uid
    ///   - model: model of this device
    ///   - name: device initial name
    ///   - delegate: device delegate
    public init(uid: String, model: DeviceModel, name: String, delegate: DeviceCoreDelegate) {
        self.uid = uid
        self.deviceModel = model
        self.delegate = delegate
        self.nameHolder = NameHolderCore(name: name)
        self.stateHolder = DeviceStateHolderCore()
        self.firmwareVersionHolder = FirmwareVersionHolderCore()
    }

    /// Get the device name and register an observer notified each time it changes
    ///
    /// - parameter observer: observer to notify when the device name changes
    /// - returns: reference to device name
    func getName(observer: @escaping Ref<String>.Observer) -> Ref<String> {
        return NameRefCore(nameHolder: nameHolder, observer: observer)
    }

    /// Get the device state and register an observer notified each time it changes
    ///
    /// - parameter observer: observer to notify when the device state changes
    /// - returns: reference to device state
    func getState(observer: @escaping Ref<DeviceState>.Observer) -> Ref<DeviceState> {
        return DeviceStateRefCore(stateHolder: stateHolder, observer: observer)
    }

    /// Gets an instrument
    ///
    /// Return the requested instrument or nil if the drone doesn't have the requested instrument, or if the instrument
    /// is not available in the current connection state.
    ///
    /// - parameter desc: requested instrument. See `Instruments` api for available descriptors instances
    /// - returns: requested instrument
    func getInstrument<Desc: InstrumentClassDesc>(_ desc: Desc) -> Desc.ApiProtocol? {
        return instrumentStore.get(desc)
    }

    /// Gets an instrument and register an observer notified each time it changes
    ///
    /// If the instrument is present, the observer will be called immediately with. If the instrument is not present,
    /// the observer won't be called until the instrument is added to the drone.
    /// If the instrument or the drone are removed, the observer will be notified and referenced value is set to nil
    ///
    /// - parameter desc: requested instrument. See `Instruments` api for available descriptors instances
    /// - parameter observer: observer to notify when the instrument changes
    /// - returns: reference to the requested instrument
    func getInstrument<Desc: InstrumentClassDesc>(
        _ desc: Desc, observer: @escaping Ref<Desc.ApiProtocol>.Observer) -> Ref<Desc.ApiProtocol> {
        return ComponentRefCore(store: instrumentStore, desc: desc, observer: observer)
    }

    /// Gets a piloting interface
    ///
    /// Return the requested piloting interface or nil if the drone doesn't have the requested piloting interface,
    /// or if the piloting interface is not available in the current connection state.
    ///
    /// - parameter desc: requested piloting interface. See `PilotingItfs` api for available descriptors instances
    /// - returns: requested piloting interface
    func getPilotingItf<Desc: PilotingItfClassDesc>(_ desc: Desc) -> Desc.ApiProtocol? {
        return pilotingItfStore.get(desc)
    }

    /// Gets a piloting interface and register an observer notified each time it changes
    ///
    /// If the piloting interface is present, the observer will be called immediately with. If the piloting interface is
    /// not present, the observer won't be called until the piloting interface is added to the drone.
    /// If the piloting interface or the drone are removed, the observer will be notified and referenced value is set to
    /// nil
    ///
    /// - parameter desc: requested piloting interface. See `PilotingItfs` api for available descriptors instances
    /// - parameter observer: observer to notify when the piloting interface changes
    /// - returns: reference to the requested piloting interface
    func getPilotingItf<Desc: PilotingItfClassDesc>(
        _ desc: Desc, observer: @escaping Ref<Desc.ApiProtocol>.Observer) -> Ref<Desc.ApiProtocol> {

        return ComponentRefCore(store: pilotingItfStore, desc: desc, observer: observer)
    }

    /// Gets a peripheral
    ///
    /// Return the requested peripheral or nil if the drone doesn't have the requested peripheral, or if the peripheral
    ///
    /// - parameter desc: requested peripheral. See `Peripherals` api for available descriptors instances
    /// - returns: requested peripheral
    func getPeripheral<Desc: PeripheralClassDesc>(_ desc: Desc) -> Desc.ApiProtocol? {
        return peripheralStore.get(desc)
    }

    /// Gets a peripheral and register an observer notified each time it changes
    ///
    /// If the peripheral is present, the observer will be called immediately with. If the peripheral is not present,
    /// the observer won't be called until the peripheral is added to the drone.
    /// If the peripheral or the drone are removed, the observer will be notified and referenced value is set to nil
    ///
    /// - parameter desc: requested peripheral. See `Peripherals` api for available descriptors instances
    /// - parameter observer: observer to notify when the peripheral changes
    /// - returns: reference to the requested peripheral
    func getPeripheral<Desc: PeripheralClassDesc>(
        _ desc: Desc, observer: @escaping Ref<Desc.ApiProtocol>.Observer) -> Ref<Desc.ApiProtocol> {
        return ComponentRefCore(store: peripheralStore, desc: desc, observer: observer)
    }

    /// Forgets the device.
    ///
    /// Persisted device data are deleted and the device is removed from the list of device if it's not visible.
    ///
    /// - returns: true if the device has been forgotten, false else.
    func forget() -> Bool {
        return delegate.forget()
    }

    /// Connects the device.
    ///
    /// - parameter connector: connector to use to connect the device
    /// - parameter password: password to use to connect the device
    /// - returns: true if the connection process has started, false else, for example if the device is no more visible.
    func connect(connector: DeviceConnector?, password: String?) -> Bool {
        var selectedConnector: DeviceConnector?
        if let connector = connector {
            // use given connector
            selectedConnector = connector
        } else {
            selectedConnector = stateHolder.state.bestConnector
        }
        if let selectedConnector = selectedConnector {
            return delegate.connect(connector: selectedConnector, password: password)
        } else {
            return false
        }
    }

    /// Disconnect the device.
    ///
    /// This method can be use to disconnect the device when connected or to cancel the connection process if the device
    /// is connecting.
    ///
    /// - returns: true if the disconnection process has started, false else.
    func disconnect() -> Bool {
        return delegate.disconnect()
    }

    /// Remove all components and clear all observers
    func clear() {
        nameHolder.clear()
        stateHolder.clear()
        instrumentStore.clear()
        pilotingItfStore.clear()
        peripheralStore.clear()
    }

    public static func == (lhs: DeviceCore, rhs: DeviceCore) -> Bool {
        return lhs.uid == rhs.uid
    }
}

/// Extension that add components getter from id, returning the basic type
/// This is used by Objective-C extension for components accessors
extension DeviceCore {

    /// Gets an instrument and register an observer notified each time it changes
    ///
    /// - parameter uid: requested instrument uid
    /// - returns: requested instrument
    func getInstrument(uid: Int) -> Instrument? {
        return instrumentStore.get(uid: uid)
    }

    /// Gets an instrument and register an observer notified each time it changes
    ///
    /// - parameter uid: requested instrument uid
    /// - parameter observer: observer to notify when the instrument changes
    /// - returns: reference to the requested instrument
    func getInstrument(uid: Int, observer: @escaping (Instrument?) -> Void) -> Ref<Instrument> {
        return ComponentUidRefCore<Instrument>(store: instrumentStore, uid: uid, observer: observer)
    }

    /// Gets a piloting interface
    ///
    /// Return the requested piloting interface or nil if the drone doesn't have the requested piloting interface,
    /// or if the piloting interface is not available in the current connection state.
    ///
    /// - parameter uid: requested piloting interface uid
    /// - returns: requested piloting interface
    func getPilotingItf(uid: Int) -> PilotingItf? {
        return pilotingItfStore.get(uid: uid)
    }

    /// Gets a piloting interface and register an observer notified each time it changes
    ///
    /// If the piloting interface is present, the observer will be called immediately with. If the piloting interface is
    /// not present, the observer won't be called until the piloting interface is added to the drone.
    /// If the piloting interface or the drone are removed, the observer will be notified and referenced value is set to
    /// nil
    ///
    /// - parameter uid: requested piloting interface uid
    /// - parameter observer: observer to notify when the piloting interface changes
    /// - returns: reference to the requested piloting interface
    func getPilotingItf(uid: Int, observer: @escaping (PilotingItf?) -> Void) -> Ref<PilotingItf> {
        return ComponentUidRefCore<PilotingItf>(store: pilotingItfStore, uid: uid, observer: observer)
    }

    /// Gets a peripheral
    ///
    /// Return the requested peripheral or nil if the drone doesn't have the requested peripheral, or if the peripheral
    ///
    /// - parameter uid: requested peripheral uid
    /// - returns: requested peripheral
    func getPeripheral(uid: Int) -> Peripheral? {
        return peripheralStore.get(uid: uid)
    }

    /// Gets a peripheral and register an observer notified each time it changes
    ///
    /// If the peripheral is present, the observer will be called immediately with. If the peripheral is not present,
    /// the observer won't be called until the peripheral is added to the drone.
    /// If the peripheral or the drone are removed, the observer will be notified and referenced value is set to nil
    ///
    /// - parameter uid: requested peripheral uid
    /// - parameter observer: observer to notify when the peripheral changes
    /// - returns: reference to the requested peripheral
    func getPeripheral(uid: Int, observer: @escaping (Peripheral?) -> Void) -> Ref<Peripheral> {
        return ComponentUidRefCore<Peripheral>(store: peripheralStore, uid: uid, observer: observer)
    }
}
