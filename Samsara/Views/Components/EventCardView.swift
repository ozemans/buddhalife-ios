import SwiftUI

// MARK: - Emoji Lookup Tables

/// Maps event tags to display emojis, matching TAG_EMOJI_MAP from EventCard.jsx
private let tagEmojiMap: [String: String] = [
    "spiritual": "\u{1F64F}",
    "ordination": "\u{1F64F}",
    "monastery": "\u{1F3DB}\u{FE0F}",
    "temple": "\u{1F3DB}\u{FE0F}",
    "merit": "\u{2638}\u{FE0F}",
    "dharma": "\u{2638}\u{FE0F}",
    "financial": "\u{1F4B0}",
    "wealth": "\u{1F4B0}",
    "commerce": "\u{1F4B0}",
    "gambling": "\u{1F4B0}",
    "relationship": "\u{2764}\u{FE0F}",
    "family": "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}",
    "health": "\u{1F3E5}",
    "healing": "\u{1F3E5}",
    "education": "\u{1F4DA}",
    "moral": "\u{2696}\u{FE0F}",
    "festival": "\u{1F389}",
    "death": "\u{1F64F}",
    "funeral": "\u{1F64F}",
    "spirits": "\u{1F64F}",
    "political": "\u{1F5F3}\u{FE0F}",
    "environment": "\u{1F333}",
    "aging": "\u{1F9D3}",
    "community": "\u{1F465}",
    "addiction": "\u{26A0}\u{FE0F}",
    "identity": "\u{1F464}",
    "food": "\u{1F35A}",
    "generosity": "\u{1F91D}",
    "tradition": "\u{1F389}",
]

/// Fallback title-keyword-to-emoji patterns, matching TITLE_KEYWORD_EMOJI from EventCard.jsx
private let titleKeywordEmoji: [(pattern: String, emoji: String)] = [
    ("temple|monastery|ordain", "\u{1F3DB}\u{FE0F}"),
    ("spirit|ghost|phi|shrine", "\u{1F64F}"),
    ("death|funeral|cremation|dying", "\u{1F64F}"),
    ("heal|sick|fever|illness", "\u{1F3E5}"),
    ("school|education|study|teach", "\u{1F4DA}"),
    ("money|wealth|gambl|vendor|market|sell", "\u{1F4B0}"),
    ("family|parent|child|son|daughter", "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}"),
    ("forest|tree|environment|logging", "\u{1F333}"),
    ("festival|songkran|ceremony|celebration", "\u{1F389}"),
    ("amulet|meditation|karma|precept", "\u{2638}\u{FE0F}"),
    ("food|eat|rice|meal", "\u{1F35A}"),
    ("hunt|fish|animal", "\u{1F33F}"),
    ("oath|sobriety|drink", "\u{26A0}\u{FE0F}"),
    ("transgender|katoey|identity", "\u{1F464}"),
    ("elder|aging|old", "\u{1F9D3}"),
    ("water|songkran", "\u{1F4A7}"),
]

/// Default choice emojis when no contextual match is found
private let defaultChoiceEmojis = ["\u{1F64F}", "\u{1F4AD}", "\u{1F3AF}", "\u{1F52E}"]

/// Context-aware choice emoji patterns, matching CHOICE_CONTEXTUAL_MAP from EventCard.jsx
private let choiceContextualMap: [(pattern: String, emoji: String)] = [
    ("pray|temple|monk|ordain|spiritual|meditat|chant|precept", "\u{1F64F}"),
    ("share|give|generous|offer|donate|sponsor", "\u{1F91D}"),
    ("money|buy|sell|save|invest|gamble|bet|cost", "\u{1F4B0}"),
    ("run|flee|escape|hide|avoid|skip|refuse", "\u{1F3C3}"),
    ("fight|throw|angry|defy|rebel|resist", "\u{1F4A2}"),
    ("family|parent|mother|father|child|home", "\u{2764}\u{FE0F}"),
    ("study|learn|school|read|education", "\u{1F4DA}"),
    ("eat|food|cook|feast|meal", "\u{1F35A}"),
    ("work|farm|labor|field|fish|hunt", "\u{1F4AA}"),
    ("help|volunteer|join|support|accept", "\u{2B50}"),
    ("wait|delay|later|postpone", "\u{23F3}"),
    ("talk|joke|laugh|negotiate|compromise", "\u{1F5E3}\u{FE0F}"),
    ("heal|cure|remedy|treat", "\u{1F3E5}"),
    ("quiet|calm|control|composed", "\u{1F9D8}"),
]

/// Maps stat keys to display emojis, matching getStatEmoji from EventCard.jsx
private let statEmojiMap: [String: String] = [
    "karma": "\u{2638}\u{FE0F}",
    "merit": "\u{2638}\u{FE0F}",
    "demerit": "\u{2638}\u{FE0F}",
    "health": "\u{2764}\u{FE0F}",
    "happiness": "\u{1F60A}",
    "wealth": "\u{1F4B0}",
    "wisdom": "\u{1F9E0}",
    "socialStatus": "\u{1F465}",
    "socialStanding": "\u{1F465}",
    "spiritualDev": "\u{1F64F}",
    "education": "\u{1F4DA}",
]

// MARK: - Helper Functions

/// Resolve the emoji for an event based on tags, then title keywords.
private func getEventEmoji(_ event: GameEvent) -> String {
    if let tags = event.tags {
        for tag in tags {
            if let emoji = tagEmojiMap[tag] { return emoji }
        }
    }
    let title = event.title.lowercased()
    for (pattern, emoji) in titleKeywordEmoji {
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) != nil {
            return emoji
        }
    }
    return "\u{1F4DC}" // scroll
}

/// Get a contextual emoji for a choice button.
private func getChoiceEmoji(_ text: String, index: Int) -> String {
    let lowered = text.lowercased()
    for (pattern, emoji) in choiceContextualMap {
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           regex.firstMatch(in: lowered, range: NSRange(lowered.startIndex..., in: lowered)) != nil {
            return emoji
        }
    }
    return defaultChoiceEmojis[index % defaultChoiceEmojis.count]
}

/// Get the karma hint indicator for a choice (virtuous, unwholesome, or complex).
private func getKarmaHint(_ choice: EventChoice) -> (symbol: String, color: Color, label: String)? {
    guard let karmaEffect = choice.effects?.karma else { return nil }
    let merit = karmaEffect.merit ?? 0
    let demerit = karmaEffect.demerit ?? 0
    if merit == 0 && demerit == 0 { return nil }
    if merit > 0 && demerit == 0 { return ("\u{2638}\u{FE0F}", Color(red: 0.204, green: 0.780, blue: 0.349), "Virtuous") }
    if demerit > 0 && merit == 0 { return ("\u{26A0}\u{FE0F}", Color(red: 1.0, green: 0.584, blue: 0.0), "Unwholesome") }
    if merit > 0 && demerit > 0 { return ("\u{2696}\u{FE0F}", Color(red: 0.557, green: 0.557, blue: 0.576), "Complex") }
    return nil
}

/// Pretty-format a stat key, e.g. "socialStanding" -> "Social Standing".
private func formatStatLabel(_ key: String) -> String {
    var result = ""
    for char in key {
        if char.isUppercase && !result.isEmpty {
            result += " "
        }
        result.append(char)
    }
    return result.prefix(1).uppercased() + result.dropFirst()
}

// MARK: - Stat Change Model

/// A single stat change pill (e.g. "+5 Health") extracted from a choice's effects.
private struct StatChange: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    let value: Int
}

/// Extract all stat changes (karma + stats) from a choice for display as pills.
private func extractStatChanges(_ choice: EventChoice) -> [StatChange] {
    var changes: [StatChange] = []
    guard let effects = choice.effects else { return changes }

    // Karma effects
    if let karma = effects.karma {
        if let merit = karma.merit, merit != 0 {
            changes.append(StatChange(key: "merit", label: "Merit", value: Int(merit)))
        }
        if let demerit = karma.demerit, demerit != 0 {
            changes.append(StatChange(key: "demerit", label: "Demerit", value: -Int(demerit)))
        }
    }

    // Stat effects
    if let stats = effects.stats {
        for (key, value) in stats.sorted(by: { $0.key < $1.key }) {
            if value != 0 {
                changes.append(StatChange(key: key, label: formatStatLabel(key), value: value))
            }
        }
    }

    return changes
}

// MARK: - EventCardView

struct EventCardView: View {
    let event: GameEvent
    @Bindable var engine: GameEngine

    @State private var selectedChoice: EventChoice?
    @State private var showOutcome: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Event header: emoji + title
            HStack(alignment: .top, spacing: 8) {
                Text(getEventEmoji(event))
                    .font(.system(size: 22))

                Text(event.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color("TextPrimary"))
                    .tracking(-0.4)
                    .lineSpacing(4)
            }
            .padding(.bottom, 16)

            // Body text: description or outcome
            Text(bodyText)
                .font(.system(size: 16))
                .foregroundStyle(Color("TextPrimary"))
                .lineSpacing(6)
                .padding(.bottom, 24)

            // Stat change pills (shown after choosing)
            if showOutcome, let choice = selectedChoice {
                let changes = extractStatChanges(choice)
                if !changes.isEmpty {
                    statChangePills(changes)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Choices or Continue button
            if !showOutcome {
                choiceButtons
            } else {
                continueButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: 600)
        .animation(.easeOut(duration: 0.3), value: showOutcome)
    }

    // MARK: - Body Text

    /// The text displayed: either the event description or the outcome text after choosing.
    private var bodyText: String {
        if showOutcome, let outcome = selectedChoice?.outcomeText, !outcome.isEmpty {
            return outcome
        }
        return event.description
    }

    // MARK: - Choice Buttons

    private var choiceButtons: some View {
        VStack(spacing: 8) {
            ForEach(Array(event.choices.enumerated()), id: \.element.id) { index, choice in
                Button {
                    handleChoice(choice)
                } label: {
                    HStack(spacing: 10) {
                        Text(getChoiceEmoji(choice.text, index: index))
                            .font(.system(size: 20))

                        Text(choice.text)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color("TextPrimary"))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(3)

                        Spacer(minLength: 0)

                        if let hint = getKarmaHint(choice) {
                            Text(hint.symbol)
                                .font(.system(size: 14))
                                .foregroundStyle(hint.color)
                                .opacity(0.7)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .buttonStyle(ChoiceButtonStyle())
            }
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            handleContinue()
        } label: {
            Text("Continue")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color("AccentColor"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ChoiceButtonStyle())
    }

    // MARK: - Stat Change Pills

    private func statChangePills(_ changes: [StatChange]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(changes.enumerated()), id: \.element.id) { index, change in
                HStack(spacing: 4) {
                    Text(statEmojiMap[change.key] ?? "\u{1F4CA}")
                        .font(.system(size: 13))
                    Text("\(change.value > 0 ? "+" : "")\(change.value)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(change.value > 0
                    ? Color(red: 0.91, green: 0.96, blue: 0.91)
                    : Color(red: 1.0, green: 0.92, blue: 0.93))
                .foregroundStyle(change.value > 0
                    ? Color(red: 0.204, green: 0.780, blue: 0.349)
                    : Color(red: 1.0, green: 0.231, blue: 0.188))
                .clipShape(Capsule())
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }

    // MARK: - Actions

    private func handleChoice(_ choice: EventChoice) {
        selectedChoice = choice
        withAnimation(.easeOut(duration: 0.3)) {
            showOutcome = true
        }
    }

    private func handleContinue() {
        guard let choice = selectedChoice else { return }
        engine.makeChoice(choiceId: choice.id)
        // Reset local state for next event
        selectedChoice = nil
        showOutcome = false
    }
}

// MARK: - Choice Button Style (press-down scale)

/// A button style that scales down slightly on press, matching the web app's touch feedback.
private struct ChoiceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Flow Layout

/// A simple horizontal flow layout that wraps items to the next line when they overflow.
/// Used for the stat change pills.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
