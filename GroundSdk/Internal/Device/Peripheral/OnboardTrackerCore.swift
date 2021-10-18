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

/// OnboardTracker backend protocol
public protocol OnboardTrackerBackend: AnyObject {

    /// Adds a new target to track.
    ///
    /// - Parameter trackingRequest: the tracking request
    func addNewTarget(trackingRequest: TrackingRequestCore)

    /// Replaces current targets by a new target.
    ///
    /// - Parameter trackingRequest: the tracking request
    func replaceAllTargetsBy(trackingRequest: TrackingRequestCore)

    /// Remove all targets from tracking.
    func removeAllTargets()

    /// Remove specific target from tracking.
    ///
    /// - Parameters:
    ///   - targetId: id of the target given by the drone.
    func removeTarget(targetId: UInt)

    /// Start tracking engine
    ///
    ///  Parameter boxProposals: true to use box proposals, false without
    func startTrackingEngine(boxProposals: Bool)

    /// Stop tracking engine.
    func stopTrackingEngine()
}

/// Type of tracking request.
public enum TrackingRequestType: Int, CustomStringConvertible {

    /// Request to add a target to track from a rectangle.
    ///
    /// Requests of this type can be cast to RectTRackingRequestCore
    case trackFromRectangle

    /// Request to add a target to track from a proposal id.
    ///
    /// Requests of this type can be cast to ProposalTrackingRequestCore.
    case trackFromProposal

    /// Debug description.
    public var description: String {
        switch self {
        case .trackFromRectangle:  return "trackFromRectangle"
        case .trackFromProposal: return "trackFromProposal"
        }
    }
}

/// Core class for requests to add a target to track from a rectangle in the video.
public class RectTrackingRequestCore: TrackingRequestCore {
    /// Horizontal position of the top left corner's target in the video, in range [0, 1].
    private (set) public var horizontalPosition: Float

    /// Vertical position of the top left corner's target in the video, in range [0, 1].
    private (set) public var verticalPosition: Float

    /// Width of target in the video, in range [0, 1].
    private (set) public var width: Float

    /// Height of target in the video, in range [0, 1].
    private (set) public var height: Float

    /// Constructor
    ///
    /// - Parameters:
    ///     - timestamp: timestamp of the video frame
    ///     - horizontalPosition: horizontal position of the top left corner's target in the video, in range [0, 1]
    ///     - verticalPosition: vertical position of the top left corner's target in the video, in range [0, 1]
    ///     - width: width of target in the video, in range [0, 1]
    ///     - height: height of target in the video, in range [0, 1]
    public init(timestamp: UInt64, horizontalPosition: Float, verticalPosition: Float, width: Float, height: Float) {
        self.horizontalPosition = horizontalPosition
        self.verticalPosition = verticalPosition
        self.width = width
        self.height = height
        super.init(type: .trackFromRectangle, timestamp: timestamp)
    }
}

/// Core class for requests to add a target to track from a proposal id.
public class ProposalTrackingRequestCore: TrackingRequestCore {
    /// Proposal id.
    private (set) public var proposalId: UInt

    /// Constructor.
    ///
    /// - Parameters:
    ///     - timestamp: timestamp of the video frame
    ///     - proposalId: id of the proposal given by the drone
    public init(timestamp: UInt64, proposalId: UInt) {
        self.proposalId = proposalId
        super.init(type: .trackFromProposal, timestamp: timestamp)
    }

    /// Gets the proposal id.
    ///
    /// - Returns: proposal id
    public func getProposalId() -> UInt {
        return proposalId
    }
}

/// Base core class for requests to add a target to track.
public class TrackingRequestCore: TrackingRequest {
    /// Type of tracking request.
    private (set) public var type: TrackingRequestType

    /// Timestamp of the video frame.
    private (set) public var timestamp: UInt64

    /// Sets a cookie that will be attached to the target.
    ///
    /// This cookie will be returned by cookie in Target.
    public var cookie: UInt = 0

    /// Constructor.
    ///
    /// - Parameters:
    ///     - type: tracking request type
    ///     - timestamp: timestamp of the video frame
    init(type: TrackingRequestType, timestamp: UInt64) {
        self.type = type
        self.timestamp = timestamp
    }
}

/// Internal onboard tracker implementation
public class OnboardTrackerCore: PeripheralCore, OnboardTracker {
    public private(set) var _targetsList: [UInt: Target] = [:]

    public private(set) var _requestStatus: RequestStatus?

    public private(set) var _isAvailable: Bool = false

    public private(set) var _trackingEngineState: TrackingEngineState = .droneActivated

    /// Implementation backend
    private unowned let backend: OnboardTrackerBackend

    /// Constructor
    ///
    /// - Parameters:
    ///   - store: store where this peripheral will be stored.
    ///   - backend: onboard tracker backend.
    public init(store: ComponentStoreCore, backend: OnboardTrackerBackend) {
        self.backend = backend
        super.init(desc: Peripherals.onboardTracker, store: store)
    }

    /// Creates a request to add a target to track from a rectangle in the video
    ///
    /// - Parameters:
    ///     - timestamp: timestamp of the video frame
    ///     - horizontalPosition: horizontal position of the top left corner's target in the video, in range [0, 1]
    ///     - verticalPosition: vertical position of the top left corner's target in the video, in range [0, 1]
    ///     - width: width of target in the video, in range [0, 1]
    ///     - height: height of target in the video, in range [0, 1]
    /// - Returns: a new tracking request
    public func ofRect(timestamp: UInt64, horizontalPosition: Float, verticalPosition: Float,
                       width: Float, height: Float) -> TrackingRequest {
        return RectTrackingRequestCore(timestamp: timestamp, horizontalPosition: horizontalPosition,
                                       verticalPosition: verticalPosition, width: width, height: height)
    }

    /// Creates a request to add a target to track from a proposal id.
    ///
    /// - Parameters:
    ///     - timestamp: timestamp of the video frame
    ///     - proposalId: id of the proposal given by the drone
    /// - Returns: a new tracking request
    public func ofProposal(timestamp: UInt64, proposalId: UInt) -> TrackingRequest {
        return ProposalTrackingRequestCore(timestamp: timestamp, proposalId: proposalId)
    }

    /// Adds a new target to track.
    ///
    /// - Parameter trackingRequest: the tracking request
    public func addNewTarget(trackingRequest: TrackingRequest) {
        if let trackingRequestCore = trackingRequest as? TrackingRequestCore {
            self.backend.addNewTarget(trackingRequest: trackingRequestCore)
        }
    }

    /// Replaces current targets by a new target.
    ///
    /// - Parameter trackingRequest: the tracking request
    public func replaceAllTargetsBy(trackingRequest: TrackingRequest) {
        if let trackingRequestCore = trackingRequest as? TrackingRequestCore {
            self.backend.replaceAllTargetsBy(trackingRequest: trackingRequestCore)
        }
    }

    /// Remove all targets from tracking.
    public func removeAllTargets() {
        if _targetsList.count != 0 {
            backend.removeAllTargets()
        }
    }

    /// Start tracking engine.
    ///
    ///  Parameter boxProposals: true to use box proposals, false without
    public func startTrackingEngine(boxProposals: Bool) {
        if trackingEngineState == .available {
            backend.startTrackingEngine(boxProposals: boxProposals)
        }
    }

    /// Stop tracking engine.
    public func stopTrackingEngine() {
        if trackingEngineState == .activated {
            backend.stopTrackingEngine()
        }
    }

    /// Tells the current state of activation off tracking engine.
    public var trackingEngineState: TrackingEngineState {
        return _trackingEngineState
    }

    /// Remove specific target from tracking.
    ///
    /// - Parameters:
    ///   - targetId: id of the target given by the drone.
    public func removeTarget(targetId: UInt) {
        backend.removeTarget(targetId: targetId)
    }

    /// Tells the current tracking state for each target of the drone.
    public var targets: [UInt: Target] {
        return _targetsList
    }

    /// Tells if last command was processed or if there was an issue with it.
    public var requestStatus: RequestStatus? {
        return _requestStatus
    }

    /// Tells if onboard tracker feature is available.
    public var isAvailable: Bool {
        return _isAvailable
    }
}

// MARK: - Backend callback methods
extension OnboardTrackerCore {
    /// Updates the tracking list.
    ///
    /// - Parameter targetsList: new targets list.
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(targetsList newTargetsList: [UInt: Target])
        -> OnboardTrackerCore {
        if _targetsList != newTargetsList {
            _targetsList = newTargetsList
            markChanged()
        }
        return self
    }

    /// Updates the request status.
    ///
    /// - Parameter requestStatus: new request status.
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(requestStatus newRequestStatus: RequestStatus?)
        -> OnboardTrackerCore {
        if _requestStatus != newRequestStatus {
            _requestStatus = newRequestStatus
            markChanged()
        }
        return self
    }

    /// Updates the availability of onboard tracker feature.
    ///
    /// - Parameter isAvailable: new availability of feature.
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(isAvailable newIsAvailable: Bool)
        -> OnboardTrackerCore {
        if _isAvailable != newIsAvailable {
            _isAvailable = newIsAvailable
            markChanged()
        }
        return self
    }

    /// Updates the tracking engine state.
    ///
    /// - Parameter trackingEngineState: new tracking engine state.
    /// - Returns: self to allow call chaining.
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(trackingEngineState newTrackingEngineState: TrackingEngineState)
        -> OnboardTrackerCore {
        if _trackingEngineState != newTrackingEngineState {
            _trackingEngineState = newTrackingEngineState
            markChanged()
        }
        return self
    }
}
