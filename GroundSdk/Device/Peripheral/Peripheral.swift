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

/// Base protocol for all Peripheral components.
@objc(GSPeripheral)
public protocol Peripheral: Component {
}

/// Peripheral component descriptor.
public protocol PeripheralClassDesc: ComponentApiDescriptor {
    /// Protocol of the peripheral.
    associatedtype ApiProtocol = Peripheral
}

/// Defines all known Peripheral descriptors.
@objcMembers
@objc(GSPeripherals)
public class Peripherals: NSObject {
    /// Anti-flicker.
    public static let antiflicker = AntiflickerDesc()
    /// Battery gauge updater.
    public static let batteryGaugeUpdater = BatteryGaugeUpdaterDesc()
    /// Beeper.
    public static let beeper = BeeperDesc()
    /// Blended thermal camera peripheral.
    public static let blendedThermalCamera = BlendedThermalCameraDesc()
    /// Blended thermal camera2 peripheral.
    public static let blendedThermalCamera2 = BlendedThermalCamera2Desc()
    /// Cellular.
    public static let cellular = CellularDesc()
    /// Certificate Uploader.
    public static let certificateUploader = CertificateUploaderDesc()
    /// Copilot.
    public static let copilot = CopilotDesc()
    /// Copter motors peripheral.
    public static let copterMotors = CopterMotorsDesc()
    /// Crash report downloader peripheral.
    public static let crashReportDownloader = CrashReportDownloaderDesc()
    /// Debug shell peripheral.
    public static let debugShell = DebugShellDesc()
    /// Development toolbox.
    public static let devToolbox = DevToolboxDesc()
    /// Dri.
    public static let dri = DriDesc()
    /// Drone finder peripheral.
    public static let droneFinder = DroneFinderDesc()
    /// Flight camera record downloader.
    public static let flightCameraRecordDownloader = FlightCameraRecordDownloaderDesc()
    /// Flight camera recorder.
    public static let flightCameraRecorder = FlightCameraRecorderDesc()
    /// Flight data (PUD) downloader.
    public static let flightDataDownloader = FlightDataDownloaderDesc()
    /// Flight log (FDR-lite) downloader.
    public static let flightLogDownloader = FlightLogDownloaderDesc()
    /// Front stereo gimbal.
    public static let frontStereoGimbal = FrontStereoGimbalDesc()
    /// Geofence.
    public static let geofence = GeofenceDesc()
    /// Gimbal.
    public static let gimbal = GimbalDesc()
    /// HTTP server.
    public static let httpServer = HttpServerDesc()
    /// Internal user storage.
    public static let internalUserStorage = InternalUserStorageDesc()
    /// Kill switch.
    public static let killSwitch = KillSwitchDesc()
    /// Leds.
    public static let leds = LedsDesc()
    /// Log control.
    public static let logControl = LogControlDesc()
    /// Magnetometer peripheral.
    public static let magnetometer = MagnetometerDesc()
    /// 1-step calibration magnetometer peripheral.
    public static let magnetometerWith1StepCalibration = MagnetometerWith1StepCalibrationDesc()
    /// 3-steps calibration magnetometer peripheral.
    public static let magnetometerWith3StepCalibration = MagnetometerWith3StepCalibrationDesc()
    /// Main camera peripheral.
    public static let mainCamera = MainCameraDesc()
    /// Main camera 2 peripheral.
    public static let mainCamera2 = MainCamera2Desc()
    /// Media store peripheral.
    public static let mediaStore = MediaStoreDesc()
    /// Messenger peripheral.
    public static let messenger = MessengerDesc()
    /// Microhard.
    public static let microhard = MicrohardDesc()
    /// Missions.
    public static let missionManager = MissionManagerDesc()
    /// Mission Store.
    public static let missionsUpdater = MissionUpdaterDesc()
    /// Network control.
    public static let networkControl = NetworkControlDesc()
    /// Obstacle avoidance.
    public static let obstacleAvoidance = ObstacleAvoidanceDesc()
    /// Onboard tracker.
    public static let onboardTracker = OnboardTrackerDesc()
    /// Piloting control.
    public static let pilotingControl = PilotingControlDesc()
    /// Precise home.
    public static let preciseHome = PreciseHomeDesc()
    /// Radio control.
    public static let radioControl = RadioControlDesc()
    /// Removable user storage.
    public static let removableUserStorage = RemovableUserStorageDesc()
    /// SecureElement.
    public static let secureElement = SecureElementDesc()
    /// SkyController3 gamepad peripheral.
    public static let skyCtrl3Gamepad = SkyCtrl3GamepadDesc()
    /// SkyController4 gamepad peripheral.
    public static let skyCtrl4Gamepad = SkyCtrl4GamepadDesc()
    /// Sleep mode peripheral.
    public static let sleepMode = SleepModeDesc()
    /// Stereo vision sensor.
    public static let stereoVisionSensor = StereoVisionSensorDesc()
    /// Video stream peripheral.
    public static let streamServer = StreamServerDesc()
    /// System info peripheral.
    public static let systemInfo = SystemInfoDesc()
    /// Target Tracker.
    public static let targetTracker = TargetTrackerDesc()
    /// Thermal camera peripheral.
    public static let thermalCamera = ThermalCameraDesc()
    /// Thermal control.
    public static let thermalControl = ThermalControlDesc()
    /// Firmware updater peripheral.
    public static let updater = UpdaterDesc()
    /// Virtual gamepad peripheral.
    public static let virtualGamepad = VirtualGamepadDesc()
    /// Wifi access point peripheral.
    public static let wifiAccessPoint = WifiAccessPointDesc()
    /// Wifi scanner peripheral.
    public static let wifiScanner = WifiScannerDesc()
    /// Wifi station peripheral.
    public static let wifiStation = WifiStationDesc()

    // Peripherals reserved for internal use.
    /// Latest flight log (FDR) downloader.
    internal static let latestLogDownloader = LatestLogDownloaderDesc()
    /// Terrain control peripheral.
    public static let terrainControl = TerrainControlDesc()
}

/// Peripheral uid.
enum PeripheralUid: Int {
    case antiflicker
    case batteryGaugeUpdater
    case beeper
    case blendedThermalCamera
    case blendedThermalCamera2
    case cellular
    case certificateUploader
    case copilot
    case copterMotors
    case crashReportDownloader
    case debugShell
    case devToolbox
    case dri
    case droneFinder
    case flightCameraRecordDownloader
    case flightCameraRecorder
    case flightDataDownloader
    case flightLogDownloader
    case frontStereoGimbal
    case geofence
    case gimbal
    case httpServer
    case internalUserStorage
    case killSwitch
    case latestLogDownloader
    case leds
    case logControl
    case magnetometer
    case magnetometerWith1StepCalibration
    case magnetometerWith3StepCalibration
    case mainCamera
    case mainCamera2
    case mediaStore
    case messenger
    case microhard
    case missionManager
    case missionUpdater
    case networkControl
    case obstacleAvoidance
    case onboardTracker
    case pilotingControl
    case preciseHome
    case radioControl
    case removableUserStorage
    case secureElement
    case skyCtrl3Gamepad
    case skyCtrl4Gamepad
    case sleepMode
    case stereoVisionSensor
    case streamServer
    case systemInfo
    case targetTracker
    case terrainControl
    case thermalCamera
    case thermalControl
    case updater
    case virtualGamepad
    case wifiAccessPoint
    case wifiScanner
    case wifiStation
}

/// Objective-C wrapper of Ref<Peripheral>. Required because swift generics can't be used from Objective-C.
/// - Note: This class is for Objective-C only and must not be used in Swift.
@objcMembers
public class GSPeripheralRef: NSObject {

    private let ref: Ref<Peripheral>

    /// Referenced peripheral.
    public var value: Peripheral? {
        return ref.value
    }

    /// Constructor.
    ///
    /// - Parameter ref: referenced peripheral
    init(ref: Ref<Peripheral>) {
        self.ref = ref
    }
}
