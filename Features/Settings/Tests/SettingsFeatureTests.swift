//
//  SettingsFeatureTests.swift
//  GainzTests
//
//  Unit test suite for the Settings feature.
//  **Reference reading**
//  • Unit-testing Combine publishers            [oai_citation:0‡swiftbysundell.com](https://www.swiftbysundell.com/articles/unit-testing-combine-based-swift-code?utm_source=chatgpt.com)
//  • Mocking UserDefaults strategies           [oai_citation:1‡colinwren.medium.com](https://colinwren.medium.com/mocking-user-defaults-in-your-swift-unit-tests-54f8a8452dda?utm_source=chatgpt.com) [oai_citation:2‡swiftbysundell.com](https://www.swiftbysundell.com/tips/avoiding-mocking-userdefaults?utm_source=chatgpt.com)
//  • Coordinator-pattern navigation tests      [oai_citation:3‡medium.com](https://medium.com/%40dikidwid0/mastering-navigation-in-swiftui-using-coordinator-pattern-833396c67db5?utm_source=chatgpt.com) [oai_citation:4‡medium.com](https://medium.com/%40michaelmavris/how-to-use-swiftui-coordinators-1011ca881eef?utm_source=chatgpt.com)
//  • Mocking UNUserNotificationCenter          [oai_citation:5‡reddit.com](https://www.reddit.com/r/swift/comments/eexvk0/mocking_unusernotificationcenter/?utm_source=chatgpt.com) [oai_citation:6‡stackoverflow.com](https://stackoverflow.com/questions/58960233/unit-testing-for-unusernotificationcenter-requestauthorization-in-swift-5?utm_source=chatgpt.com)
//  • Deep-link constant docs                   [oai_citation:7‡developer.apple.com](https://developer.apple.com/documentation/uikit/uiapplication/opennotificationsettingsurlstring?utm_source=chatgpt.com) [oai_citation:8‡developer.apple.com](https://developer.apple.com/documentation/uikit/uiapplicationopennotificationsettingsurlstring?utm_source=chatgpt.com)
//  • Testing @AppStorage                        [oai_citation:9‡iosdev.space](https://iosdev.space/%40qcoding/112565808826634354?utm_source=chatgpt.com) [oai_citation:10‡medium.com](https://medium.com/%40petrpavlik/testable-appstorage-c825746d4c39?utm_source=chatgpt.com)
//  • Async/await + Combine test tips           [oai_citation:11‡blog.jacobstechtavern.com](https://blog.jacobstechtavern.com/p/combine-asyncawait-and-unit-testing?utm_source=chatgpt.com)
//
//  NOTE: The feature purposefully omits HRV or Velocity-tracking logic.
//

import XCTest
import Combine
@testable import Settings

// MARK: - Mock Helpers

private final class MockAppearanceManager: AppearanceManaging {
    static let shared: AppearanceManaging = MockAppearanceManager()
    private(set) var darkModeCalls = 0
    func setDarkMode(_ enabled: Bool) { darkModeCalls += 1 }
}

private final class MockFeedbackManager: FeedbackManaging {
    static let shared: FeedbackManaging = MockFeedbackManager()
    var hapticsEnabled: Bool = true
    var notificationsEnabled: Bool = true
}

// MARK: - Settings Feature Tests

@MainActor
final class SettingsFeatureTests: XCTestCase {

    private var viewModel: SettingsViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        // Isolated in-memory UserDefaults suite
        let suite = UserDefaults(suiteName: #function)!
        suite.removePersistentDomain(forName: #function)

        viewModel = SettingsViewModel(
            appearanceManager: MockAppearanceManager.shared,
            feedbackManager: MockFeedbackManager.shared,
            storage: suite
        )
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - ViewModel Tests

    func testDefaultValues_MatchExpected() {
        XCTAssertFalse(viewModel.darkModeEnabled)
        XCTAssertTrue(viewModel.hapticsEnabled)
        XCTAssertTrue(viewModel.notificationsEnabled)
    }

    func testDarkModeToggle_PersistsAndInvokesManager() throws {
        let exp = expectation(description: "manager called")

        // Observe the mock to count invocations
        var disposable: AnyCancellable?
        disposable = viewModel.$darkModeEnabled
            .dropFirst()
            .sink { _ in
                let mock = MockAppearanceManager.shared as! MockAppearanceManager
                if mock.darkModeCalls == 1 { exp.fulfill() }
            }
        viewModel.toggleDarkMode()
        wait(for: [exp], timeout: 1.0)
        disposable?.cancel()

        // Verify persisted value
        let persisted = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        XCTAssertEqual(persisted, viewModel.darkModeEnabled)
    }

    func testHapticsToggle_UpdatesManager() {
        let mock = MockFeedbackManager.shared as! MockFeedbackManager
        viewModel.toggleHaptics()
        XCTAssertEqual(mock.hapticsEnabled, viewModel.hapticsEnabled)
    }

    func testNotificationsToggle_UpdatesManager() {
        let mock = MockFeedbackManager.shared as! MockFeedbackManager
        viewModel.toggleNotifications()
        XCTAssertEqual(mock.notificationsEnabled, viewModel.notificationsEnabled)
    }

    // MARK: - Coordinator Tests

    func testCoordinatorPushesLicenses() {
        let coordinator = SettingsCoordinator(viewModel: viewModel)
        coordinator.showLicenses()
        XCTAssertTrue(coordinator.path.contains(SettingsCoordinator.Destination.licenses))
    }

    func testCoordinatorOpensWebURL() throws {
        let coordinator = SettingsCoordinator(viewModel: viewModel)
        let url = try XCTUnwrap(URL(string: "https://gainz.app"))
        coordinator.openURL(url)
        XCTAssertTrue(coordinator.path.contains(SettingsCoordinator.Destination.web(url)))
    }
}
