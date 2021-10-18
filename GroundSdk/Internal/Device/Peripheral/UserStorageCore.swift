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

/// User storage backend.
public protocol UserStorageBackend: AnyObject {
    /// Request a format of the media.
    ///
    /// - Parameters:
    ///     - formattingType: type of formatting
    ///     - newMediaName: the new name that should be given to the media.
    /// - Returns: true if the format has been asked, false otherwise.
    func format(formattingType: FormattingType, newMediaName: String?) -> Bool

    /// Request a format with encryption of the media.
    ///
    /// - Parameters:
    ///     - password: password used for encryption
    ///     - formattingType: type of formatting
    ///     - newMediaName: the new name that should be given to the media. If you pass an empty string, the
    ///                           a default name will be assigned.
    /// - Returns: `true` if the format has been asked, `false` otherwise
    func formatWithEncryption(password: String, formattingType: FormattingType, newMediaName: String?) -> Bool

    /// Sends the password to the drone to access an encypted sd card.
    ///
    /// - Parameters:
    ///     - password: password used to access encrypted card
    ///     - usage: password usage
    /// - Returns: `true` if the password has been sent, `false` otherwise
    func sendPassword(password: String, usage: PasswordUsage) -> Bool
}

/// User storage peripheral implementation
public class UserStorageCore: PeripheralCore, UserStorage {

    /// Information about the current media.
    ///
    /// `nil` if current media is not available.

    /// Internal implementation of the Media Info
    class MediaInfo: UserStorageMediaInfo {
        fileprivate(set) var name: String

        fileprivate(set) var capacity: Int64

        /// Constructor
        ///
        /// - Parameters:
        ///   - name: the name of the media
        ///   - capacity: the capacity of the media
        init(name: String, capacity: Int64) {
            self.name = name
            self.capacity = capacity
        }
    }

    public var mediaInfo: UserStorageMediaInfo? {
        return _mediaInfo
    }
    /// private backend value of `mediaInfo`
    private var _mediaInfo: MediaInfo?

    public var physicalState = UserStoragePhysicalState.noMedia

    public var fileSystemState = UserStorageFileSystemState.error

    public var availableSpace: Int64 = -1

    private(set) public var canFormat = false

    private(set) public var isEncryptionSupported = false

    private(set) public var isEncrypted = false

    /// uuid of the sdcard
    private(set) public var uuid: String?

    private(set) public var supportedFormattingTypes: Set<FormattingType> = [.full]

    public var formattingState: FormattingState?

    public var hasCheckError: Bool?

    /// Implementation backend
    private unowned let backend: UserStorageBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - desc: component descriptor
    ///    - store: store where this peripheral will be stored
    ///    - backend: System info backend
    public init(_ desc: ComponentDescriptor, store: ComponentStoreCore, backend: UserStorageBackend) {
        self.backend = backend
        super.init(desc: desc, store: store)
    }

    public func format(formattingType: FormattingType, newMediaName: String) -> Bool {
        if canFormat {
            return backend.format(formattingType: formattingType, newMediaName: newMediaName)
        }
        return false
    }

    public func format(formattingType: FormattingType) -> Bool {
        if canFormat {
            return backend.format(formattingType: formattingType, newMediaName: nil)
        }
        return false
    }

    public func formatWithEncryption(password: String, formattingType: FormattingType) -> Bool {
        if canFormat && isEncryptionSupported {
            return backend.formatWithEncryption(password: password, formattingType: formattingType, newMediaName: nil)
        }
        return false
    }

    public func formatWithEncryption(password: String, formattingType: FormattingType, newMediaName: String) -> Bool {
        if canFormat && isEncryptionSupported {
            return backend.formatWithEncryption(password: password, formattingType: formattingType,
                                                newMediaName: newMediaName)
        }
        return false
    }

    public func sendPassword(password: String, usage: PasswordUsage) -> Bool {
        if isEncryptionSupported {
            return backend.sendPassword(password: password, usage: usage)
        }
        return false
    }
}

/// Objc support
extension UserStorageCore: GSUserStorage {
    public func isFormattingTypeSupported(_ formattingType: FormattingType) -> Bool {
         return supportedFormattingTypes.contains(formattingType)
    }

    public var isCheckingErrorSupported: Bool {
        return hasCheckError != nil ? true : false
    }

    public var gsHasCheckError: Bool {
        return hasCheckError != nil ? hasCheckError! : false
    }
}

/// Backend callback methods
extension UserStorageCore {
    /// Updates the available space on the media
    ///
    /// - Parameter availableSpace: the new available space
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(availableSpace newSpace: Int64) -> UserStorageCore {
        if availableSpace != newSpace {
            availableSpace = newSpace
            markChanged()
        }
        return self
    }

    /// Updates current ability to format the media.
    ///
    /// - Parameter canFormat: `true` if the media can be formatted
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(canFormat: Bool) -> UserStorageCore {
        if canFormat != self.canFormat {
            self.canFormat = canFormat
            markChanged()
        }
        return self
    }

    /// Updates supported formatting types
    ///
    /// - Parameter supportedFormattingTypes: formatting types
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedFormattingTypes: Set<FormattingType>) -> UserStorageCore {
        if supportedFormattingTypes != self.supportedFormattingTypes {
            self.supportedFormattingTypes = supportedFormattingTypes
            markChanged()
        }
        return self
    }

    /// Updates supported formatting step
    ///
    /// - Parameters:
    ///   - formattingStep: formatting step
    ///   - formattingProgress : formatting progress
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(formattingStep: FormattingStep, formattingProgress: Int)
        -> UserStorageCore {
            if let formattingState = self.formattingState {
                if formattingStep != formattingState.step || formattingProgress != formattingState.progress {
                    formattingState.step = formattingStep
                    formattingState.progress = formattingProgress
                    markChanged()
                }
            } else {
                self.formattingState = FormattingState()
                self.formattingState?.step = formattingStep
                self.formattingState?.progress = formattingProgress
                markChanged()
            }
        return self
    }

    /// Updates the user storage physical state
    ///
    /// - Parameter physicalState: the new physical state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(physicalState newPhysicalState: UserStoragePhysicalState) -> UserStorageCore {
        if physicalState != newPhysicalState {
            physicalState = newPhysicalState
            if physicalState == .noMedia {
                _mediaInfo = nil
                availableSpace = -1
            }
            markChanged()
        }
        return self
    }

    /// Updates the user storage file system state
    ///
    /// - Parameter fileSystemState: the new file system state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(fileSystemState newFileSystemState: UserStorageFileSystemState)
        -> UserStorageCore {
        if fileSystemState != newFileSystemState {
            fileSystemState = newFileSystemState
            if fileSystemState != .formatting {
                formattingState = nil
            }
            markChanged()
        }
        return self
    }

    /// Updates the media information
    ///
    /// - Parameters:
    ///   - name: the new name
    ///   - capacity: the new capacity, in bytes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(name: String, capacity: Int64) -> UserStorageCore {
        if let mediaInfo = _mediaInfo {
            if mediaInfo.name != name || mediaInfo.capacity != capacity {
                mediaInfo.name = name
                mediaInfo.capacity = capacity
                markChanged()
            }
        } else {
            _mediaInfo = MediaInfo(name: name, capacity: capacity)
            markChanged()
        }
        return self
    }

    /// Updates current ability to encrypt the media.
    ///
    /// - Parameter isEncryptionSupported: `true` if the media can be formatted
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(isEncryptionSupported: Bool) -> UserStorageCore {
        if isEncryptionSupported != self.isEncryptionSupported {
            self.isEncryptionSupported = isEncryptionSupported
            markChanged()
        }
        return self
    }

    /// Updates the sdcard uuid
    ///
    /// - Parameter uuid : the uuid of the sdcard
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(uuid newValue: String) -> UserStorageCore {
        if let uuid = uuid {
            if uuid != newValue {
                self.uuid = newValue
                markChanged()
            }
        } else {
            uuid = newValue
            markChanged()
        }
        return self
    }

    /// Updates current info indicating if card is encrypted.
    ///
    /// - Parameter isEncrypted: `true` if the media is encrypted
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(isEncrypted: Bool) -> UserStorageCore {
        if isEncrypted != self.isEncrypted {
            self.isEncrypted = isEncrypted
            markChanged()
        }
        return self
    }

    /// Updates current info indicating if the media failed being checked without error
    ///
    /// - Parameter hasCheckError: `true` if the media failed being checked without error
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(hasCheckError: Bool) -> UserStorageCore {
        if hasCheckError != self.hasCheckError {
            self.hasCheckError = hasCheckError
            markChanged()
        }
        return self
    }
}
