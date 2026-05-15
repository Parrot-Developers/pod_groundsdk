// Copyright (C) 2019 Parrot Drones SAS
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

/// Drone finder backend part.
public protocol DroneFinderBackend: AnyObject {
    /// Starts visible drones discovery.
    ///
    /// - Parameter useBackupRadio: whether to use backup radio or not
    func discoverDrones(useBackupRadio: Bool)

    /// Connects a remote drone.
    ///
    /// - Parameters:
    ///   - uid: uid of the drone to connect
    ///   - parameters: custom parameters to use to connect the drone
    ///   - wakeIdle: `true` to wake up the drone if it's in idle state
    /// - Returns: `true` if the connection process has started, `false` otherwise
    func connectDrone(uid: String, parameters: [DeviceConnectionParameter], wakeIdle: Bool) -> Bool

    /// Connects a known drone.
    ///
    /// - Parameter uid: uid of the drone to connect
    /// - Returns: `true` if the connection process has started, `false` otherwise
    func connectKnownDrone(uid: String) -> Bool

    /// Stops discovery.
    func stopDiscovery() -> Bool
}

/// Core class for `DiscoveredDrone`
public class DiscoveredDroneCore: DiscoveredDrone {

    /// Constructor
    ///
    /// - Parameters:
    ///    - uid: drone unique identifier
    ///    - model: drone model
    ///    - name: drone name
    ///    - known: whether the drone known
    ///    - rssi: rssi in dBm
    ///    - connectionSecurity: connection security
    ///    - wifiVisibility: drone visibility over wifi
    ///    - cellularOnLine: drone cellular network is online
    ///    - backupLinkVisibility: backup link visibility
    override public init(
        uid: String, model: Drone.Model, name: String, known: Bool, rssi: Int, connectionSecurity: ConnectionSecurity,
        wifiVisibility: Bool, cellularOnLine: Bool, backupLinkVisibility: DroneBackupLinkVisibility) {
        super.init(uid: uid, model: model, name: name, known: known, rssi: rssi, connectionSecurity: connectionSecurity,
                   wifiVisibility: wifiVisibility, cellularOnLine: cellularOnLine,
                   backupLinkVisibility: backupLinkVisibility)
    }
}

/// Core class for `KnownDrone`
public class KnownDroneCore: KnownDrone {

    /// Constructor
    /// - Parameters:
    ///   - uid: drone unique identifier
    ///   - model: drone model
    ///   - name: drone name
    ///   - connectionTypes: known connection types of the drone
    override public init(uid: String, model: Drone.Model, name: String, connectionTypes: Set<DroneConnectionType>) {
        super.init(uid: uid, model: model, name: name, connectionTypes: connectionTypes)
    }
}

/// Internal drone finder implementation
public class DroneFinderCore: PeripheralCore, DroneFinder {

    /// Implementation backend
    private unowned let backend: DroneFinderBackend

    private(set) public var state: DroneFinderState = .idle

    private(set) public var discoveredDrones = [DiscoveredDrone]()

    private(set) public var knownDrones = [KnownDrone]()

    private(set) public var discoveryStatus: DiscoveryStatus?

    private(set) public var connectionTypes = Set<DroneConnectionType>()

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: DroneFinder backend
    public init(store: ComponentStoreCore, backend: DroneFinderBackend) {
        self.backend = backend
        super.init(desc: Peripherals.droneFinder, store: store)
    }

    /// Clears the current list of discovered drones.
    ///
    /// After calling this method, discoveredDrones is an empty list
    public func clear() {
        discoveredDrones.removeAll()
        // notify the changes
        markChanged()
        notifyUpdated()
    }

    /// Asks for an update of the list of discovered drones.
    public func refresh() {
        backend.discoverDrones(useBackupRadio: false)
    }

    /// Asks for an update of the list of discovered drones.
    ///
    /// - Parameter useBackupRadio: whether to use backup radio or not
    public func refresh(useBackupRadio: Bool) {
        backend.discoverDrones(useBackupRadio: useBackupRadio)
    }

    /// Stops discovery
    ///
    /// - Note: Only necessary if refresh was started with useBackupRadio at `true`
    public func stopDiscovery() -> Bool {
        return backend.stopDiscovery()
    }

    /// Connect a discovered drone
    ///
    /// - Parameters:
    ///    - discoveredDrone: discovered drone to connect
    /// - Returns: true if the connection process has started
    public func connect(discoveredDrone: DiscoveredDrone) -> Bool {
        return backend.connectDrone(uid: discoveredDrone.uid, parameters: [],
                                    wakeIdle: discoveredDrone.backupLinkVisibility == .visibleAndIdle)
    }

    /// Connect a known drone
    ///
    /// - Parameters:
    ///    - knownDrone: known drone to connect
    /// - Returns: true if the connection process has started
    public func connect(knownDrone: KnownDrone) -> Bool {
        return backend.connectKnownDrone(uid: knownDrone.uid)
    }

    /// Connect a discovered drone with a password
    ///
    /// - Parameters:
    ///    - discoveredDrone: discovered drone to connect
    ///    - password: password to use for connection
    /// - Returns: true if the connection process has started
    public func connect(discoveredDrone: DiscoveredDrone, password: String) -> Bool {
        return backend.connectDrone(uid: discoveredDrone.uid, parameters: [.securityKey(key: password)],
                                    wakeIdle: discoveredDrone.backupLinkVisibility == .visibleAndIdle)
    }
}

/// Backend callback methods
extension DroneFinderCore {
    /// Changes current state.
    ///
    /// - Parameter state: new state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(state newValue: DroneFinderState) -> DroneFinderCore {
        if state != newValue {
            state = newValue
            markChanged()
        }
        return self
    }

    /// Changes current discovered drone list.
    ///
    /// - Parameter discoveredDrones: new discovered drone list
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(discoveredDrones newValue: [DiscoveredDrone]) -> DroneFinderCore {
        discoveredDrones = newValue
        markChanged()
        return self
    }

    /// Changes current known drone list.
    ///
    /// - Parameter knownDrones: new known drone list
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(knownDrones newValue: [KnownDrone]) -> DroneFinderCore {
        knownDrones = newValue
        markChanged()
        return self
    }

    /// Changes current state.
    ///
    /// - Parameter discoveryStatus: new discovery status
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(discoveryStatus newValue: DiscoveryStatus?) -> DroneFinderCore {
        if discoveryStatus != newValue {
            discoveryStatus = newValue
            markChanged()
        }
        return self
    }

    /// Changes connection types.
    ///
    /// - Parameter connectionTypes: new connection types
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(connectionTypes newValue: Set<DroneConnectionType>) -> DroneFinderCore {
        if connectionTypes != newValue {
            connectionTypes = newValue
            markChanged()
        }
        return self
    }
}
