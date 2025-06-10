// CoachingDrawerView.swift

import SwiftUI
import Combine
import DesignSystem     // Color & typography tokens

// MARK: - ViewModel

/// ViewModel for the coaching tips drawer, managing tip content and open/close state.
public final class CoachingDrawerViewModel: ObservableObject {
    @Published public var tips: [String] = []
    @Published public var isOpen: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let tipProvider: TipProviderProtocol

    public init(tipProvider: TipProviderProtocol) {
        self.tipProvider = tipProvider
        bind()
    }

    private func bind() {
        // Subscribe to the provider's tips stream and update our tips.
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

/// A sliding drawer view that displays context-aware coaching tips during mesocycle planning.
public struct CoachingDrawerView: View {
    @ObservedObject private var viewModel: CoachingDrawerViewModel
    @GestureState private var dragOffset: CGFloat = 0

    // Drawer height when fully open
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
        .accessibilityIdentifier("coachingDrawer")
    }

    // MARK: - Sub-views

    // The draggable handle bar at the top of the drawer
    private var handleBar: some View {
        Capsule()
            .fill(DesignSystem.Color.onSurfaceSecondary.opacity(0.4))
            .frame(width: 40, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .onTapGesture { viewModel.toggle() }
    }

    // List of coaching tips
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
                let dragAmount = value.translation.height
                // Allow dragging down when open, or dragging up when closed
                state = viewModel.isOpen ? max(dragAmount, 0) : min(dragAmount, 0)
            }
            .onEnded { value in
                let threshold = openHeight / 3
                if viewModel.isOpen {
                    // If dragged down beyond threshold, close the drawer
                    if value.translation.height > threshold {
                        viewModel.isOpen = false
                    }
                } else {
                    // If dragged up beyond threshold, open the drawer
                    if -value.translation.height > threshold {
                        viewModel.isOpen = true
                    }
                }
            }
    }

    private func currentOffset(in geo: GeometryProxy) -> CGFloat {
        // Closed position just off the bottom of the screen
        let closedY = geo.size.height + 12
        // Open position: drawer's top aligned at desired height from bottom
        let openY = geo.size.height - openHeight
        // Base offset depending on open/closed state, plus any drag offset
        let baseY = viewModel.isOpen ? openY : closedY
        return baseY + dragOffset
    }
}

// MARK: - Previews

#if DEBUG
private final class MockTipProvider: TipProviderProtocol {
    let tipsPublisher = Just<[String]>([
        "Aim for 8-12 reps at RPE 8 for optimal hypertrophy.",
        "Keep rest ~90s on accessory lifts for more density.",
        "Progressive overload: add weight, or sets, or reps gradually."
    ]).eraseToAnyPublisher()
}

struct CoachingDrawerView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = CoachingDrawerViewModel(tipProvider: MockTipProvider())
        vm.isOpen = true
        return ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            CoachingDrawerView(viewModel: vm)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
