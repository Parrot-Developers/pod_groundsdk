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

/// Setting providing access to the Wifi access point security setup.
public protocol SecurityModeSetting: AnyObject {

    /// Tells if the setting value has been changed and is waiting for change confirmation.
    var updating: Bool { get }

    /// Supported security modes.
    var supportedModes: Set<SecurityMode> { get }

    /// Currently active security modes.
    var modes: Set<SecurityMode> { get }

    /// Current security mode.
    @available(*, deprecated, message: "Use `modes` instead")
    var mode: SecurityMode { get }

    /// Sets the security mode to `.open`, disabling any security checks.
    ///
    /// - Note: this function does nothing if the `.open` mode is not supported (see `supportedModes`).
    func open()

    /// Sets the security mode to `.wpa2Secured`, and secures connection to the access point using a password.
    ///
    /// Password validation is checked first (see `WifiPasswordUtil.isValid(_:)`), and nothing is done if password
    /// is not valid.
    ///
    /// - Note: this function does nothing if the `.wpa2Secured` mode is not supported (see `supportedModes`).
    ///
    /// - Parameter password: password to secure the access point with
    /// - Returns: `true` if the new configuration has been sent, `false` otherwise
    @available(*, deprecated, message: "Use `secure(with:password:)` instead")
    func secureWithWpa2(password: String) -> Bool

    /// Configures secure connection with the given modes and password.
    ///
    /// Password validation is checked first (see `WifiPasswordUtil.isValid(_:)`), and nothing is done if password
    /// is not valid.
    ///
    /// Modes that are not supported (see `supportedModes`), as well as `.open` mode, will be ignored when passed in
    /// the modes argument.
    ///
    /// - Parameters:
    ///   - modes: security modes to activate
    ///   - password: access point password
    /// - Returns: `true` if the new configuration has been sent, `false` otherwise
    func secure(with modes: Set<SecurityMode>, password: String) -> Bool
}

/// Utility class for Wifi passwords.
public class WifiPasswordUtil: NSObject {

    /// Regular expression in order to check the password validity.
    public static let passwordPattern = "^[\\x20-\\x7E]{8,63}$"

    /// Checks wifi password validity.
    ///
    /// - Note: A valid wifi password contains from 8 to 63 printable ASCII characters.
    /// - Parameter password: the password to validate
    /// - Returns: `true` if password is valid, `false` otherwise
    public static func isValid(_ password: String) -> Bool {
        return password.range(of: passwordPattern, options: .regularExpression) != nil
    }

    /// Private constructor for utility class.
    private override init() {}
}
