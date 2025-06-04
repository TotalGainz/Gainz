//
//  CoachingDrawerView.swift
//  Features › Planner › Components
//
//  Sliding drawer that surfaces context-aware coaching tips
//  while the athlete is arranging their weekly mesocycle.
//
//  ──────────────────────────────────────────────────────────────
//  • Pure SwiftUI; no UIKit.
//  • Dark-mode first, pulls colors & typography from DesignSystem.
//  • No HRV, recovery, or velocity content—only hypertrophy guidance.
//  • Uses a spring drag gesture for interactive open/close.
//  • Prepared for localisation via SwiftGen `L10n`.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Combine
import DesignSystem     // Color & typography tokens

// MARK: - ViewModel

public final class CoachingDrawerViewModel: ObservableObject {
    @Published public var tips: [String] = []
    @Published public var isOpen: Bool   = false

    private var cancellables = Set<AnyCancellable>()
    private let tipProvider: TipProviderProtocol

    public init(tipProvider: TipProviderProtocol) {
        self.tipProvider = tipProvider
        bind()
    }

    private func bind() {
        tipProvider.tipsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.tips, on: self)
            .store(in: &cancellables)
    }

    public func toggle() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            isOpen.toggle()
        }
    }
}

public protocol TipProviderProtocol {
    var tipsPublisher: AnyPublisher<[String], Never> { get }
}

// MARK: - View

public struct CoachingDrawerView: View {

    @ObservedObject private var viewModel: CoachingDrawerViewModel
    @GestureState private var dragOffset: CGFloat = 0

    // Drawer height when open
    private let openHeight: CGFloat = 240

    public init(viewModel: CoachingDrawerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                handleBar
                tipsList
            }
            .frame(maxWidth: .infinity)
            .frame(height: openHeight, alignment: .top)
            .background(DesignSystem.Color.surfacePrimary)
            .mask(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(DesignSystem.Color.gradientPurple, lineWidth: 1)
            )
            .offset(y: currentOffset(in: geo))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isOpen)
            .gesture(
                dragGesture(in: geo)
            )
            .edgesIgnoringSafeArea(.bottom)
        }
        .accessibility(identifier: "coachingDrawer")
    }

    // MARK: - Sub-views

    private var handleBar: some View {
        Capsule()
            .fill(DesignSystem.Color.onSurfaceSecondary.opacity(0.4))
            .frame(width: 40, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .onTapGesture { viewModel.toggle() }
    }

    private var tipsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.tips, id: \.self) { tip in
                    Text(tip)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Color.onSurfacePrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            DesignSystem.Color.surfaceSecondary.opacity(0.7)
                                .cornerRadius(12)
                        )
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Gesture Handling

    private func dragGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .updating($dragOffset) { value, state, _ in
                let raw = value.translation.height
                state = viewModel.isOpen ? max(raw, 0) : min(raw, 0)
            }
            .onEnded { value in
                let threshold = openHeight / 3
                if viewModel.isOpen {
                    if value.translation.height > threshold { viewModel.isOpen = false }
                } else {
                    if -value.translation.height > threshold { viewModel.isOpen = true }
                }
            }
    }

    private func currentOffset(in geo: GeometryProxy) -> CGFloat {
        let closedY = geo.size.height + 12   // Hidden just off-screen
        let openY   = geo.size.height - openHeight
        let base    = viewModel.isOpen ? openY : closedY
        return base + dragOffset
    }
}

// MARK: - Previews

#if DEBUG
import SwiftUI

struct CoachingDrawerView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = CoachingDrawerViewModel(tipProvider: MockTipProvider())
        vm.tips = [
            "Aim for 8-12 reps at RPE 8 for prime hypertrophy stimulus.",
            "Keep rest to ~90 s on accessory lifts to maximise density.",
            "Progressive overload ≠ add weight every session—use sets or reps too."
        ]
        return ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            CoachingDrawerView(viewModel: vm)
        }
        .preferredColorScheme(.dark)
    }

    private final class MockTipProvider: TipProviderProtocol {
        let tipsPublisher = Just<[String]>([]).eraseToAnyPublisher()
    }
}
#endif
