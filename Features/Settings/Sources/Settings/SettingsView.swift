//  SettingsView.swift
//  Gainz – Settings Feature
//
//  Created by AI Auto-Generated on 2025-06-04.
//  SwiftUI settings screen leveraging Form, @AppStorage and dependency injection.
//
//  Implementation references SwiftUI Form best practices  [oai_citation:0‡developer.apple.com](https://developer.apple.com/documentation/swiftui/form?utm_source=chatgpt.com),
//  Apple HIG Toggles guidelines  [oai_citation:1‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/toggles?utm_source=chatgpt.com),
//  @AppStorage usage articles  [oai_citation:2‡medium.com](https://medium.com/%40ramdhas/mastering-swiftui-best-practices-for-efficient-user-preference-management-with-appstorage-cf088f4ca90c?utm_source=chatgpt.com) [oai_citation:3‡avanderlee.com](https://www.avanderlee.com/swift/appstorage-explained/?utm_source=chatgpt.com),
//  persistent settings tutorial  [oai_citation:4‡holyswift.app](https://holyswift.app/using-userdefaults-to-persist-in-swiftui/?utm_source=chatgpt.com),
//  list/section grouping docs  [oai_citation:5‡developer.apple.com](https://developer.apple.com/documentation/swiftui/list?utm_source=chatgpt.com),
//  custom property wrapper exploration  [oai_citation:6‡fatbobman.com](https://fatbobman.com/en/posts/exploring-swiftui-property-wrappers-2/?utm_source=chatgpt.com),
//  view styles reference  [oai_citation:7‡developer.apple.com](https://developer.apple.com/documentation/swiftui/view-styles?utm_source=chatgpt.com),
//  sample list-navigation patterns  [oai_citation:8‡developer.apple.com](https://developer.apple.com/tutorials/swiftui/building-lists-and-navigation?utm_source=chatgpt.com),
//  SwiftUI form tutorial  [oai_citation:9‡medium.com](https://medium.com/%40sharma17krups/swiftui-form-tutorial-how-to-create-settings-screen-using-form-part-1-8e8e80cf584e?utm_source=chatgpt.com),
//  comprehensive settings page guide  [oai_citation:10‡csdiaries.hashnode.dev](https://csdiaries.hashnode.dev/the-ultimate-guide-to-designing-and-creating-a-stunning-settings-page-for-your-ios-app-with-swift-c52fe27e337b?utm_source=chatgpt.com).
//  NOTE: No HRV or Velocity Tracking features are included by design.

import SwiftUI
import DesignSystem
import CoreUI

// MARK: - Settings Keys

private enum SettingsKey: String {
    case darkModeEnabled
    case hapticsEnabled
    case notificationsEnabled
}

// MARK: - SettingsView

@MainActor
public struct SettingsView: View {
    // Persisted user preferences using @AppStorage for automatic state syncing
    @AppStorage(SettingsKey.darkModeEnabled.rawValue) private var darkModeEnabled: Bool = false
    @AppStorage(SettingsKey.hapticsEnabled.rawValue) private var hapticsEnabled: Bool = true
    @AppStorage(SettingsKey.notificationsEnabled.rawValue) private var notificationsEnabled: Bool = true

    // Environment value to dismiss the view when presented modally
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                feedbackSection
                aboutSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            // Apply brand-specific styling
            .tint(DesignSystem.Colors.phoenixAccent)
            .scrollContentBackground(.hidden)    // Provides translucent grouped background
            .background(DesignSystem.Colors.surface.ignoresSafeArea())
        }
    }

    // MARK: - Private Sections

    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Toggle(isOn: $darkModeEnabled) {
                Label("Dark Mode", systemImage: "moon.fill")
            }
            .onChange(of: darkModeEnabled) { isOn in
                // Forward preference to system/UI kit bridge
                CoreUI.AppearanceManager.shared.setDarkMode(isOn)
            }
        }
    }

    private var feedbackSection: some View {
        Section(header: Text("Feedback")) {
            Toggle(isOn: $hapticsEnabled) {
                Label("Haptics", systemImage: "wave.3.right.circle.fill")
            }
            .onChange(of: hapticsEnabled) { isOn in
                CoreUI.FeedbackManager.shared.hapticsEnabled = isOn
            }

            Toggle(isOn: $notificationsEnabled) {
                Label("Push Notifications", systemImage: "bell.badge.fill")
            }
            .onChange(of: notificationsEnabled) { isOn in
                CoreUI.FeedbackManager.shared.notificationsEnabled = isOn
            }
        }
    }

    private var aboutSection: some View {
        Section(header: Text("About")) {
            NavigationLink {
                LicenseListView()
            } label: {
                Label("Open Source Licenses", systemImage: "doc.append")
            }

            Button {
                // Simple in-app share sheet for feedback
                presentSupportMail()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }

            HStack {
                Label("Version", systemImage: "number")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "—"
    }

    private func presentSupportMail() {
        guard let url = URL(string: "mailto:support@gainz.app") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Settings")
}
