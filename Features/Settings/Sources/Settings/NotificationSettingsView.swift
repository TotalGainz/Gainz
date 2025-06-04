//
//  NotificationSettingsView.swift
//  Gainz – Settings Feature
//
//  SUMMARY: A SwiftUI Form that (1) displays the current push-notification
//  authorization state; (2) lets people request permission via
//  `UNUserNotificationCenter`; and (3) deep-links to the system’s
//  per-app notification page using `UIApplication.openNotificationSettingsURLString`.
//  The UI follows Apple’s HIG for toggles, forms, and notification
//  consent flows.  [oai_citation:0‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/notifications?utm_source=chatgpt.com) [oai_citation:1‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/toggles?utm_source=chatgpt.com)
//
//  ## Key Points
//  • Uses Combine to refresh status whenever the app becomes active.  [oai_citation:2‡mikegopsill.com](https://www.mikegopsill.com/posts/combine-publishers/?utm_source=chatgpt.com) [oai_citation:3‡stackoverflow.com](https://stackoverflow.com/questions/61000353/using-combine-to-trigger-download-on-app-activation-not-compiling?utm_source=chatgpt.com)
//  • Requests alerts, sounds, and badges in a single call.  [oai_citation:4‡holyswift.app](https://holyswift.app/push-notifications-options-in-swiftui/?utm_source=chatgpt.com) [oai_citation:5‡developer.apple.com](https://developer.apple.com/documentation/usernotifications?utm_source=chatgpt.com) [oai_citation:6‡developer.apple.com](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications?utm_source=chatgpt.com)
//  • Deep-links to Settings with `openNotificationSettingsURLString`.  [oai_citation:7‡developer.apple.com](https://developer.apple.com/documentation/uikit/uiapplication/opennotificationsettingsurlstring?utm_source=chatgpt.com) [oai_citation:8‡stackoverflow.com](https://stackoverflow.com/questions/74548628/how-to-open-apps-notification-settings-in-settings-app-swift-ios?utm_source=chatgpt.com) [oai_citation:9‡developer.apple.com](https://developer.apple.com/documentation/uikit/uiapplication/opensettingsurlstring?language=objc&utm_source=chatgpt.com)
//  • No HRV or velocity-tracking logic is present by scope.
//
//  ## References
//  Apple HIG – Notifications  [oai_citation:10‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/notifications?utm_source=chatgpt.com)
//  Toggles HIG  [oai_citation:11‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/toggles?utm_source=chatgpt.com)
//  UNUserNotificationCenter API  [oai_citation:12‡developer.apple.com](https://developer.apple.com/documentation/usernotifications?utm_source=chatgpt.com)
//  iOS 18 Priority Notifications (context)  [oai_citation:13‡theverge.com](https://www.theverge.com/news/617534/ios-18-4-developer-beta-default-navigation-news-plus-food?utm_source=chatgpt.com)
//
//  Created by AI Auto-Generated on 2025-06-04.
//

import SwiftUI
import UserNotifications
import Combine
import DesignSystem

@MainActor
public struct NotificationSettingsView: View {

    // MARK: - State
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var alertPresented = false

    // Combine token to monitor app-active events
    private let didBecomeActive = NotificationCenter.default
        .publisher(for: UIApplication.didBecomeActiveNotification)
    @State private var cancellable: AnyCancellable?

    public init() {}

    // MARK: - Body
    public var body: some View {
        Form {
            Section {
                HStack {
                    Label("Permission Status", systemImage: statusIcon)
                    Spacer()
                    Text(statusText)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .none) {
                    requestAuthorization()
                } label: {
                    Text(authorizationStatus == .authorized ? "Re-request Permission" : "Enable Notifications")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(authorizationStatus == .authorized)

                Button("Open System Settings") {
                    openSystemSettings()
                }
            } footer: {
                Text("Gainz uses notifications only for workout reminders and important account alerts.")
            }
        }
        .navigationTitle("Notification Settings")
        .onAppear {
            fetchAuthorizationStatus()
            observeAppActive()
        }
        .onDisappear {
            cancellable?.cancel()
        }
        .alert("Notifications Disabled",
               isPresented: $alertPresented,
               actions: {
                   Button("OK", role: .cancel) { }
               },
               message: {
                   Text("Enable notifications in Settings to receive workout reminders.")
               })
        // Brand styling
        .tint(DesignSystem.Colors.phoenixAccent)
    }

    // MARK: - Helpers

    private var statusIcon: String {
        switch authorizationStatus {
        case .authorized:       "bell.fill"
        case .denied:           "bell.slash.fill"
        case .provisional:      "bell.badge.fill"
        default:                "bell"
        }
    }

    private var statusText: String {
        switch authorizationStatus {
        case .authorized:       "On"
        case .denied:           "Off"
        case .provisional:      "Provisional"
        case .ephemeral:        "Ephemeral"
        default:                "Unknown"
        }
    }

    private func fetchAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                authorizationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                Task { @MainActor in
                    fetchAuthorizationStatus()
                    if !granted { alertPresented = true }
                }
            }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func observeAppActive() {
        cancellable = didBecomeActive
            .sink { _ in fetchAuthorizationStatus() }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
