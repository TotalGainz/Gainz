//
//  OnboardingViewModelTests.swift
//  GainzTests
//
//  Created by Broderick Hiland on 2025-06-04.
//  © 2025 Echelon Commerce LLC. All rights reserved.
//

import XCTest
import Combine
@testable import Gainz

final class OnboardingViewModelTests: XCTestCase {

    // System Under Test
    private var sut: OnboardingViewModel!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Lifecycle
    override func setUpWithError() throws {
        try super.setUpWithError()
        cancellables = []
        sut = OnboardingViewModel(pages: OnboardingPage.samplePages)
    }

    override func tearDownWithError() throws {
        sut = nil
        cancellables = nil
        try super.tearDownWithError()
    }

    // MARK: - Tests
    /// Verify that `advance()` increments `currentPage`
    func testAdvanceIncrementsCurrentPage() {
        // given
        XCTAssertEqual(sut.currentPage, 0)

        // when
        sut.advance()

        // then
        XCTAssertEqual(sut.currentPage, 1)
    }

    /// Verify that advancing past the last page clamps to the final index
    func testAdvanceDoesNotExceedLastPage() {
        // when
        for _ in 0..<(sut.pages.count + 3) {
            sut.advance()
        }

        // then
        XCTAssertEqual(sut.currentPage, sut.pages.lastIndex)
    }

    /// Verify the `didFinishPublisher` emits exactly once when onboarding completes
    func testDidFinishPublisherEmitsUponCompletion() {
        // given
        let expectation = XCTestExpectation(description: "didFinishPublisher emits")

        var emissionCount = 0
        sut.didFinishPublisher
            .sink { emissionCount += 1; expectation.fulfill() }
            .store(in: &cancellables)

        // when – walk through all pages plus one extra call
        for _ in 0...sut.pages.count {
            sut.advance()
        }

        // then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(emissionCount, 1)
    }
}
