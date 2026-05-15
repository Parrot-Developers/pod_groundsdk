// Copyright (C) 2023 Parrot Drones SAS
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

/// Drone location information
public struct LocationInfo: Equatable {
    /// Latitude in degrees
    var latitude: Double
    /// Longitude, in degrees
    var longitude: Double
    /// Altitude in meters; `nil` if unavailable
    var altitude: Double?
    /// Heading, in degrees relative to the north; `nil` if unavailable
    var heading: Double?
    /// Horizontal accuracy, in meters; `nil` if unavailable
    var horizontalAccuracy: Double?
    /// Vertical accuracy, in meters; `nil` if unavailable
    var verticalAccuracy: Double?
    /// Heading accuracy, in degrees; `nil` if unavailable
    var headingAccuracy: Double?
    /// Time when the information was sampled, in milliseconds; reference is the user device's wall clock
    var timestamp: Date

    public init(latitude: Double, longitude: Double, altitude: Double? = nil, heading: Double? = nil,
                horizontalAccuracy: Double? = nil, verticalAccuracy: Double? = nil,
                headingAccuracy: Double? = nil, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.heading = heading
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.headingAccuracy = headingAccuracy
        self.timestamp = timestamp
    }
}

/// Identifies a type of navigation frame.
public enum NavigationControlFrame: Int, CustomStringConvertible {
    /// A local navigation frame.
    case local
    /// A global navigation frame.
    case global

    public var description: String {
        switch self {
        case .local: return "local"
        case .global: return "global"
        }
    }
}

/// The navigation control state.
public struct NavigationControlState: Equatable {

    /// The available frames.
    public let availableFrames: [NavigationControlFrame]

    /// Constructor.
    ///
    /// - Parameter availableFrames: The list of available navigation frames.
    public init(availableFrames: [NavigationControlFrame]) {
        self.availableFrames = availableFrames
    }
}

/// NavigationControl backend part.
public protocol NavigationControlBackend: AnyObject {

    /// Selects the location sources
    ///
    /// - Parameter sources: location sources to select
    /// - Returns: `true` if the request has been sent to the drone, otherwise `false`
    func selectSources(sources: Set<Source>) -> Bool

    /// Set the drone position in GPS coordinates corresponding to the 2D origin of its global
    /// coordinate system and its heading.
    ///
    /// The drone will set the given coordinate as its origin for any operation performed in global
    /// coordinate system.
    ///
    /// - Parameters:
    ///   - latitude: origin latitude in decimal degrees
    ///   - longitude: origin longitude in decimal degrees
    ///   - heading: origin heading in radians
    /// - Returns: `true` if the request has been sent to the drone, otherwise `false`
    func sendGlobalPose(latitude: Double, longitude: Double, heading: Float) -> Bool
}

/// Internal NavigationControl peripheral implementation.
public class NavigationControlCore: PeripheralCore, NavigationControl {

    public private(set) var gnssInfo: GnssInfo?

    public var currentLocation: CLLocation? {
        return hasCurrentLocation ? lastKnownLocation : nil
    }

    public var lastKnownLocation: CLLocation? {
        guard let location = location else { return nil }

        let coord = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        return CLLocation(coordinate: coord, altitude: location.altitude ?? 0,
                          horizontalAccuracy: location.horizontalAccuracy ?? 0,
                          verticalAccuracy: location.altitude == nil ? -1 : (location.verticalAccuracy ?? 0),
                          course: location.heading ?? -1,
                          courseAccuracy: location.headingAccuracy ?? 0,
                          speed: -1,
                          speedAccuracy: -1,
                          timestamp: location.timestamp)
    }

    public private(set) var reliability: Reliability?

    public private(set) var usesMagnetometer: Bool?

    public private(set) var gnssSource: GnssSource?

    public var sources: EnumSetSetting<Source> {
        return _sources
    }

    /// Tells whether drone has a current location.
    private var hasCurrentLocation = false

    /// Current location information.
    /// Used by backend to update such information.
    private var location: LocationInfo?

    /// Core implementation of the sources setting.
    private var _sources: EnumSetSettingCore<Source>!

    /// Current navigation control state.
    public private(set) var state: NavigationControlState

    /// Implementation backend.
    private unowned let backend: NavigationControlBackend

    /// Constructor.
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: navigation backend
    public init(store: ComponentStoreCore, backend: NavigationControlBackend) {
        self.backend = backend
        self.state = NavigationControlState(availableFrames: [])
        super.init(desc: Peripherals.navigationControl, store: store)
        _sources = EnumSetSettingCore(defaultValues: [], didChangeDelegate: self) {[unowned self] sources in
            return self.backend.selectSources(sources: sources)
        }
    }

    public func sendGlobalPose(latitude: Double, longitude: Double, heading: Float) -> Bool {
        backend.sendGlobalPose(latitude: latitude, longitude: longitude, heading: heading)
    }
}

extension NavigationControlCore {
    /// Updates state.
    ///
    /// - Parameter state: new state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(state newState: NavigationControlState) -> NavigationControlCore {
        if self.state != newState {
            self.state = newState
            markChanged()
        }
        return self
    }

    /// Updates gnss info
    ///
    /// - Parameter gnssInfo: new gnss info
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(gnssInfo newGnssInfo: GnssInfo?) -> NavigationControlCore {
        if self.gnssInfo != newGnssInfo {
            self.gnssInfo = newGnssInfo
            markChanged()
        }
        return self
    }

    /// Updates hasCurrentLocation
    ///
    /// - Parameter hasCurrentLocation: new hasCurrentLocation
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(hasCurrentLocation newHasCurrentLocation: Bool) -> NavigationControlCore {
        if self.hasCurrentLocation != newHasCurrentLocation {
            self.hasCurrentLocation = newHasCurrentLocation
            markChanged()
        }
        return self
    }

    /// Updates location
    ///
    /// - Parameter location: new location
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(location newLocation: LocationInfo) -> NavigationControlCore {
        if self.location != newLocation {
            self.location = newLocation
            markChanged()
        }
        return self
    }

    /// Updates reliability
    ///
    /// - Parameter reliability: new reliability
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(reliability newReliability: Reliability?) -> NavigationControlCore {
        if self.reliability != newReliability {
            self.reliability = newReliability
            markChanged()
        }
        return self
    }

    /// Updates usesMagnetometer
    ///
    /// - Parameter usesMagnetometer: new usesMagnetometer
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(usesMagnetometer newUsesMagnetometer: Bool?) -> NavigationControlCore {
        if self.usesMagnetometer != newUsesMagnetometer {
            self.usesMagnetometer = newUsesMagnetometer
            markChanged()
        }
        return self
    }

    /// Updates sources
    ///
    /// - Parameter sources: new sources
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(sources newSources: Set<Source>) -> NavigationControlCore {
        if _sources.update(values: newSources) {
            markChanged()
        }
        return self
    }

    /// Updates supported sources
    ///
    /// - Parameter supportedSources: new supported sources
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(supportedSources newSupportedSources: Set<Source>) -> NavigationControlCore {
        if _sources.update(supportedValues: newSupportedSources) {
            markChanged()
        }
        return self
    }

    /// Updates GNSS source
    ///
    /// - Parameter gnssSource: the new GNSS source
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult
    public func update(gnssSource newGnssSource: GnssSource?) -> NavigationControlCore {
        if gnssSource != newGnssSource {
            gnssSource = newGnssSource
            markChanged()
        }
        return self
    }
}
