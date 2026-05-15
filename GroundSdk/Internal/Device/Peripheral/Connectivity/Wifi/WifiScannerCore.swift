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
//    "AS IS" AND A(NY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
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

/// Wifi scanner backend.
public protocol WifiScannerBackend: AnyObject {

    /// Starts scanning visible wifi networks.
    func startScan()

    /// Stops ongoing scanning, if any.
    func stopScan()
}

/// Internal implementation of the wifi scanner.
public class WifiScannerCore: PeripheralCore, WifiScanner {

    public private(set) var scanning = false

    public private(set) var scanResults: [ScanResult] = []

    /// Implementation backend.
    private unowned let backend: WifiScannerBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored
    ///   - backend: wifi scanner backend
    public init(store: ComponentStoreCore, backend: WifiScannerBackend) {
        self.backend = backend
        super.init(desc: Peripherals.wifiScanner, store: store)
    }

    override func reset() {
        scanning = false
        scanResults.removeAll()
    }

    public func startScan() {
        if !scanning {
            backend.startScan()
        }
    }

    public func stopScan() {
        if scanning {
            backend.stopScan()
        }
    }

    public func getOccupationRate(forChannel channel: WifiChannel) -> Int {
        return scanResults.filter({ $0.channel == channel }).count
    }
}

/// Backend callback methods
extension WifiScannerCore {

    /// Updates scanning value.
    ///
    /// - Parameter newValue: new scanning value
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(scanning newValue: Bool) -> WifiScannerCore {
        if scanning != newValue {
            scanning = newValue
            markChanged()
        }
        return self
    }

    /// Updates scan results.
    ///
    /// - Parameter newValue: new scan results
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(scanResults newValue: [ScanResult]) -> WifiScannerCore {
        if scanResults != newValue {
            scanResults = newValue
            markChanged()
        }
        return self
    }
}
