//
//  ExtensionDelegate.swift
//  Gainz • WatchAppExtension
//
//  WKExtensionDelegate manages life-cycle events, background refresh,
//  complication reloads, and Watch Connectivity for Gainz on watchOS.
//  No HRV or velocity logic is included.
//
//  © 2025 Echelon Commerce LLC. All rights reserved.
//

import WatchKit
import ClockKit
import WatchConnectivity
import UserNotifications
import CorePersistence   // DatabaseManager for workout / streak data

// MARK: – Extension Delegate

final class ExtensionDelegate: NSObject,
                               WKExtensionDelegate,
                               WCSessionDelegate {
    
    private let db       = DatabaseManager.shared
    private let server   = CLKComplicationServer.sharedInstance()
    private var session: WCSession? {
        WCSession.isSupported() ? .default : nil
    }
    
    // MARK: Launch
    
    func applicationDidFinishLaunching() {
        // Activate Watch Connectivity for data sync with iOS app. :contentReference[oaicite:0]{index=0}
        session?.delegate = self
        session?.activate()
        UNUserNotificationCenter.current().delegate = self
        scheduleNextBackgroundRefresh()
    }
    
    // MARK: Foreground
    
    func applicationDidBecomeActive() {
        // Reload complications when app returns to foreground. :contentReference[oaicite:1]{index=1}
        refreshComplications()
    }
    
    func applicationWillResignActive() { }
    
    // MARK: Background Tasks
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Iterate through tasks; complete each appropriately. :contentReference[oaicite:2]{index=2}
        for task in backgroundTasks {
            switch task {
            case let refresh as WKApplicationRefreshBackgroundTask:
                updateDataAndComplications()
                scheduleNextBackgroundRefresh()
                refresh.setTaskCompletedWithSnapshot(false)
                
            case let snapshot as WKSnapshotRefreshBackgroundTask:
                snapshot.setTaskCompleted(restoredDefaultState: true,
                                          estimatedSnapshotExpiration: .distantFuture,
                                          userInfo: nil)
                
            case let urlSession as WKURLSessionRefreshBackgroundTask:
                urlSession.setTaskCompletedWithSnapshot(false)
                
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    // MARK: Connectivity
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if activationState == .activated { refreshComplications() }
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any]) {
        // Minimal message bridge—for example, “logSet” updates. :contentReference[oaicite:3]{index=3}
        if message["action"] as? String == "dataUpdated" {
            updateDataAndComplications()
        }
    }
    
    // MARK: Helpers
    
    private func scheduleNextBackgroundRefresh() {
        // Request refresh ~30 min ahead to keep complications timely. :contentReference[oaicite:4]{index=4}
        let target = Date(timeIntervalSinceNow: 1_800)
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: target,
            userInfo: nil) { _ in }
    }
    
    private func updateDataAndComplications() {
        db.refreshTodayCache() // lightweight pull from persistent store
        refreshComplications()
    }
    
    private func refreshComplications() {
        guard let comps = server.activeComplications else { return }
        for comp in comps {
            server.reloadTimeline(for: comp) // prompts template regeneration :contentReference[oaicite:5]{index=5}
        }
    }
}

// MARK: – Notification Delegate (opt-in)

extension ExtensionDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
                                -> UNNotificationPresentationOptions {
        // Always show banner on wrist for coaching nudges. :contentReference[oaicite:6]{index=6}
        return [.banner, .sound]
    }
}
