// Copyright (C) 2022 Parrot Drones SAS
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

/// A plan generator/parser utility.
///
/// [Parrot Plan format documentation](https://developer.parrot.com/docs/mavlink-flightplan/plan_format.html)
public protocol PlanUtility: AnyObject, UtilityCore {
    /// Generates a plan file in the given filepath URL with the given
    /// items and configurations.
    ///
    /// cf `Plan.generate(filepath:staticConfig:items:groundStation:)` for more information.
    ///
    /// - Parameters:
    ///   - plan: the plan representation to write out to `filepath`.
    ///   - fileUrl: a local file URL where the output will be written.
    ///   - groundStation: the ground station id that creates the plan.
    /// - throws: Plan.Error or any JSON encoder errors that can occur during
    ///   generation.
    func generate(plan: Plan, at fileUrl: URL, groundStation: String) throws

    /// Generates a plan file in the given filepath URL with the given
    /// items and configurations.
    ///
    /// cf `Plan.generate(filepath:staticConfig:items:groundStation:)` for more information.
    ///
    /// - Parameters:
    ///   - plan: the plan representation to write out to `filepath`.
    ///   - filepath: a local file URL where the output will be written.
    ///   - groundStation: the ground station id that creates the plan.
    /// - throws: Plan.Error or any JSON encoder errors that can occur during
    ///   generation.
    /// - returns: a plan file (in JSON format)
    func generate(plan: Plan, groundStation: String) throws -> Data

    /// Parses a plan file in the given filepath URL.
    ///
    /// - Parameters:
    ///   - fileUrl: a local file URL where an existing plan resides.
    /// - throws:
    ///   - `Plan.Error.fileDoesNotExist` if `filepath` does not exist.
    ///   - `Plan.Error.parseError` if during the parsing any content of the plan
    ///      file can not be converted.
    ///   - any JSON decoder errors that can occur during decoding.
    /// - returns: a plan representation instance.
    func parse(fileUrl: URL) throws -> Plan

    /// Parses a plan data (in JSON format).
    ///
    /// - Parameters:
    ///   - filepath: a local file URL where an existing plan resides.
    /// - throws:
    ///   - `Plan.Error.parseError` if during the parsing any content of the plan
    ///      can not be converted.
    ///   - any JSON decoder errors that can occur during decoding.
    /// - returns: a plan representation instance.
    func parse(planData: Data) throws -> Plan
}

/// Implementation of the `PlanUtility` utility.
public class PlanUtilityCore: UtilityCore, PlanUtility {
    public let desc: UtilityCoreDescriptor = Utilities.planUtilityProvider

    private let backend: PlanUtility

    public init(backend: PlanUtility) {
        self.backend = backend
    }

    public func generate(plan: Plan, at fileUrl: URL, groundStation: String) throws {
        try backend.generate(plan: plan, at: fileUrl, groundStation: groundStation)
    }

    public func generate(plan: Plan, groundStation: String) throws -> Data {
        try backend.generate(plan: plan, groundStation: groundStation)
    }

    public func parse(fileUrl: URL) throws -> Plan {
        try backend.parse(fileUrl: fileUrl)
    }

    public func parse(planData: Data) throws -> Plan {
        try backend.parse(planData: planData)
    }
}

/// Plan generator/parser utility description
public class PlanUtilityCoreDesc: UtilityCoreApiDescriptor {
    public typealias ApiProtocol = PlanUtility
    public let uid = UtilityUid.planUtilityProvider.rawValue
}
