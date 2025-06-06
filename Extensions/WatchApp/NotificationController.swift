//
//  NotificationController.swift
//  Gainz • WatchApp
//
//  Presents custom long-look notifications using SwiftUI. Implements
//  WKUserNotificationHostingController per Apple’s guidelines. :contentReference[oaicite:0]{index=0}
/*  ▸ Displays rest-timer or coaching nudges sent from iOS. All data are
      conveyed in UNNotificationContent, so we avoid heavy data fetches. :contentReference[oaicite:1]{index=1}
    ▸ Follows the watchOS tutorial pattern—separate NotificationView struct
      for declarative UI. :contentReference[oaicite:2]{index=2}
    ▸ No HRV or bar-velocity metrics are used, per brand constraints.
    ▸ SwiftUI notifications require overriding `body` and `didReceive`. :contentReference[oaicite:3]{index=3}
    ▸ Supports dynamic long-look; short-look relies on system summary. :contentReference[oaicite:4]{index=4}
    ▸ Generated as part of Gainz v8 repo “WatchApp/NotificationController.swift”.
      Reference sample code & forum clarifications. :contentReference[oaicite:5]{index=5}
*/

import SwiftUI
import UserNotifications
import WatchKit
import CoreUI              // ColorPalette for brand accent

// MARK: – SwiftUI View

/// Minimal, brand-consistent layout for a rest or coaching notification.
struct NotificationView: View {
    let title: String
    let message: String
    let accent: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(accent)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.bar)                   // blurred material for depth
    }
}

// MARK: – Hosting Controller

final class NotificationController: WKUserNotificationHostingController<NotificationView> {
    
    // MARK: Internal State
    private var titleText   = "Gainz Reminder"
    private var messageText = "Time for your next set."
    
    // MARK: Body
    override var body: NotificationView {
        NotificationView(title: titleText,
                         message: messageText,
                         accent: ColorPalette.accent)
    }
    
    // MARK: Notification Handling
    override func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        titleText   = content.title.isEmpty ? "Gainz" : content.title
        messageText = content.body.isEmpty  ? "Let's keep pushing!" : content.body
        // Refresh the SwiftUI hierarchy
        setNeedsBodyLayout()
    }
}
