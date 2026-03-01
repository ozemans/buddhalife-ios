import SwiftUI

// MARK: - KarmaVisualizerView

struct KarmaVisualizerView: View {
    let karma: Karma

    // MARK: - Derived Values

    /// Karma score clamped to 0-100, matching the web app's formula:
    /// Math.round(Math.max(0, Math.min(100, 50 + (merit - demerit))))
    private var score: Int {
        let raw = 50.0 + (karma.merit - karma.demerit)
        return Int(max(0, min(100, raw)).rounded())
    }

    private var display: KarmaDisplay {
        KarmaEngine.getKarmaDisplay(karma)
    }

    private var momentumDisplay: (text: String, arrow: String, color: Color) {
        if karma.momentum > 0.1 {
            return ("Rising", "\u{2191}", Color(red: 0.204, green: 0.780, blue: 0.349))
        }
        if karma.momentum < -0.1 {
            return ("Falling", "\u{2193}", Color(red: 1.0, green: 0.231, blue: 0.188))
        }
        return ("Steady", "\u{2192}", Color("TextSecondary"))
    }

    /// Lotus stage emoji visualization: 1-5 maps to increasingly bloomed lotus.
    private var lotusEmoji: String {
        switch display.lotusStage {
        case 1: return "\u{1F331}"           // seedling
        case 2: return "\u{1F33F}"           // herb
        case 3: return "\u{1F337}"           // tulip
        case 4: return "\u{1FAB7}"           // lotus
        case 5: return "\u{1FAB7}\u{2728}"   // lotus + sparkles
        default: return "\u{1F337}"
        }
    }

    // MARK: - Ring Dimensions

    private let ringSize: CGFloat = 120
    private let strokeWidth: CGFloat = 8

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Circular progress ring
            karmaRing
                .padding(.bottom, 16)

            // Lotus stage
            Text(lotusEmoji)
                .font(.system(size: 28))
                .padding(.bottom, 8)

            // Merit / Demerit line
            Text("Merit: \(Int(karma.merit.rounded())) | Demerit: \(Int(karma.demerit.rounded()))")
                .font(.system(size: 14))
                .foregroundStyle(Color("TextSecondary"))
                .padding(.bottom, 8)

            // Momentum indicator
            Text("\(momentumDisplay.text) \(momentumDisplay.arrow)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(momentumDisplay.color)
                .padding(.bottom, 12)

            // Karma level description
            Text(display.description)
                .font(.system(size: 14))
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 280)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .animation(.easeOut(duration: 0.8), value: score)
    }

    // MARK: - Karma Ring

    private var karmaRing: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(Color(.systemGray5), lineWidth: strokeWidth)
                .frame(width: ringSize, height: ringSize)

            // Filled arc
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100.0)
                .stroke(
                    Color("AccentColor"),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: score)

            // Score number centered
            Text("\(score)")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color("TextPrimary"))
                .tracking(-0.7)
                .monospacedDigit()
        }
    }
}
