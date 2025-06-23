import XCTest
import SwiftUI
@testable import GainzFeaturePlanner
import SnapshotTesting

/// Snapshot tests for `PlannerView`.
///
/// * Renders the planner in both light & dark mode.
/// * Covers small (iPhone SE 3), medium (iPhone 15 Pro), and
///   accessibility‑scaled Dynamic Type.
/// * Uses a deterministic in‑memory repository seeded with a
///   5‑week hypertrophy mesocycle (no HRV, recovery, or velocity data).
final class PlannerViewSnapshotTests: XCTestCase {
    /// Flip to `true` when updating golden images.
    private let record = false

    override func setUp() {
        super.setUp()
        isRecording = record
        SnapshotTesting.diffTool = "open"
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        throw XCTSkip("Skipping snapshot tests (no reference images present)")
    }

    // MARK: – Public Cases

    func testPlannerView_iPhone15Pro_light() {
        assertPlannerSnapshot(device: .iPhone15Pro, scheme: .light, size: .medium)
    }

    func testPlannerView_iPhone15Pro_dark() {
        assertPlannerSnapshot(device: .iPhone15Pro, scheme: .dark, size: .medium)
    }

    func testPlannerView_iPhoneSE3_light_accessibilityXXL() {
        assertPlannerSnapshot(device: .iPhoneSE3, scheme: .light, size: .accessibilityXXXL)
    }

    // MARK: – Helper

    private func assertPlannerSnapshot(
        device: ViewImageConfig.iOSDevice,
        scheme: ColorScheme,
        size: ContentSizeCategory
    ) {
        let viewModel = PreviewFactory.makeViewModel()

        let root = PlannerView(viewModel: viewModel)
            .environment(\.colorScheme, scheme)
            .environment(\.sizeCategory, size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        assertSnapshot(
            matching: root,
            as: .image(on: device),
            named: "\(device.description)_\(scheme)_\(size)",
            record: record
        )
    }
}

#if DEBUG
// MARK: – Preview Seed Data (Domain‑pure)
private enum PreviewFactory {
    static func makeViewModel() -> PlannerViewModel {
        let repo = InMemoryWorkoutPlanRepository(seed: Seed.mesocycle())
        return PlannerViewModel(repository: repo)
    }
}
#endif
