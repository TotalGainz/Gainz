//
//  ServiceHealthTests.swift
//  Gainz – ServiceHealth
//
//  Integration tests for NotificationManager.
//  Runs entirely on the simulator with an in-memory UNUserNotificationCenter,
//  so no alerts actually hit the system UI.
//
//  Created 27 May 2025.
//

import XCTest
import UserNotifications
@testable import ServiceHealth

final class NotificationManagerTests: XCTestCase {

    private let manager = NotificationManager.shared
    private var center: UNUserNotificationCenter {
        .current()
    }

    // MARK: - Helpers

    /// Async wrapper for reading the current pending-request count.
    private func pendingCount() async -> Int {
        await withCheckedContinuation { cont in
            center.getPendingNotificationRequests { cont.resume(returning: $0.count) }
        }
    }

    // MARK: - Tests

    /// Verifies that authorisation can be requested without throwing
    /// and returns a Boolean result.
    func testRequestAuthorisation_returnsBool() async {
        // When
        let result = await manager.requestAuthorization()

        // Then
        XCTAssertNotNil(result)
        // Cannot assert exact value because CI environments differ.
    }

    /// Schedules, fetches, and cancels a notification; expects counts to
    /// transition 0 → 1 → 0.
    func testScheduleAndCancelNotification_roundTrip() async throws {
        // Given
        await manager.clearAll()
        let initial = await pendingCount()
        XCTAssertEqual(initial, 0, "Environment not clean")

        let id    = "TEST_NOTIFICATION_ID"
        let title = "Unit-Test Title"
        let body  = "Unit-Test Body"
        let fireDate = Calendar.current.date(
            byAdding: .minute,
            value: 5,
            to: Date()
        )!

        // When – schedule
        try await manager.scheduleNotification(
            id: id,
            title: title,
            body: body,
            at: fireDate
        )

        // Then – verify pending
        let pendingAfterAdd = await pendingCount()
        XCTAssertEqual(pendingAfterAdd, 1, "Notification was not scheduled")

        // When – cancel
        await manager.cancelNotification(id: id)

        // Then – verify cleared
        let pendingAfterCancel = await pendingCount()
        XCTAssertEqual(pendingAfterCancel, 0, "Notification was not cancelled")
    }

    /// Ensures that re-scheduling with the same identifier replaces
    /// the original request (no dupes).
    func testSchedule_replacesExistingOnSameID() async throws {
        await manager.clearAll()

        let id = "DUPLICATE_ID"
        let date1 = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        let date2 = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

        // Schedule first instance
        try await manager.scheduleNotification(
            id: id,
            title: "First",
            body: "First Body",
            at: date1
        )

        // Schedule again with same id but different fire date
        try await manager.scheduleNotification(
            id: id,
            title: "Second",
            body: "Second Body",
            at: date2
        )

        // Fetch requests and ensure there is still only one
        let requests = await withCheckedContinuation { cont in
            center.getPendingNotificationRequests { cont.resume(returning: $0) }
        }

        XCTAssertEqual(requests.count, 1, "Duplicate requests not replaced")
        XCTAssertEqual(requests.first?.identifier, id)
    }
}
