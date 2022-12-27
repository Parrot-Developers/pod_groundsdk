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

/// Protocol that provides time information
protocol TimeProviderProtocol {
    /// Reference time interval
    var timeInterval: TimeInterval { get }

    /// Reference dispatch time
    var dispatchTime: DispatchTime { get }
}

/// Utility class that provides a time information
///
/// This utility class mainly exists for mocking purposes in tests.
public class TimeProvider {
    /// Reference time interval.
    ///
    /// On default implementation, corresponds to the time interval since reference date.
    public static var timeInterval: TimeInterval {
        return instance.timeInterval
    }

    /// Reference dispatch time.
    ///
    /// On default implementation, corresponds to the amount of time the system has been running.
    public static var dispatchTime: DispatchTime {
        return instance.dispatchTime
    }

    /// Current TimeProvider singleton instance.
    ///
    /// Should only be set in order to mock a different behavior
    static var instance: TimeProviderProtocol = DefaultTimeProvider()

    /// Set back the instance to the default one.
    public static func setDefault() {
        instance = DefaultTimeProvider()
    }

    /// Private constructor for utility class
    private init() {}
}

/// Default implementation of the TimeProviderProtocol
private class DefaultTimeProvider: TimeProviderProtocol {
    /// Reference time interval.
    /// Corresponds to the time interval since reference date.
    var timeInterval: TimeInterval {
        return Date.timeIntervalSinceReferenceDate
    }

    /// Reference dispatch time.
    /// Corresponds to the amount of time the system has been running.
    var dispatchTime: DispatchTime {
        return DispatchTime.now()
    }

    /// Private constructor
    fileprivate init() {

    }
}

/// Extension of DispatchTime that adds uptime conversion.
public extension DispatchTime {
    /// The number of seconds since boot, excluding any time the system spent asleep.
    var uptimeSeconds: Double {
        return Double(uptimeNanoseconds) / 1_000_000_000.0
    }
}
