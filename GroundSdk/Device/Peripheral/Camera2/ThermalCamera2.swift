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
//

import Foundation

/// Blended Thermal Camera2 peripheral.
///
/// Provides access to the thermal camera2 in order to take pictures and to record videos.
/// Also provides access to various camera2 settings, such as:
/// - Exposure,
/// - EV compensation,
/// - White balance,
/// - Recording mode, resolution and framerate selection,
/// - Photo mode, format and file format selection.
///
/// This peripheral can be retrieved by:
/// ```
/// drone.getPeripheral(Peripherals.thermalCamera2)
/// ```
public protocol BlendedThermalCamera2: Camera2, Peripheral {
}

/// :nodoc:
/// Blended thermal camera 2 description.
public class BlendedThermalCamera2Desc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = BlendedThermalCamera2
    public let uid = PeripheralUid.blendedThermalCamera2.rawValue
    public let parent: ComponentDescriptor? = nil
}
