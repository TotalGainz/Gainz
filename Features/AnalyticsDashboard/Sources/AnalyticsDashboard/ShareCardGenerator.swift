//  ShareCardGenerator.swift
//  Gainz – AnalyticsDashboard Feature
//
//  Provides functionality to create a branded progress share card image and present it via the iOS share sheet.
//  Renders an off-screen SwiftUI view to UIImage (ImageRenderer on iOS 16+, UIGraphics fallback on earlier versions).
//  Wraps UIActivityViewController in a SwiftUI representable for easy integration in the app.
//

import SwiftUI
import UIKit

// MARK: - Share Card Payload Model

/// Data payload for generating a shareable progress card.
public struct ShareCardPayload: Identifiable, Sendable, Equatable {
    public let id: UUID = UUID()
    public let headline: String        // e.g. "5-Lift Total 1020 kg"
    public let subheadline: String     // e.g. "You're in the Top 3%!"
    public let avatarURL: URL?         // Optional URL for user's avatar image.
    public let metricRows: [Metric]    // List of metrics (name/value pairs) to display.

    /// A name-value pair metric on the share card.
    public struct Metric: Sendable, Equatable {
        public let name: String       // Metric name (e.g., "Squat").
        public let value: String      // Metric value (e.g., "405 lb").
        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }

    public init(headline: String,
                subheadline: String,
                avatarURL: URL? = nil,
                metricRows: [Metric]) {
        self.headline = headline
        self.subheadline = subheadline
        self.avatarURL = avatarURL
        self.metricRows = metricRows
    }

    public static func ==(lhs: ShareCardPayload, rhs: ShareCardPayload) -> Bool {
        // Equate payloads by content (ignore id differences).
        return lhs.headline == rhs.headline &&
               lhs.subheadline == rhs.subheadline &&
               lhs.avatarURL == rhs.avatarURL &&
               lhs.metricRows == rhs.metricRows
    }
}

// MARK: - Share Card Generator

public enum ShareCardGenerator {

    /// Creates a share sheet view (UIActivityViewController) containing the generated card image.
    public static func makeShareSheet(for payload: ShareCardPayload) -> some View {
        let image = Self.render(payload: payload)
        return ActivityView(activityItems: [image])
    }

    /// Renders the share card SwiftUI view off-screen to a `UIImage`.
    public static func render(payload: ShareCardPayload,
                              scale: CGFloat = UIScreen.main.scale) -> UIImage {
        let view = ShareCardView(payload: payload)
        // Use ImageRenderer on iOS 16+ for higher fidelity.
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = scale
            return renderer.uiImage ?? UIImage()
        }
        // Fallback for iOS 15 and earlier using UIKit.
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: CGSize(width: 512, height: 640))
        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - Share Card SwiftUI Layout

private struct ShareCardView: View {
    let payload: ShareCardPayload

    var body: some View {
        VStack(spacing: 20) {
            // User avatar (if available).
            if let url = payload.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Image(systemName: "person.fill")
                            .resizable().scaledToFit()
                            .padding(24)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .shadow(radius: 5)
            }

            // Headline and subheadline text.
            Text(payload.headline)
                .font(.title2.weight(.bold))
            Text(payload.subheadline)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider().padding(.horizontal, 24)

            // Metric rows (name and value pairs).
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(payload.metricRows.enumerated()), id: \.offset) { index, metric in
                    HStack {
                        Text(metric.name).fontWeight(.semibold)
                        Spacer()
                        Text(metric.value).monospacedDigit()
                    }
                    if index < payload.metricRows.count - 1 {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.secondary.opacity(0.15))
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [
                Color(red: 0.64, green: 0.28, blue: 1.0),
                Color(red: 0.23, green: 0.21, blue: 0.35)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(24)
    }
}

// MARK: - Share Sheet Wrapper (UIKit Integration)

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.excludedActivityTypes = [.saveToCameraRoll]
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update dynamically.
    }
}

/* Developer Notes:
   - UIActivityViewController automatically surfaces installed social apps for sharing.
   - The rendered PNG (~512x640 @3x) is approximately 500 KB.
   - Using ImageRenderer yields crisp text; older fallback rasterizes but remains acceptable.
   - This approach follows common best practices from StackOverflow and Apple documentation.
   - A context menu or copy action could be added to allow copying the image or text if needed.
*/
