import Foundation

// MARK: - Festival Engine

/// Handles festival detection and event creation.
/// Festivals are loaded from festivals.json in the app bundle.
struct FestivalEngine {

    /// Probability that a festival occurs in any given year.
    private static let festivalChance = 0.3

    // MARK: - Public API

    /// Check if a festival occurs this year.
    /// Filters festivals to those matching the character's country or "shared",
    /// then rolls a 30% chance. Returns a Festival or nil.
    static func checkForFestival(country: String, age: Int) -> Festival? {
        guard chance(festivalChance) else { return nil }

        let allFestivals = loadFestivals()
        let eligible = allFestivals.filter { f in
            f.country == country || f.country == "shared"
        }

        guard !eligible.isEmpty else { return nil }

        return eligible.randomElement()
    }

    /// Convert a Festival into a GameEvent compatible with EventCard.
    /// Adjusts merit by age (children under 13 get half merit).
    static func createFestivalEvent(festival: Festival, age: Int) -> GameEvent {
        let ageMult = age < 13 ? 0.5 : 1.0
        let mult = festival.gameEffect.meritMultiplier

        let festivalId = "festival_" + festival.name.lowercased()
            .replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)

        let choices: [EventChoice] = [
            EventChoice(
                id: "a",
                text: "Participate fully and make offerings",
                effects: ChoiceEffects(
                    karma: KarmaEffect(
                        merit: Double(Int(3.0 * mult * ageMult)),
                        demerit: 0
                    ),
                    stats: ["happiness": 5, "spiritualDev": 3],
                    relationships: nil
                ),
                outcomeText: "You participate wholeheartedly in \(festival.name). The community spirit lifts your heart.",
                karmaHint: nil
            ),
            EventChoice(
                id: "b",
                text: "Attend quietly and observe",
                effects: ChoiceEffects(
                    karma: KarmaEffect(
                        merit: Double(Int(1.0 * mult * ageMult)),
                        demerit: 0
                    ),
                    stats: ["happiness": 2, "wisdom": 2],
                    relationships: nil
                ),
                outcomeText: "You observe the \(festival.name) celebrations thoughtfully, gaining insight into the tradition.",
                karmaHint: nil
            ),
            EventChoice(
                id: "c",
                text: "Skip the festivities this year",
                effects: ChoiceEffects(
                    karma: KarmaEffect(merit: 0, demerit: 1),
                    stats: ["socialStanding": -2],
                    relationships: nil
                ),
                outcomeText: "You stay home while the community celebrates. Some neighbors notice your absence.",
                karmaHint: nil
            ),
            EventChoice(
                id: "d",
                text: "Steal from the offerings while everyone is distracted",
                effects: ChoiceEffects(
                    karma: KarmaEffect(merit: 0, demerit: 7),
                    stats: [
                        "happiness": -5,
                        "spiritualDev": -5,
                        "socialStanding": -8,
                        "wealth": 3,
                    ],
                    relationships: [
                        EventRelationshipEffect(
                            target: "community", change: -10,
                            action: nil, name: nil, type: nil,
                            affinity: nil, affinityDelta: nil, description: nil
                        ),
                        EventRelationshipEffect(
                            target: "monks", change: -8,
                            action: nil, name: nil, type: nil,
                            affinity: nil, affinityDelta: nil, description: nil
                        ),
                    ]
                ),
                outcomeText: "During the height of \(festival.name), you slip coins and offerings into your pocket while the crowd is absorbed in prayer. A child notices but says nothing \u{2014} only stares. The stolen merit-money burns in your hands. The monks seem to look through you for weeks afterward.",
                karmaHint: nil
            ),
        ]

        return GameEvent(
            id: festivalId,
            title: festival.name,
            country: nil,
            lifeStage: nil,
            minAge: nil,
            maxAge: nil,
            karmaRange: nil,
            description: festival.description,
            choices: choices,
            tags: ["festival", "spiritual"],
            source: nil,
            gender: nil,
            requires: nil,
            background: nil,
            karmaRelevance: nil,
            stakes: nil
        )
    }

    // MARK: - Private Helpers

    /// Load festivals from the bundled festivals.json file.
    private static func loadFestivals() -> [Festival] {
        guard let url = Bundle.main.url(forResource: "festivals", withExtension: "json", subdirectory: "Resources") ??
              Bundle.main.url(forResource: "festivals", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Festival].self, from: data)
        } catch {
            return []
        }
    }
}
