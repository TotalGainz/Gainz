//  LogAnalyticsUseCase.swift
//  AnalyticsService
//
//  One-shot command use-case that records an AnalyticsEvent locally
//  and schedules it for background upload. Designed for “fire-and-forget”
//  execution so UI threads remain unblocked.
//
//  ──────────────────────────────────────────────────────────────
//  • Pure Domain logic – no SwiftUI or UIKit imports.
//  • Dependency-injected repositories (Database + Uploader) keep
//    the use-case testable and platform-agnostic.
//  • Executes on a background queue; completion delivered on main.
//  • No HRV, recovery-score, or velocity fields — aligns with brand spec.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine
import Domain          // AnalyticsEvent, WorkoutSession, etc.
import CorePersistence // AnalyticsRepository

// MARK: - Protocol

/// Abstraction so ViewModels depend on a protocol (for easier testing).
public protocol LogAnalyticsUseCaseProtocol {
    @discardableResult
    func execute(event: AnalyticsEvent) -> AnyPublisher<Void, Error>
}

// MARK: - Implementation

public final class LogAnalyticsUseCase: LogAnalyticsUseCaseProtocol {

    // Dependencies
    private let repository: AnalyticsRepository
    private let uploadScheduler: AnalyticsUploadScheduler
    private let queue: DispatchQueue

    /// Initializes the use-case with required dependencies.
    /// - Parameters:
    ///   - repository: Persists AnalyticsEvent to local store (e.g., Core Data).
    ///   - uploadScheduler: Schedules background uploads for new events.
    ///   - queue: Execution queue (defaults to a utility global queue).
    public init(
        repository: AnalyticsRepository,
        uploadScheduler: AnalyticsUploadScheduler,
        queue: DispatchQueue = .global(qos: .utility)
    ) {
        self.repository = repository
        self.uploadScheduler = uploadScheduler
        self.queue = queue
    }

    // MARK: Log Analytics

    /// Persists the event and schedules it for upload.
    /// - Returns: A Combine publisher that completes when the local save finishes.
    @discardableResult
    public func execute(event: AnalyticsEvent) -> AnyPublisher<Void, Error> {
        return Future { [repository, uploadScheduler] promise in
            // Perform persistence off the main thread.
            queue.async {
                do {
                    try repository.save(event: event)            // Save event to database.
                    uploadScheduler.markPendingUpload()          // Notify scheduler to enqueue upload.
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)  // Callback on main thread.
        .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Interfaces

/// Repository responsible for local persistence of analytics events.
public protocol AnalyticsRepository {
    func save(event: AnalyticsEvent) throws
}

/// Schedules batched uploads; concrete implementation in AnalyticsService.
public protocol AnalyticsUploadScheduler {
    /// Signals that new analytics data is pending; scheduler decides when to push to server.
    func markPendingUpload()
}
