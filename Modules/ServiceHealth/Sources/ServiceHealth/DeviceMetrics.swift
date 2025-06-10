//  DeviceMetrics.swift
//  ServiceHealth
//
//  Lightweight façade for querying ambient device state that might
//  impact UX decisions—battery, Low Power Mode, free disk, and network
//  reachability.  No HRV, recovery, or velocity metrics are captured.
//
//  • Pure Swift, Conditional compilation for iOS, watchOS, macOS, and visionOS.
//  • Public async API so callers never block UI thread.
//  • Uses modern Combine/async-await where available, avoids Obj-C reachability.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
#if canImport(UIKit)
import UIKit    // for battery and Low Power Mode (iOS, visionOS)
#endif
#if canImport(Network)
import Network // for network reachability (cellular connection status)
#endif

// MARK: - DeviceMetrics (snapshot)

/// Immutable snapshot of current device health parameters.
public struct DeviceMetrics: Sendable {

    public let batteryLevel: Float?         // Battery charge level from 0.0 (empty) to 1.0 (full), or nil if unavailable.
    public let isLowPowerModeEnabled: Bool  // Low Power Mode status (true if enabled).
    public let freeDiskGB: Double           // Available disk space in gigabytes (approximately).
    public let isCellularConnected: Bool?   // Indicates if the device is currently using cellular data (nil if device has no cellular capability).

    /// A human-readable multiline summary of the metrics, useful for debugging (e.g., showing in a debug overlay).
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

/// An actor-backed singleton service that samples device metrics on demand.
/// Use this to get the latest `DeviceMetrics` snapshot in an asynchronous, thread-safe manner.
public actor DeviceMetricsProvider {

    /// Global singleton instance for device metrics.
    public static let shared = DeviceMetricsProvider()

    /// Private initializer to ensure only one instance exists. Enables battery monitoring on supported platforms.
    private init() {
        #if canImport(UIKit)
        // Enable battery monitoring so that UIDevice.current.batteryLevel returns actual values instead of -1.
        UIDevice.current.isBatteryMonitoringEnabled = true
        #endif
    }

    // MARK: Public API

    /// Captures a snapshot of current device metrics (battery, power mode, disk, connectivity).
    /// - Returns: A `DeviceMetrics` struct containing the latest values for battery level, low power mode, free disk space, and cellular connectivity.
    /// - Note: This function is async to avoid blocking the main thread. It always returns a result and never throws.
    public func snapshot() async -> DeviceMetrics {
        // Gather all metrics concurrently (where possible) and return a populated DeviceMetrics.
        return await DeviceMetrics(
            batteryLevel: currentBatteryLevel(),
            isLowPowerModeEnabled: lowPowerMode(),
            freeDiskGB: freeDiskSpaceGB(),
            isCellularConnected: await cellularConnected()
        )
    }

    // MARK: Private helpers

    /// Reads the current battery charge level if available.
    /// - Returns: Battery level as a float (0.0 to 1.0), or nil if battery level is not accessible on this platform or device.
    private func currentBatteryLevel() -> Float? {
        #if canImport(UIKit)
        let level = UIDevice.current.batteryLevel   // This returns -1 if battery level is unavailable (e.g., on simulator or certain devices).
        return level >= 0 ? level : nil
        #else
        // Battery info is not available on platforms without UIKit (e.g., macOS without Catalyst, or watchOS through this code).
        return nil
        #endif
    }

    /// Checks if Low Power Mode is enabled on the device.
    /// - Returns: `true` if Low Power Mode is currently on (iOS only), otherwise `false`.
    private func lowPowerMode() -> Bool {
        #if canImport(UIKit)
        // On iOS (and devices supporting UIKit), use ProcessInfo to detect Low Power Mode.
        return ProcessInfo.processInfo.isLowPowerModeEnabled
        #else
        // Other platforms (watchOS, macOS) either do not support Low Power Mode or have no equivalent, so assume false.
        return false
        #endif
    }

    /// Computes the available free disk space on the device.
    /// - Returns: Free disk space in gigabytes (GB), or 0 if it cannot be determined.
    private func freeDiskSpaceGB() -> Double {
        // NSHomeDirectory gives the path to the app's sandbox (or home directory). We query the file system for available capacity.
        let url = URL(fileURLWithPath: NSHomeDirectory())
        guard
            // Use resourceValues to get the volume's available capacity (for important usage, which excludes space that can be freed by the system).
            let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
            let bytes = values.volumeAvailableCapacityForImportantUsage
        else {
            return 0
        }
        // Convert bytes to gigabytes (1 GB = 2^30 bytes).
        return Double(bytes) / 1_073_741_824
    }

    /// Determines whether the device is currently using a cellular network connection.
    /// - Returns: `true` if on cellular, `false` if on Wi-Fi or no network, or `nil` if the device has no cellular capability.
    /// - Note: This uses `NWPathMonitor` to asynchronously check network status. We wait briefly for the monitor to report the current path status (up to 0.2 seconds).
    private func cellularConnected() async -> Bool? {
        #if canImport(Network)
        let monitor = NWPathMonitor()
        var isCellular: Bool?
        let semaphore = DispatchSemaphore(value: 0)

        monitor.pathUpdateHandler = { path in
            // Determine if the active network interface is cellular.
            isCellular = path.usesInterfaceType(.cellular)
            // Signal that we got the information and stop the monitor.
            semaphore.signal()
            monitor.cancel()
        }
        // Start monitoring on a background thread.
        let queue = DispatchQueue(label: "DeviceMetrics.CellularCheck")
        monitor.start(queue: queue)

        // Wait for a path update or time out after 200 milliseconds.
        _ = semaphore.wait(timeout: .now() + 0.2)
        // If no update was received in time, isCellular will remain nil.
        return isCellular
        #else
        // If the Network framework is not available, we cannot determine cellular status.
        return nil
        #endif
    }
}
