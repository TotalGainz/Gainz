//
//  SetRecord.swift
//  Domain – Models
//
//  Captures a single set within an ExerciseLog.
//  Design follows research-backed metrics: weight, reps, RIR or RPE.
//  No HRV, recovery scores, or velocity tracking.
//
//  References:
//  - NASM on Reps-in-Reserve :contentReference[oaicite:0]{index=0}
 // - NASM on RPE scale :contentReference[oaicite:1]{index=1}
 // - Volume-load formula (Sets × Reps × Weight) :contentReference[oaicite:2]{index=2}
 // - Reliability of RIR for load prescription (J Strength Cond Res 2022) :contentReference[oaicite:3]{index=3}
 // - Modified Borg CR-10 RPE scale :contentReference[oaicite:4]{index=4}
 // - Practical RIR usage in hypertrophy training :contentReference[oaicite:5]{index=5}
//
//  Created by Gainz Core Team on 27 May 2025.
//

import Foundation

/// Immutable value representing one executed set.
///
/// ```swift
/// let topSet = SetRecord(weight: 120, reps: 6, rir: 1)
/// print(topSet.volume) // 720 kg•reps
/// ```
public struct SetRecord: Identifiable, Hashable, Codable {

    // MARK: Identity

    /// Unique identifier for diffing & persistence.
    public let id: UUID

    // MARK: Loaded Fields

    /// Load in **kilograms**; convert at UI layer if user prefers pounds.
    public let weight: Double

    /// Completed repetitions (≥ 0).
    public let reps: Int

    /// Reps-in-Reserve (0 = failure, 1–4 = proximity), optional.
    public let rir: Int?

    /// Single-set RPE (1–10), optional alternative to RIR.
    public let rpe: Int?

    /// Optional cadence in “ecc-pause-con-pause” seconds (e.g., `40X1` = 4-0-fast-1).
    public let tempo: String?

    // MARK: Derived

    /// Simple volume-load metric (kg × reps).
    public var volume: Double { weight * Double(reps) }

    // MARK: Init

    public init(
        id: UUID = .init(),
        weight: Double,
        reps: Int,
        rir: Int? = nil,
        rpe: Int? = nil,
        tempo: String? = nil
    ) {
        precondition(weight > 0, "Weight must be > 0 kg")
        precondition(reps >= 0, "Reps must be non-negative")
        if let rir = rir { precondition((0...5).contains(rir), "RIR must be 0–5") }
        if let rpe = rpe { precondition((1...10).contains(rpe), "RPE must be 1–10") }

        self.id = id
        self.weight = weight
        self.reps = reps
        self.rir = rir
        self.rpe = rpe
        self.tempo = tempo
    }
}
