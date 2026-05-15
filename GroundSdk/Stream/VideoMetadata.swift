// Copyright (C) 2024 Parrot Drones SAS
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
import SdkCore

/// Recording session metadata.
public struct RecordingSessionMetadata {

    /// Session metadata, as `Vmeta_SessionMetadata` protobuf
    public var metadata: Vmeta_SessionMetadata

    /// Recording duration, in seconds.
    public var duration: TimeInterval
}

/// Video metadata utility.
public class VideoMetadata {

    /// Extracts session metadata from a video recording file.
    ///
    /// - Parameter file: video recording file to parse.
    /// - Returns: the data as `RecordingSessionMetadata`.
    public static func extractSessionMetadata(file: URL) -> RecordingSessionMetadata? {
        let duration = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        var recordingSessionMetadata: RecordingSessionMetadata?

        if let sessionMetadata = VmetadataExtract.sessionMetaExtract(file.path, duration: duration) {
            do {
                try recordingSessionMetadata = RecordingSessionMetadata(
                    metadata: Vmeta_SessionMetadata(serializedData: sessionMetadata),
                    duration: Double(duration.pointee) / 1_000_000.0)
            } catch let error {
                ULog.e(.streamTag, "Could not parse session metadata \(error.localizedDescription)")
            }
        }

        duration.deallocate()
        return recordingSessionMetadata
    }
}
