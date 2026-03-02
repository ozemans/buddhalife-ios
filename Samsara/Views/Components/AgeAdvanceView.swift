import SwiftUI

// MARK: - AgeAdvanceView
//
// Ports AgeAdvance.jsx — the idle screen shown between events.
// Displays the avatar emoji, current age, life stage label,
// a transition notice when entering a new life stage, and the
// saffron-gold "Age Up" button that drives the game forward.

struct AgeAdvanceView: View {

    @Bindable var engine: GameEngine

    // MARK: - Derived State

    /// The next age the character will be after tapping "Age Up".
    private var nextAge: Int { engine.character.age + 1 }

    /// Current life stage label.
    private var currentStageLabel: String {
        lifeStageDisplayName(engine.lifeStage)
    }

    /// Next life stage label (what the character will enter).
    private var nextStageLabel: String {
        lifeStageDisplayName(LifeProgression.getLifeStage(age: nextAge))
    }

    /// Whether advancing will cause a life stage transition.
    private var isTransition: Bool {
        engine.lifeStage != LifeProgression.getLifeStage(age: nextAge)
    }

    /// Avatar emoji for the current age and gender.
    private var avatar: String {
        avatarEmoji(age: engine.character.age, gender: engine.character.gender)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Avatar emoji (large)
            Text(avatar)
                .font(.system(size: 64))
                .padding(.bottom, 16)

            // Age display
            Text("Age: \(engine.character.age)")
                .font(.system(size: 40, weight: .bold))
                .tracking(-0.8)
                .foregroundStyle(Color("TextPrimary"))

            // Life stage label
            Text(currentStageLabel)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color("TextSecondary"))
                .padding(.top, 4)

            // Life stage transition notice
            if isTransition {
                Text("Entering \(nextStageLabel)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor.opacity(0.1))
                    )
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Quiet year text
            Text("A quiet year passes...")
                .font(.system(size: 14))
                .italic()
                .foregroundStyle(Color("TextSecondary"))
                .padding(.top, 20)

            Spacer()

            // Age Up button
            Button {
                engine.advanceYear()
            } label: {
                HStack(spacing: 8) {
                    Text("Age Up")
                    Text("\u{25B6}")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.bottom, 24)
        }
        .frame(maxWidth: 400)
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.3), value: isTransition)
    }
}

// MARK: - Scale Button Style

/// Mimics the press-down scale effect from the React onMouseDown/onTouchStart
/// handlers (scale 0.97 on press, 1.0 on release).
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    AgeAdvanceView(engine: GameEngine())
}
