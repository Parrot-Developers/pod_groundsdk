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

/// Product variant
public enum ProductVariant: Int, CustomStringConvertible {
    /// SkyController standard variant (with either MARS or Wifi radio).
    case standard

    /// SkyController mission variant (without radio).
    case mission

    /// SkyController Ranger variant (for remote antenna usage).
    case ranger

    public var description: String {
        switch self {
        case .standard: return "standard"
        case .mission:  return "mission"
        case .ranger:   return "ranger"
        }
    }
}

/// Remote control system information.
///
/// In this peripheral you can retrieve all information relative to the system of the device.
///
/// This peripheral can be retrieved by:
/// ```
/// device.getPeripheral(Peripherals.remoteControlSystemInfo)
/// ```
public protocol RemoteControlSystemInfo: SystemInfo {

    /// Product variant
    ///
    /// `nil` if not available.
    var productVariant: ProductVariant? { get }
}

/// :nodoc:
/// Remote control system info description
public class RemoteControlSystemInfoDesc: NSObject, PeripheralClassDesc {
    public typealias ApiProtocol = RemoteControlSystemInfo
    public let uid = PeripheralUid.remoteControlSystemInfo.rawValue
    public let parent: ComponentDescriptor? = Peripherals.systemInfo
}
