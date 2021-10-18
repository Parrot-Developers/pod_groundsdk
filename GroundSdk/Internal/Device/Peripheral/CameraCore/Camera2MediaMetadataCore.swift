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

/// Type of media metadata.
public enum Camera2MediaMetadataType {
    /// Media copyright.
    case copyright
    /// Application custom identifier.
    case customId
    /// Application custom title.
    case customTitle
}

/// Internal camera media metadata core implementation.
public class Camera2MediaMetadataCore: ComponentCore, Camera2MediaMetadata {

    /// Timeout object.
    ///
    /// Visibility is internal for testing purposes
    let timeout = SettingTimeout()

    /// Whether the tag has been changed and is waiting for change confirmation.
    public var updating: Bool { timeout.isScheduled }

    /// Closure to call to change the tag.
    private let backend: (_ mediaMetadata: [Camera2MediaMetadataType: String]) -> Bool

    /// Copyright that will be injected in produced media metadata.
    public var copyright: String {
        get {
            mediaMetadata[.copyright] ?? ""
        }
        set {
            mediaMetadata[.copyright] = newValue
        }
    }

    /// Application custom identifier that will be injected in produced media metadata.
    public var customId: String {
        get {
            mediaMetadata[.customId] ?? ""
        }
        set {
            mediaMetadata[.customId] = newValue
        }
    }

    /// Application custom title that will be injected in produced media metadata.
    public var customTitle: String {
        get {
            mediaMetadata[.customTitle] ?? ""
        }
        set {
            mediaMetadata[.customTitle] = newValue
        }
    }

    /// Media metadata that will be injected in produced media.
    private var mediaMetadata: [Camera2MediaMetadataType: String] {
        get {
            _mediaMetadata
        }
        set {
            if _mediaMetadata != newValue {
                if backend(newValue) {
                    let oldValue = _mediaMetadata
                    // value sent to the backend, update setting value and mark it updating
                    _mediaMetadata = newValue
                    timeout.schedule { [weak self] in
                        if let `self` = self, self.update(mediaMetadata: oldValue) {
                            self.userDidChangeSetting()
                        }
                    }
                    userDidChangeSetting()
                }
            }
        }
    }

    /// Media metadata that will be injected in produced media.
    private var _mediaMetadata: [Camera2MediaMetadataType: String] = [:]

    /// Constructor.
    ///
    /// - Parameters:
    ///   - store: store where this component will be stored
    ///   - backend: closure to call to change media metadata
    init(store: ComponentStoreCore,
         backend: @escaping (_ mediaMetadata: [Camera2MediaMetadataType: String]) -> Bool) {
        self.backend = backend
        super.init(desc: Camera2Components.mediaMetadata, store: store)
    }

    /// Changes media metadata.
    ///
    /// - Parameter mediaMetadata: new media metadata
    /// - Returns: true if the setting has been changed, false otherwise
    func update(mediaMetadata newMediaMetadata: [Camera2MediaMetadataType: String]) -> Bool {
        if updating || _mediaMetadata != newMediaMetadata {
            _mediaMetadata = newMediaMetadata
            timeout.cancel()
            return true
        }
        return false
    }
}

/// Backend callback methods.
extension Camera2MediaMetadataCore {
    /// Changes media metadata.
    ///
    /// - Parameter name: new media metadata
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func update(mediaMetadata newMediaMetadata: [Camera2MediaMetadataType: String]) -> Camera2MediaMetadataCore {
        if update(mediaMetadata: newMediaMetadata) {
            markChanged()
        }
        return self
    }

    /// Cancels any pending rollback.
    ///
    /// - Returns: self, to allow call chaining
    @discardableResult
    public func cancelRollback() -> Camera2MediaMetadataCore {
        if timeout.isScheduled {
            timeout.cancel()
            markChanged()
        }
        return self
    }
}
