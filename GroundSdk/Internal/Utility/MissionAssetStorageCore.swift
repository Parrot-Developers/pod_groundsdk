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

/// Utility protocol allowing to access mission asset internal storage.
///
/// This mainly allows to query the location where Mission asset files should be stored and
/// to notify the engine when new mission assets have been downloaded.
public protocol MissionAssetStorageCore: UtilityCore {
    /// Directory where new mission assets may be downloaded.
    ///
    /// Multiple downloaders may be assigned the same download directory. As a consequence, mission assets
    /// are identified in subdirectories by mission uid.
    ///
    /// The directory in question might not exist, and the caller has the responsibility to create it if necessary,
    /// but should ensure to do so on a background thread.
    var workDir: URL { get }

    /// Start monitoring the mission asset storage.
    ///
    /// - Note: To avoid memory leaks, the returned monitor should be kept. When not needed anymore, the `stop()`
    /// function should be called on this monitor before releasing it.
    ///
    /// - Parameter storeDidChange: closure called when the store changes.
    /// - Returns: returns a monitor. This monitor should be kept until calling `stop()` on it.
    func startMonitoring(storeDidChange: @escaping () -> Void) -> MonitorCore

    /// Notifies all monitors that the store has changed.
    func notifyStoreChanged()
}

/// Implementation of the `MissionAssetStorageCore` utility.
class MissionAssetStorageCoreImpl: MissionAssetStorageCore {
    /// Monitor that calls back closures when the store changes
    fileprivate class Monitor: NSObject, MonitorCore {
        /// Closure called when the store changes.
        fileprivate let storeDidChange: () -> Void

        /// Monitored store.
        private let store: MissionAssetStorageCoreImpl

        /// Constructor
        ///
        /// - Parameters:
        ///   - store: the monitored store
        ///   - storeDidChange: closure called when the store changes.
        fileprivate init(store: MissionAssetStorageCoreImpl, storeDidChange: @escaping () -> Void) {
            self.store = store
            self.storeDidChange = storeDidChange
        }

        public func stop() {
            store.stopMonitoring(with: self)
        }
    }

    let desc: UtilityCoreDescriptor = Utilities.missionAssetStorage

    var workDir: URL

    /// List of monitors
    private var monitors: Set<Monitor> = []

    /// Constructor
    public init() {
        let fileManager = FileManager.default
        let documentPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        workDir = documentPath.appendingPathComponent("missions")
    }

    func startMonitoring(storeDidChange: @escaping () -> Void) -> MonitorCore {
        let monitor = Monitor(store: self, storeDidChange: storeDidChange)
        monitors.insert(monitor)
        monitor.storeDidChange()
        return monitor
    }

    func notifyStoreChanged() {
        monitors.forEach { monitor in
            monitor.storeDidChange()
        }
    }

    /// Stops monitoring with a given monitor.
    ///
    /// - Parameter monitor: the monitor
    private func stopMonitoring(with monitor: Monitor) {
        monitors.remove(monitor)
    }
}

/// Mission asset storage utility description
public class MissionAssetStorageCoreDesc: NSObject, UtilityCoreApiDescriptor {
    public typealias ApiProtocol = MissionAssetStorageCore
    public let uid = UtilityUid.missionAssetStorage.rawValue
}
