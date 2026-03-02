import SwiftUI

// MARK: - Game Tab

/// The five tabs in the bottom navigation bar.
/// Mirrors LEFT_TABS + center "game" + RIGHT_TABS from GameScreen.jsx.
enum GameTab: String, CaseIterable {
    case karma
    case stats
    case play
    case profile
    case log

    var emoji: String {
        switch self {
        case .karma:   return "\u{2638}\u{FE0F}"  // ☸️
        case .stats:   return "\u{1F4CA}"          // 📊
        case .play:    return "\u{25B6}\u{FE0F}"   // ▶️
        case .profile: return "\u{1F464}"          // 👤
        case .log:     return "\u{1F4DC}"          // 📜
        }
    }

    var label: String {
        switch self {
        case .karma:   return "Karma"
        case .stats:   return "Stats"
        case .play:    return "Play"
        case .profile: return "Profile"
        case .log:     return "Log"
        }
    }
}

// MARK: - CustomTabBar

/// A custom bottom tab bar that replicates the GameScreen.jsx <nav> section.
/// Five tabs in an HStack — the center "Play" tab is a raised circular button
/// with saffron-gold fill, offset upward above the bar.
struct CustomTabBar: View {

    @Binding var activeTab: GameTab

    /// Tabs to the left of the center button.
    private let leftTabs: [GameTab] = [.karma, .stats]
    /// Tabs to the right of the center button.
    private let rightTabs: [GameTab] = [.profile, .log]

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // Left tabs
            ForEach(leftTabs, id: \.self) { tab in
                tabButton(for: tab)
            }

            // Center raised Play button
            centerPlayButton

            // Right tabs
            ForEach(rightTabs, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(height: 1)
                Color.white
            }
        )
    }

    // MARK: - Tab Button

    private func tabButton(for tab: GameTab) -> some View {
        let isActive = activeTab == tab

        return Button {
            activeTab = tab
        } label: {
            VStack(spacing: 2) {
                Text(tab.emoji)
                    .font(.system(size: 22))

                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isActive ? Color.accentColor : Color(uiColor: .systemGray))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Center Play Button

    private var centerPlayButton: some View {
        let isActive = activeTab == .play

        return Button {
            activeTab = .play
        } label: {
            Text(GameTab.play.emoji)
                .font(.system(size: 24))
                // Brighten the emoji when active to match the JS filter: brightness(10)
                .brightness(isActive ? 0.5 : 0)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(isActive ? Color.accentColor : Color(uiColor: .systemGray6))
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            isActive
                                ? Color.accentColor.opacity(0.8)
                                : Color(uiColor: .systemGray5),
                            lineWidth: 3
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .offset(y: -20)
        // Prevent the offset from shrinking the HStack allocation
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        CustomTabBar(activeTab: .constant(.play))
    }
}
