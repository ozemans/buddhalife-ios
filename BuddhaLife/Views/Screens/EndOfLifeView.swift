import SwiftUI

// MARK: - Rebirth Prognosis

private struct RebirthTeaser {
    let text: String
    let emoji: String
}

private func getRebirthTeaser(karmaScore: Int) -> RebirthTeaser {
    if karmaScore >= 80 {
        return RebirthTeaser(
            text: "Your accumulated merit radiates like the sun. A most fortunate rebirth awaits — perhaps even a heavenly realm, or a life destined for awakening.",
            emoji: "\u{1F31F}" // star
        )
    }
    if karmaScore >= 60 {
        return RebirthTeaser(
            text: "A life of virtue and generosity. Your good karma suggests a fortunate human rebirth, blessed with opportunity and wisdom.",
            emoji: "\u{1FAB7}" // lotus
        )
    }
    if karmaScore >= 40 {
        return RebirthTeaser(
            text: "A balanced life, neither burdened by great demerit nor elevated by great merit. The wheel turns, and another chance to grow awaits.",
            emoji: "\u{2638}\u{FE0F}" // dharma wheel
        )
    }
    if karmaScore >= 20 {
        return RebirthTeaser(
            text: "The weight of unskillful actions lingers. Yet even in difficulty, the seed of awakening remains. May the next life bring greater mindfulness.",
            emoji: "\u{1F331}" // seedling
        )
    }
    return RebirthTeaser(
        text: "A life heavy with demerit, far from the path of liberation. But even the most tangled karma can be unwound through sincere effort in lives to come.",
        emoji: "\u{1F311}" // new moon
    )
}

// MARK: - Event Emoji Helper

private let eventEmojiMap: [String: String] = [
    "spiritual": "\u{1F64F}",   // folded hands
    "financial": "\u{1F4B0}",   // money bag
    "relationship": "\u{2764}\u{FE0F}", // red heart
    "health": "\u{1F3E5}",      // hospital
    "education": "\u{1F4DA}",   // books
    "moral": "\u{2696}\u{FE0F}", // scales
    "festival": "\u{1F389}",    // party popper
    "temple": "\u{1F3DB}\u{FE0F}", // classical building
    "family": "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}", // family
    "political": "\u{1F5F3}\u{FE0F}", // ballot box
    "dharma": "\u{2638}\u{FE0F}", // dharma wheel
]

private func getEventEmoji(for event: LifeEvent) -> String {
    // Use the karmaEffect as a rough type proxy; fall back to dharma wheel
    if let effect = event.karmaEffect {
        switch effect {
        case "positive": return "\u{1F64F}"
        case "negative": return "\u{2696}\u{FE0F}"
        default: break
        }
    }
    return "\u{2638}\u{FE0F}"
}

// MARK: - EndOfLifeView

struct EndOfLifeView: View {
    @Bindable var engine: GameEngine

    /// Computed karma score normalized to 0–100. Net karma of 0 maps to 50.
    private var karmaScore: Int {
        let meritVal = Int(engine.karma.merit.rounded())
        let demeritVal = Int(engine.karma.demerit.rounded())
        let net = meritVal - demeritVal
        return max(0, min(100, 50 + net))
    }

    private var meritVal: Int { Int(engine.karma.merit.rounded()) }
    private var demeritVal: Int { Int(engine.karma.demerit.rounded()) }

    /// Key moments or the last 5 events as highlights.
    private var highlights: [LifeEvent] {
        Array(engine.lifeEvents.suffix(5))
    }

    private var rebirth: RebirthTeaser {
        // Prefer the engine's prognosis text if available
        if let prognosis = engine.endOfLifeSummary?.rebirthPrognosis, !prognosis.isEmpty {
            let teaser = getRebirthTeaser(karmaScore: karmaScore)
            return RebirthTeaser(text: prognosis, emoji: teaser.emoji)
        }
        return getRebirthTeaser(karmaScore: karmaScore)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: Header
                Text("The wheel turns...")
                    .font(.system(size: 14))
                    .foregroundStyle(Color("TextSecondary"))
                    .padding(.top, 48)
                    .padding(.bottom, 8)

                Text("You lived to age \(engine.character.age)")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(Color("TextPrimary"))

                Text("\(countryFlag(engine.character.country)) \(engine.character.name) of \(countryDisplayName(engine.character.country))")
                    .font(.system(size: 16))
                    .foregroundStyle(Color("TextSecondary"))
                    .padding(.top, 4)
                    .padding(.bottom, 32)

                // MARK: Karma Ring
                karmaRing
                    .padding(.bottom, 32)

                // MARK: Stats Row
                statsRow
                    .padding(.bottom, 32)

                // MARK: Highlights
                if !highlights.isEmpty {
                    highlightsSection
                        .padding(.bottom, 32)
                }

                // MARK: Rebirth Card
                rebirthCard
                    .padding(.bottom, 24)

                // MARK: Play Again Button
                Button {
                    engine.returnToTitle()
                } label: {
                    Text("Begin New Life")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("AccentColor"), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(EndOfLifeScaleButtonStyle())
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: - Karma Ring

    private var karmaRing: some View {
        let size: CGFloat = 160
        let strokeWidth: CGFloat = 12
        let clampedScore = Double(max(0, min(100, karmaScore)))
        let trimEnd = clampedScore / 100.0

        return ZStack {
            // Background track
            Circle()
                .stroke(Color(.systemGray4), lineWidth: strokeWidth)
                .frame(width: size - strokeWidth, height: size - strokeWidth)

            // Filled arc
            Circle()
                .trim(from: 0, to: trimEnd)
                .stroke(
                    Color("AccentColor"),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size - strokeWidth, height: size - strokeWidth)
                .rotationEffect(.degrees(-90))

            // Center label
            VStack(spacing: 4) {
                Text("\(karmaScore)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color("TextPrimary"))

                Text("Karma")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(emoji: "\u{1F64F}", value: meritVal, label: "Merit", color: .green)

            divider

            statItem(emoji: "\u{1F480}", value: demeritVal, label: "Demerit", color: .red)

            divider

            statItem(emoji: "\u{1F4DC}", value: engine.lifeEvents.count, label: "Events", color: Color("TextPrimary"))
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color("BgSecondary"), in: RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(emoji: String, value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 20))
            Text("\(value)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.systemGray3))
            .frame(width: 1, height: 40)
    }

    // MARK: - Highlights Section

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HIGHLIGHTS")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color("TextSecondary"))
                .tracking(0.8)

            VStack(spacing: 8) {
                ForEach(highlights) { event in
                    highlightRow(event)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func highlightRow(_ event: LifeEvent) -> some View {
        HStack(spacing: 10) {
            Text("Age \(event.age)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color("AccentColor"))
                .frame(minWidth: 48, alignment: .leading)

            Text(getEventEmoji(for: event))
                .font(.system(size: 18))

            Text(event.title.isEmpty ? (event.choiceText.isEmpty ? "A moment of significance" : event.choiceText) : event.title)
                .font(.system(size: 15))
                .foregroundStyle(Color("TextPrimary"))
                .lineSpacing(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("BgSecondary"), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }

    // MARK: - Rebirth Card

    private var rebirthCard: some View {
        VStack(spacing: 12) {
            Text(rebirth.emoji)
                .font(.system(size: 32))

            Text(rebirth.text)
                .font(.system(size: 15))
                .foregroundStyle(Color("TextPrimary"))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color("BgSecondary"), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Scale Button Style

private struct EndOfLifeScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    let engine = GameEngine()
    EndOfLifeView(engine: engine)
}
