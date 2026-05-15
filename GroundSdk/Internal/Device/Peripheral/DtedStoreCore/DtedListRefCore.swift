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

/// Implementation of a reference on a list of dted files
class DtedListRefCore: Ref<[DtedFile]>, DtedOperationRef {
    /// Dted store instance
    private let dtedStore: DtedStoreCore
    /// Dted store listener
    private var dtedStoreListener: DtedStoreCore.Listener!
    /// Running dted browse request, nil if there are no queries running
    private(set) var request: CancelableCore?

    /// Convenience accessor to the `value` of the `Ref` returning the `value` typed to a
    /// implementation dependent type.
    private var files: [DtedFileCore] {
        self.value as! [DtedFileCore]
    }

    /// Constructor
    ///
    /// - Parameters:
    ///   - dtedStore: dted store instance
    ///   - observer: observer notified when the list changes
    init(dtedStore: DtedStoreCore, observer: @escaping Observer) {
        self.dtedStore = dtedStore
        super.init(observer: observer)
        dtedStoreListener = dtedStore.register { [unowned self] event in
            // store content changed, update dted list
            self.dtedEventOccured(event)
        }
        setup(value: nil)
        // send the initial query
        browse()
    }

    /// destructor
    deinit {
        cancel()
        dtedStore.unregister(listener: dtedStoreListener)
    }

    /// Cancels the request
    func cancel() {
        request?.cancel()
        request = nil
    }
}

private extension DtedListRefCore {

    /// Send a request to load dted list
    func dtedEventOccured(_ event: DtedStoreChangeEvent) {
        guard dtedStore.published  else {
            // not published, set the Dted list to nil
            update(newValue: nil)
            return
        }
        let newList = process(event, files: self.files)
        update(newValue: newList)
    }

    /// Apply the change described by a `DtedStoreChangeEvent` to a given list of dted returning
    /// the resulting list of dted files.
    ///
    /// - Parameters:
    ///   - event: the change event describing the change that occured.
    ///   - files: the list to act upon.
    /// - Returns: a new list that reflects the change as described by the `event`.
    func process(_ event: DtedStoreChangeEvent, files: [DtedFileCore]) -> [DtedFileCore] {
        var newList = files
        switch event {
        case .terrainAdded(let file):
            if !newList.contains(file) {
                newList.append(file)
            }
        case .terrainRemoved:
            browse()
        case .allTerrainsRemoved:
            newList = []
        }
        return newList
    }

    func browse() {
        guard request == nil else { return }
        request = dtedStore
            .backend.browse(completion: { [weak self] files in
            // weak self in case backend call callback after cancelling request
            guard let self = self else { return }
            self.request = nil
            // update the ref with the new list
            self.update(newValue: files)
        })
    }
}
