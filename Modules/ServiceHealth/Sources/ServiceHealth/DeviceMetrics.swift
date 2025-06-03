//
//  DeviceMetrics.swift
//  ServiceHealth
//
//  Lightweight façade for querying ambient device state that might
//  impact UX decisions—battery, Low Power Mode, free disk, and network
//  reachability.  No HRV, recovery, or velocity metrics are captured.
//
//  • Pure Swift, Conditional compilation for iOS vs. watchOS vs. macOS.
//  • Public async API so callers never block UI thread.
//  • Uses modern Combine/async-await where available, avoids Obj-C reachability.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Network)
import Network
#endif

// MARK: - DeviceMetrics (snapshot)

/// Immutable snapshot of current device health parameters.
public struct DeviceMetrics: Sendable {

    public let batteryLevel: Float?         // 0…1, or nil if unavailable
    public let isLowPowerModeEnabled: Bool
    public let freeDiskGB: Double
    public let isCellularConnected: Bool?   // nil on Wi-Fi-only hardware

    /// Friendly description for debug overlays.
    public var debugSummary: String {
        """
        🔋 \(batteryLevel.map { "\($0 * 100)%" } ?? "N/A")  \
        ⚡️ LowPower=\(isLowPowerModeEnabled)  \
        💾 Free=\(String(format: "%.2f", freeDiskGB)) GB  \
        📶 Cellular=\(isCellularConnected.map(\.description) ?? "N/A")
        """
    }
}

// MARK: - DeviceMetricsProvider

/// Actor-backed singleton that samples metrics on demand.
public actor DeviceMetricsProvider {

    public static let shared = DeviceMetricsProvider()

    private init() {
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        #endif
    }

    // MARK: Public API

    /// Returns an up-to-the-millisecond snapshot; never throws.
    public func snapshot() async -> DeviceMetrics {
        await DeviceMetrics(
            batteryLevel: currentBatteryLevel(),
            isLowPowerModeEnabled: lowPowerMode(),
            freeDiskGB: freeDiskSpaceGB(),
            isCellularConnected: await cellularConnected()
        )
    }

    // MARK: Private helpers

    private func currentBatteryLevel() -> Float? {
        #if canImport(UIKit)
        let level = UIDevice.current.batteryLevel   // -1 if unavailable
        return level >= 0 ? level : nil
        #else
        return nil
        #endif
    }

    private func lowPowerMode() -> Bool {
        #if canImport(UIKit)
        ProcessInfo.processInfo.isLowPowerModeEnabled
        #else
        return false
        #endif
    }

    private func freeDiskSpaceGB() -> Double {
        let url = URL(fileURLWithPath: NSHomeDirectory() as String)
        guard
            let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
            let bytes = values.volumeAvailableCapacityForImportantUsage
        else { return 0 }
        return Double(bytes) / 1_073_741_824 // GiB
    }

    private func cellularConnected() async -> Bool? {
        #if canImport(Network)
        let monitor = NWPathMonitor()
        var isCellular: Bool?
        let semaphore = DispatchSemaphore(value: 0)

        monitor.pathUpdateHandler = { path in
            isCellular = path.usesInterfaceType(.cellular)
            semaphore.signal()
            monitor.cancel()
        }
        let queue = DispatchQueue(label: "DeviceMetrics.Cellular")
        monitor.start(queue: queue)

        // Wait max 200 ms for first callback
        _ = semaphore.wait(timeout: .now() + 0.2)
        return isCellular
        #else
        return nil
        #endif
    }
}

// MARK: - Preview Debug (SwiftUI live overlay)
//
// struct MetricsPreview: View {
//     @State private var metrics: DeviceMetrics = .init(
//         batteryLevel: nil, isLowPowerModeEnabled: false,
//         freeDiskGB: 0, isCellularConnected: nil
//     )
//
//     var body: some View {
//         Text(metrics.debugSummary)
//             .monospaced()
//             .task {
//                 metrics = await DeviceMetricsProvider.shared.snapshot()
//             }
//     }
// }
