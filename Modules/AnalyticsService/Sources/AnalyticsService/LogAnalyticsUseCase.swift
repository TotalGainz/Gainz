//
//  LogAnalyticsUseCase.swift
//  AnalyticsService
//
//  One-shot command use-case that records an AnalyticsEvent locally
//  and schedules it for background upload.  Designed for “fire-and-forget”
//  execution so UI threads remain unblocked.
//
//  ──────────────────────────────────────────────────────────────
//  • Pure Domain logic – no SwiftUI or UIKit imports.
//  • Dependency-injected repositories (Database + Uploader) to keep
//    the use-case testable and platform-agnostic.
//  • Executes on a background queue; completion delivered on main.
//  • No HRV, recovery-score, or velocity fields—aligns with brand spec.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine
import Domain          // AnalyticsEvent, WorkoutSession, etc.
import CorePersistence // AnalyticsRepository

// MARK: - Protocol

/// Abstraction so the ViewModels call a protocol, not the concrete.
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

    /// - Parameters:
    ///   - repository: Persists AnalyticsEvent into Core Data.
    ///   - uploadScheduler: Schedules background uploads.
    ///   - queue: Execution queue (defaults to `.global(qos: .utility)`).
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

    /// Persists the event and schedules upload.
    /// - Returns: A publisher that completes when the local save finishes.
    @discardableResult
    public func execute(event: AnalyticsEvent) -> AnyPublisher<Void, Error> {
        return Future { [repository, uploadScheduler] promise in
            queue.async {
                do {
                    try repository.save(event: event)
                    uploadScheduler.markPendingUpload()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Interfaces

/// Repository responsible for local persistence of analytics events.
public protocol AnalyticsRepository {
    func save(event: AnalyticsEvent) throws
}

/// Schedules batched uploads; implementation lives inside AnalyticsService.
public protocol AnalyticsUploadScheduler {
    /// Mark that new data is pending; scheduler decides when to push.
    func markPendingUpload()
}
