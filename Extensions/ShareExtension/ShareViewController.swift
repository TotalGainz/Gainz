//
//  ShareViewController.swift
//  Gainz • ShareExtension
//
//  Receives text / URL / image from the system share sheet, shows a lightweight
//  SwiftUI confirmation, then persists the content via CorePersistence and
//  dismisses. No HRV or velocity tracking.
//  © 2025 Echelon Commerce LLC. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import UniformTypeIdentifiers
import CorePersistence          // DatabaseManager for saving share content

// MARK: – Root UIViewController bridging into SwiftUI

final class ShareViewController: UIViewController {
    
    // State object propagated into SwiftUI view
    private let vm = ShareViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Build HostingController
        let host = UIHostingController(rootView: ShareView(vm: vm))
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        
        // Load attachments
        collectAttachments()
        
        // Observe completion
        vm.$didFinish
            .compactMap { $0 }
            .sink { [weak self] success in
                self?.finish(success: success)
            }
            .store(in: &cancellables)
    }
    
    // MARK: – Attachment Harvesting
    
    private func collectAttachments() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        vm.load(attachments: items.flatMap { $0.attachments ?? [] })
    }
    
    // MARK: – Finish & Dismiss
    
    private func finish(success: Bool) {
        // Notify host app that work is done
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

// MARK: – ViewModel

final class ShareViewModel: ObservableObject {
    @Published var attachments: [SharedAttachment] = []
    @Published var didFinish: Bool? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    func load(attachments providers: [NSItemProvider]) {
        let group = DispatchGroup()
        var results: [SharedAttachment] = []
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    if let url = item as? URL {
                        results.append(.url(url))
                    }
                    group.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                    if let text = item as? String {
                        results.append(.text(text))
                    }
                    group.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                    if let url = item as? URL {
                        results.append(.image(url))
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.attachments = results
        }
    }
    
    func importToGainz() {
        // Persist via shared database
        for att in attachments {
            switch att {
            case .url(let url):   DatabaseManager.shared.saveSharedURL(url)
            case .text(let txt):  DatabaseManager.shared.saveSharedNote(txt)
            case .image(let url): DatabaseManager.shared.saveSharedImage(at: url)
            }
        }
        didFinish = true
    }
}

// MARK: – SwiftUI UI

private struct ShareView: View {
    @ObservedObject var vm: ShareViewModel
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.attachments) { att in
                    HStack {
                        att.icon
                            .font(.title2)
                            .foregroundStyle(.accent)
                        Text(att.description)
                            .font(.body)
                    }
                }
            }
            .navigationTitle("Import to Gainz")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { vm.importToGainz() }
                        .disabled(vm.attachments.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.didFinish = false }
                }
            }
        }
    }
}

// MARK: – SharedAttachment

private enum SharedAttachment: Identifiable {
    var id: UUID { UUID() }
    case url(URL)
    case text(String)
    case image(URL)
    
    var icon: Image {
        switch self {
        case .url:   return Image(systemName: "link.circle.fill")
        case .text:  return Image(systemName: "textformat")
        case .image: return Image(systemName: "photo.on.rectangle")
        }
    }
    
    var description: String {
        switch self {
        case .url(let url):   return url.absoluteString
        case .text(let txt):  return txt
        case .image:          return "Image"
        }
    }
}
