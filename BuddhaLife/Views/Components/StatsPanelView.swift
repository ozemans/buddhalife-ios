import SwiftUI

// MARK: - Stat Configuration

/// Maps each stat to its display properties, matching STAT_CONFIG from StatsPanel.jsx.
private struct StatConfig: Identifiable {
    let id: String
    let keyPath: KeyPath<Stats, Int>
    let label: String
    let emoji: String
    let color: Color
    let maxValue: Int
}

private let statConfigs: [StatConfig] = [
    StatConfig(id: "health",         keyPath: \.health,         label: "Health",    emoji: "\u{2764}\u{FE0F}", color: Color(red: 1.0, green: 0.231, blue: 0.188),   maxValue: 100),
    StatConfig(id: "happiness",      keyPath: \.happiness,      label: "Happiness", emoji: "\u{1F60A}",        color: Color(red: 1.0, green: 0.800, blue: 0.0),     maxValue: 100),
    StatConfig(id: "wealth",         keyPath: \.wealth,         label: "Wealth",    emoji: "\u{1F4B0}",        color: Color(red: 0.204, green: 0.780, blue: 0.349), maxValue: 200),
    StatConfig(id: "wisdom",         keyPath: \.wisdom,         label: "Wisdom",    emoji: "\u{1F9E0}",        color: Color(red: 0.0, green: 0.478, blue: 1.0),     maxValue: 100),
    StatConfig(id: "socialStanding", keyPath: \.socialStanding, label: "Social",    emoji: "\u{1F465}",        color: Color(red: 0.686, green: 0.322, blue: 0.871), maxValue: 100),
    StatConfig(id: "spiritualDev",   keyPath: \.spiritualDev,   label: "Spiritual", emoji: "\u{1F64F}",        color: Color(red: 0.910, green: 0.588, blue: 0.047), maxValue: 100),
]

// MARK: - StatsPanelView

struct StatsPanelView: View {
    let stats: Stats

    var body: some View {
        VStack(spacing: 16) {
            ForEach(statConfigs) { config in
                statRow(config: config)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    // MARK: - Individual Stat Row

    private func statRow(config: StatConfig) -> some View {
        let rawValue = stats[keyPath: config.keyPath]
        let clampedValue = max(0, min(config.maxValue, rawValue))
        let fraction = Double(clampedValue) / Double(config.maxValue)

        return VStack(spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Text(config.emoji)
                        .font(.system(size: 18))
                    Text(config.label)
                        .font(.system(size: 14))
                        .foregroundStyle(Color("TextPrimary"))
                }

                Spacer()

                Text("\(clampedValue)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("TextPrimary"))
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // Fill
                    Capsule()
                        .fill(config.color)
                        .frame(width: geometry.size.width * fraction, height: 8)
                        .animation(.easeOut(duration: 0.5), value: clampedValue)
                }
            }
            .frame(height: 8)
        }
    }
}
