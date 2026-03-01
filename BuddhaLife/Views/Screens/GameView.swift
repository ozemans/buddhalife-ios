import SwiftUI

// MARK: - GameView
//
// Ports GameScreen.jsx — the main game screen with:
// 1. A sticky saffron-gold header bar (character name + age, sound toggle, encyclopedia)
// 2. A scrollable content area that swaps based on the active tab
// 3. A custom bottom tab bar via .safeAreaInset(edge: .bottom)
//
// Tab content mapping:
//   .karma   → KarmaVisualizerView
//   .stats   → StatsPanelView
//   .play    → AgeAdvanceView (idle) or EventCardView (active event)
//   .profile → ProfileView
//   .log     → TimelineView

struct GameView: View {

    @Bindable var engine: GameEngine

    @State private var activeTab: GameTab = .play
    @State private var showEncyclopedia: Bool = false

    // MARK: - Derived State

    private var avatar: String {
        avatarEmoji(age: engine.character.age, gender: engine.character.gender)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Sticky header bar
            headerBar

            // Scrollable content area
            ScrollView {
                contentForActiveTab
                    .padding(16)
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom) {
            CustomTabBar(activeTab: $activeTab)
        }
        .background(Color.white)
        // Auto-switch to .play tab when an event triggers
        .onChange(of: engine.currentEvent) { oldValue, newValue in
            if oldValue == nil, newValue != nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeTab = .play
                }
            }
        }
        .sheet(isPresented: $showEncyclopedia) {
            EncyclopediaView()
        }
    }

    // MARK: - Header Bar

    /// Saffron-gold header — character name + age on left, sound toggle + encyclopedia on right.
    /// Tapping the header switches back to the .play tab (mirrors handleHeaderClick).
    private var headerBar: some View {
        HStack {
            // Left: avatar + name
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeTab = .play
                }
            } label: {
                HStack(spacing: 10) {
                    Text(avatar)
                        .font(.system(size: 24))

                    Text(engine.character.name.isEmpty ? "Unknown" : engine.character.name)
                        .font(.system(size: 18, weight: .semibold))
                        .tracking(-0.36)
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Right: age + sound toggle + encyclopedia
            HStack(spacing: 12) {
                Text("Age: \(engine.character.age)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                SoundToggleView()

                // Encyclopedia button
                Button {
                    showEncyclopedia = true
                } label: {
                    Text("\u{1F4D6}") // 📖
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .background(Color.accentColor)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var contentForActiveTab: some View {
        switch activeTab {
        case .karma:
            KarmaVisualizerView(karma: engine.karma)
                .padding(.vertical, 16)

        case .stats:
            StatsPanelView(stats: engine.stats)
                .padding(.vertical, 16)

        case .play:
            if let event = engine.currentEvent {
                EventCardView(event: event, engine: engine)
                    .id(event.id)
            } else {
                AgeAdvanceView(engine: engine)
            }

        case .profile:
            ProfileView(engine: engine)

        case .log:
            TimelineView(lifeEvents: engine.lifeEvents)
                .padding(.vertical, 16)
        }
    }
}

// MARK: - Preview

#Preview {
    GameView(engine: GameEngine())
}
