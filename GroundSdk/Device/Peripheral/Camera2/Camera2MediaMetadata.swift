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

/// Media metadata component.
///
/// Allows to specify various metadata that will be injected in all medias produced by the camera
/// (photo captures, video records).
public protocol Camera2MediaMetadata: Component {
    /// Whether metadata have been changed and are waiting for change confirmation.
    var updating: Bool { get }

    /// Copyright that will be injected in produced media metadata.
    var copyright: String { get set }

    /// Application custom identifier that will be injected in produced media metadata.
    var customId: String { get set }

    /// Application custom title that will be injected in produced media metadata.
    var customTitle: String { get set }
}

/// :nodoc:
/// Camera2MediaMetadata description.
public class Camera2MediaMetadataDesc: NSObject, Camera2ComponentClassDesc {
    public typealias ApiProtocol = Camera2MediaMetadata
    public let uid = Camera2ComponentUid.mediaMetadata.rawValue
    public let parent: ComponentDescriptor? = nil
}
