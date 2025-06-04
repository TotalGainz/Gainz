//
//  SettingsViewModelTests.swift
//  Gainz – Settings Feature Tests
//
//  Unit-test coverage for SettingsViewModel.  Verifies default bootstrap,
//  persistence round-trip, dependency-injection, and Combine-published
//  state changes.
//
//  References / inspiration:
//  • ObservableObject unit-testing pattern  [oai_citation:0‡stackoverflow.com](https://stackoverflow.com/questions/78462538/unit-testing-an-observableobject-class-in-swiftui-that-depends-on-a-network-requ?utm_source=chatgpt.com)
//  • @AppStorage testability techniques  [oai_citation:1‡iosdev.space](https://iosdev.space/%40qcoding/112565808826634354?utm_source=chatgpt.com) [oai_citation:2‡medium.com](https://medium.com/%40petrpavlik/testable-appstorage-c825746d4c39?utm_source=chatgpt.com)
//  • Combine publisher test helpers  [oai_citation:3‡swiftbysundell.com](https://www.swiftbysundell.com/articles/unit-testing-combine-based-swift-code?utm_source=chatgpt.com) [oai_citation:4‡medium.com](https://medium.com/%40rokridi/unit-testing-combine-publishers-in-swift-ca328be66f18?utm_source=chatgpt.com)
 // • Coordinator-pattern test nuances (navigation-agnostic)  [oai_citation:5‡stackoverflow.com](https://stackoverflow.com/questions/74935288/unit-test-assertion-on-a-coordinator-fails-because-the-view-controller-takes-som?utm_source=chatgpt.com) [oai_citation:6‡youtube.com](https://www.youtube.com/watch?v=_ubeTqVV3Ng&utm_source=chatgpt.com)
 // • Mocking UserDefaults / persistent stores  [oai_citation:7‡colinwren.medium.com](https://colinwren.medium.com/mocking-user-defaults-in-your-swift-unit-tests-54f8a8452dda?utm_source=chatgpt.com) [oai_citation:8‡stackoverflow.com](https://stackoverflow.com/questions/59851675/how-to-write-unit-test-for-userdefaults?utm_source=chatgpt.com)
 // • Concurrency & MainActor caveats in XCTest  [oai_citation:9‡forums.swift.org](https://forums.swift.org/t/swift-5-10-concurrency-and-xctest/69929?utm_source=chatgpt.com) [oai_citation:10‡qualitycoding.org](https://qualitycoding.org/xctest-mainactor/?utm_source=chatgpt.com)
//
//  NOTE: No HRV or velocity-tracking behaviour is tested—out of scope.
//

import XCTest
import Combine
@testable import Settings

// MARK: - Mock Implementations

private final class MockAppearanceManager: AppearanceManaging {
    static let shared: AppearanceManaging = MockAppearanceManager()

    private(set) var didSetDarkMode: Bool?
    func setDarkMode(_ enabled: Bool) {
        didSetDarkMode = enabled
    }
}

private final class MockFeedbackManager: FeedbackManaging {
    static let shared: FeedbackManaging = MockFeedbackManager()

    var hapticsEnabled: Bool = true
    var notificationsEnabled: Bool = true
}

// Isolated UserDefaults container for test repeatability
private final class EphemeralDefaults: UserDefaults {
    init() { super.init(suiteName: UUID().uuidString)! }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - SettingsViewModelTests

final class SettingsViewModelTests: XCTestCase {

    private var viewModel: SettingsViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        let defaults = EphemeralDefaults()
        viewModel = SettingsViewModel(
            appearanceManager: MockAppearanceManager.shared,
            feedbackManager: MockFeedbackManager.shared,
            storage: defaults
        )
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }

    // MARK: – Tests

    func testInitialValues_matchDefaults() {
        // GIVEN newly-initialised ViewModel
        // WHEN reading published properties
        // THEN they equal UserDefaults defaults
        XCTAssertFalse(viewModel.darkModeEnabled)
        XCTAssertTrue(viewModel.hapticsEnabled)
        XCTAssertTrue(viewModel.notificationsEnabled)
    }

    func testToggleDarkMode_updatesAppearanceManagerAndPersists() {
        // GIVEN darkMode is off
        let appearance = MockAppearanceManager.shared as! MockAppearanceManager
        let defaults = EphemeralDefaults()

        // WHEN toggled
        viewModel.toggleDarkMode()

        // THEN appearance manager is called
        XCTAssertEqual(appearance.didSetDarkMode, true)

        // AND value persisted
        XCTAssertTrue(
            defaults.bool(forKey: "darkModeEnabled"),
            "darkModeEnabled not persisted to UserDefaults"
        )
    }

    func testToggleHaptics_propagatesAndPersists() {
        // GIVEN haptics is on
        let feedback = MockFeedbackManager.shared as! MockFeedbackManager
        let expectation = XCTestExpectation(description: "haptics toggled")

        // Observe Combine publisher for change
        viewModel.$hapticsEnabled
            .dropFirst()
            .sink { isOn in
                XCTAssertFalse(isOn)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // WHEN toggled
        viewModel.toggleHaptics()

        // THEN feedback manager updated
        XCTAssertFalse(feedback.hapticsEnabled)

        wait(for: [expectation], timeout: 0.1)
    }

    func testToggleNotifications_updatesManagerAndPersists() {
        let feedback = MockFeedbackManager.shared as! MockFeedbackManager

        viewModel.notificationsEnabled = false
        XCTAssertFalse(feedback.notificationsEnabled)
    }
}
