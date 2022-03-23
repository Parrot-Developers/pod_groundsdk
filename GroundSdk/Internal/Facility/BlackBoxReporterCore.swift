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

/// Core implementation of the black box reporter facility
class BlackBoxReporterCore: FacilityCore, BlackBoxReporter {

    fileprivate(set) var pendingCount = 0

    fileprivate(set) var isUploading = false

    /// Constructor
    ///
    /// - Parameter store: component store owning this component
    init(store: ComponentStoreCore) {
        super.init(desc: Facilities.blackBoxReporter, store: store)
    }

    override func reset() {
        pendingCount = 0
        isUploading = false
    }
}

/// Backend callback methods
extension BlackBoxReporterCore {
    /// Changes current pending count.
    ///
    /// - Parameter pendingCount: new pending count
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(pendingCount newValue: Int) -> BlackBoxReporterCore {
        if pendingCount != newValue {
            pendingCount = newValue
            markChanged()
        }
        return self
    }

    /// Changes the uploading flag
    ///
    /// - Parameter isUploading: new uploading flag
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(isUploading newValue: Bool) -> BlackBoxReporterCore {
        if isUploading != newValue {
            isUploading = newValue
            markChanged()
        }
        return self
    }
}
