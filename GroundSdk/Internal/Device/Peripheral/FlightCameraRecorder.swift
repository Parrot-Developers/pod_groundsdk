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

/// Setting to change the flight camera recording pipelines configuration.
public protocol FlightCameraRecorderPipelinesSetting: AnyObject {
    /// Tells if setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Flight camera recorder pipelines configuration identifier.
    var id: UInt64 { get set }
}

/// Flight camera recorder peripheral interface for anafi2 drones.
///
/// This peripheral allows to configure flight camera recorder behavior, such as:
/// Active recording pipelines
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.flightCameraRecorder)
/// ```
public protocol FlightCameraRecorder: Peripheral {
    /// Gives access to the flight camera recording pipelines configuration setting.
    /// This setting allows to select current flight camera recording pipelines configuration.
    /// - Note: This setting remains available when the drone is not connected.
    var pipelines: FlightCameraRecorderPipelinesSetting { get }
}

/// :nodoc:
/// Flight camera recorder description
public class FlightCameraRecorderDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = FlightCameraRecorder
    public let uid = PeripheralUid.flightCameraRecorder.rawValue
    public let parent: ComponentDescriptor? = nil
}
