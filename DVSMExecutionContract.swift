//
//  DVSMCore.swift
//  DVSM v∞ — Reality-Stable Monolith + Lattice Extension
//
//  Primary Author: Daniel J. Dillberg
//  Status: REFERENCE STANDARD [Lattice Integrated]
//  Copyright © 2024. All Rights Reserved.
//

import Foundation
import Accelerate
import CryptoKit

// =====================================================
// MARK: - 1. CANONICAL STATE (Memory Invariant)
// =====================================================

public final class DVSMBitBlock: @unchecked Sendable {
    fileprivate let buffer: UnsafeMutableRawPointer

    public init() {
        self.buffer = UnsafeMutableRawPointer.allocate(byteCount: 2048, alignment: 64)
        self.buffer.initializeMemory(as: UInt8.self, repeating: 0, count: 2048)
    }

    /// bit-perfect transfer from candidate arrays
    internal init(from doubles: [Double]) {
        self.buffer = UnsafeMutableRawPointer.allocate(byteCount: 2048, alignment: 64)
        let ptr = self.buffer.assumingMemoryBound(to: UInt64.self)
        for i in 0..<256 {
            let val = i < doubles.count ? doubles[i] : 0.0
            // Final normalization pass before bit-locking
            let clean = val.isFinite ? (val == 0.0 ? 0.0 : val) : 0.0
            ptr[i] = clean.bitPattern.littleEndian
        }
    }

    public func snapshot() -> DVSMBitBlock {
        let new = DVSMBitBlock()
        new.buffer.copyMemory(from: self.buffer, byteCount: 2048)
        return new
    }

    deinit { buffer.deallocate() }

    public var bytes: Data { Data(bytes: buffer, count: 2048) }

    internal var lanes: UnsafeMutablePointer<UInt64> {
        buffer.assumingMemoryBound(to: UInt64.self)
    }
}

// =====================================================
// MARK: - 1.5 LATTICE LOGIC LAYER
// =====================================================

public struct DVMSLatticeResult {
    public let projected: [Double]
    public let residual: [Double]
}

public struct DVMSLattice {
    private static let step: Double = 0.125

    public static func project(_ flux: [Double]) -> DVMSLatticeResult {
        var projected = [Double]()
        var residual = [Double]()
        
        for v in flux {
            let clean = v.isFinite ? v : 0.0
            let p = (clean / step).rounded() * step
            projected.append(p)
            residual.append(clean - p)
        }
        
        return DVMSLatticeResult(projected: projected, residual: residual)
    }
}

// =====================================================
// MARK: - 2. THE TRANSITION LAW (Process Invariant)
// =====================================================

public struct DVSMLaw {

    public static func propose(
        current: DVSMBitBlock,
        flux: [Double],
        latticeEnabled: Bool = true
    ) -> DVSMBitBlock {

        let S = current.lanes
        let tau: Double = 0.05

        // G0: canonical normalization
        let Vraw = flux.map { $0.isFinite ? ($0 == 0.0 ? 0.0 : $0) : 0.0 }

        let lattice = latticeEnabled
            ? DVMSLattice.project(Vraw)
            : DVMSLatticeResult(projected: Vraw, residual: [])

        let V = lattice.projected

        var next = [Double](repeating: 0.0, count: 256)

        for i in 0.. String {
        lock.lock(); defer { lock.unlock() }

        // 1. Law Proposal
        let candidate = DVSMLaw.propose(
            current: physicalState,
            flux: input,
            latticeEnabled: true
        )

        // 2. Commit (Atomic Pointer Update)
        self.physicalState = candidate

        // 3. Hash (Deterministic Observation)
        let hash = SHA256.hash(data: physicalState.bytes)
            .compactMap { String(format: "%02x", $0) }
            .joined()

        self.lastHash = hash
        self.sequence += 1
        return hash
    }
}
