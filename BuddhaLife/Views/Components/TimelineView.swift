import SwiftUI

// MARK: - TimelineView
//
// Ports Timeline.jsx — a reverse-chronological scrollable list of life events.
//
// Each entry displays:
//   - An "Age N" pill badge in saffron gold
//   - A summary line (choiceText if shorter than title, else title)
//   - Green/red/gray tint based on karmaEffect
//
// When no events exist yet, shows a centered "Your story begins..." placeholder.

struct TimelineView: View {

    let lifeEvents: [LifeEvent]

    // MARK: - Derived State

    /// Events sorted newest-first, matching `sortedEvents` in Timeline.jsx.
    private var sortedEvents: [LifeEvent] {
        lifeEvents.sorted { $0.age > $1.age }
    }

    // MARK: - Body

    var body: some View {
        if lifeEvents.isEmpty {
            emptyPlaceholder
        } else {
            eventList
        }
    }

    // MARK: - Empty Placeholder

    private var emptyPlaceholder: some View {
        Text("Your story begins...")
            .font(.system(size: 16))
            .foregroundStyle(Color("TextSecondary"))
            .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Event List

    private var eventList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(sortedEvents.enumerated()), id: \.element.id) { index, event in
                VStack(spacing: 0) {
                    eventRow(event)

                    // Divider — skip after last item (mirrors JSX index check)
                    if index < sortedEvents.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Event Row

    /// Renders one timeline entry: age badge + summary text.
    /// Summary logic mirrors Timeline.jsx:
    ///   choiceText if shorter than title, else title, fallback "An event occurred".
    private func eventRow(_ event: LifeEvent) -> some View {
        let summary: String = {
            if !event.choiceText.isEmpty,
               event.choiceText.count < (event.title.isEmpty ? Int.max : event.title.count) {
                return event.choiceText
            }
            if !event.title.isEmpty { return event.title }
            if !event.choiceText.isEmpty { return event.choiceText }
            return "An event occurred"
        }()

        return HStack(alignment: .center, spacing: 12) {
            // Age badge — saffron gold pill
            Text("Age \(event.age)")
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(karmaTintColor(event.karmaEffect))
                .padding(.horizontal, 10)
                .frame(minWidth: 48, minHeight: 28)
                .background(
                    Capsule()
                        .fill(karmaTintColor(event.karmaEffect).opacity(0.12))
                )

            // Summary text
            Text(summary)
                .font(.system(size: 15))
                .foregroundStyle(Color("TextPrimary"))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Karma Tint

    /// Returns green/red/saffron-gold based on the event's karma effect.
    private func karmaTintColor(_ karmaEffect: String?) -> Color {
        switch karmaEffect {
        case "positive":
            return Color(red: 0.204, green: 0.780, blue: 0.349) // green
        case "negative":
            return Color(red: 1.0, green: 0.231, blue: 0.188)   // red
        default:
            return Color.accentColor                              // saffron gold (neutral/nil)
        }
    }
}

// MARK: - Preview

#Preview("With events") {
    ScrollView {
        TimelineView(lifeEvents: [
            LifeEvent(eventId: "e1", title: "Born into a humble family", choiceText: "Born", outcomeText: "", age: 0, year: 2020, karmaEffect: nil),
            LifeEvent(eventId: "e2", title: "Helped an elderly monk", choiceText: "You helped the monk carry water", outcomeText: "", age: 5, year: 2025, karmaEffect: "positive"),
            LifeEvent(eventId: "e3", title: "Stole fruit from the market", choiceText: "Stole fruit", outcomeText: "", age: 8, year: 2028, karmaEffect: "negative"),
        ])
    }
}

#Preview("Empty") {
    TimelineView(lifeEvents: [])
}
