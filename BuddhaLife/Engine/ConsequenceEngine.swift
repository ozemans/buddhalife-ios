import Foundation

// MARK: - ConsequenceEngine

/// Applies the consequences of a player's choice to produce stat changes,
/// karma updates, relationship effects, and narrative outcome text.
/// Faithfully ported from consequences.js.
struct ConsequenceEngine {

    // MARK: - Public API

    /// Apply a choice's consequences to the game state.
    /// Returns a ChoiceConsequences that the GameEngine uses to update state.
    ///
    /// The choice is expected to be "adapted" — i.e. it has karmaEffect, statChanges,
    /// relationshipEffects, and consequences fields populated from the raw JSON format.
    static func applyChoice(
        _ adapted: AdaptedChoice,
        currentEvent: GameEvent?,
        character: Character,
        stats: Stats,
        karma: Karma,
        relationships: [Relationship],
        lifeStage: LifeStage,
        year: Int
    ) -> ChoiceConsequences {
        // Calculate new karma
        let newKarma = KarmaEngine.calculateKarmaChange(adapted, karma: karma)

        // Calculate stat changes from the choice
        let statChanges = calculateStatChanges(adapted)

        // Process any relationship effects
        let relationshipChanges = processRelationshipEffects(
            adapted,
            relationships: relationships
        )

        // Generate narrative outcome text
        let outcomeText = generateOutcomeText(
            adapted,
            character: character,
            lifeStage: lifeStage
        )

        // Build the life event timeline entry
        let lifeEventEntry = LifeEvent(
            eventId: currentEvent?.id ?? "unknown",
            title: currentEvent?.title ?? "A moment in life",
            choiceText: adapted.text,
            outcomeText: outcomeText,
            age: character.age,
            year: year,
            karmaEffect: adapted.karmaEffect
        )

        return ChoiceConsequences(
            statChanges: statChanges,
            karma: newKarma,
            relationshipChanges: relationshipChanges,
            lifeEventEntry: lifeEventEntry,
            outcomeText: outcomeText
        )
    }

    // MARK: - Stat Changes

    /// Calculate stat changes from a choice.
    /// Uses explicit stat effects if the choice defines them,
    /// otherwise infers reasonable changes from the karma effect.
    static func calculateStatChanges(_ choice: AdaptedChoice) -> [String: Int] {
        // If the choice explicitly defines stat changes, use those
        if let explicit = choice.statChanges, !explicit.isEmpty {
            return explicit
        }

        // Otherwise, infer from karma effect and context
        var changes: [String: Int] = [
            "health": 0,
            "happiness": 0,
            "wealth": 0,
            "wisdom": 0,
            "socialStanding": 0,
            "spiritualDev": 0,
        ]

        let effect = choice.karmaEffect ?? "neutral"

        switch effect {
        case "positive":
            changes["happiness"]! += randBetween(2, 6)
            changes["socialStanding"]! += randBetween(1, 4)
            changes["wisdom"]! += randBetween(1, 3)
            changes["spiritualDev"]! += randBetween(1, 4)
            // Generous acts often cost money
            if choiceMentions(choice, keywords: ["sponsor", "offer", "donate", "give", "generous", "lavish"]) {
                changes["wealth"]! -= randBetween(3, 10)
            }
            // Temple/merit activities boost spiritual dev more
            if choiceMentions(choice, keywords: ["temple", "merit", "monk", "precept", "ordain", "meditation"]) {
                changes["spiritualDev"]! += randBetween(2, 5)
            }

        case "negative":
            changes["happiness"]! -= randBetween(2, 6)
            changes["socialStanding"]! -= randBetween(2, 5)
            // Breaking precepts or bad acts reduce spiritual dev
            changes["spiritualDev"]! -= randBetween(1, 3)
            // Some negative choices gain wealth (dirty money, gambling)
            if choiceMentions(choice, keywords: ["gamble", "money", "accept", "job", "dirty", "steal"]) {
                changes["wealth"]! += randBetween(2, 8)
            }
            // Dangerous choices may risk health
            if choiceMentions(choice, keywords: ["risk", "danger", "break", "fight", "drink", "spirit"]) {
                changes["health"]! -= randBetween(2, 8)
            }

        case "complex":
            // Complex choices have mixed outcomes -- some good, some bad
            changes["wisdom"]! += randBetween(2, 5) // You always learn from complexity
            changes["happiness"]! += randBetween(-4, 4)
            changes["socialStanding"]! += randBetween(-3, 3)
            // Financial complexity
            if choiceMentions(choice, keywords: ["money", "debt", "gamble", "accept"]) {
                changes["wealth"]! += randBetween(-5, 10)
            }
            // Spiritual complexity
            if choiceMentions(choice, keywords: ["spirit", "faith", "religion", "path"]) {
                changes["spiritualDev"]! += randBetween(-2, 4)
            }

        default: // "neutral"
            // Small, mild changes
            changes["wisdom"]! += randBetween(0, 2)
            changes["happiness"]! += randBetween(-2, 2)
        }

        // Apply surprise factor: occasionally, consequences are unexpectedly
        // stronger or weaker (reflecting karma's unpredictability)
        if Double.random(in: 0..<1) < 0.15 {
            let surpriseMultiplier: Double = Double.random(in: 0..<1) < 0.5 ? 1.5 : 0.5
            for key in changes.keys {
                changes[key] = Int((Double(changes[key]!) * surpriseMultiplier).rounded())
            }
        }

        return changes
    }

    // MARK: - Relationship Effects

    /// Process relationship effects from a choice.
    static func processRelationshipEffects(
        _ choice: AdaptedChoice,
        relationships: [Relationship]
    ) -> [RelationshipChange] {
        if let explicit = choice.relationshipEffects, !explicit.isEmpty {
            return explicit
        }

        // Infer basic relationship effects from the choice context
        var changes: [RelationshipChange] = []

        // Choices involving community impact social bonds
        if choiceMentions(choice, keywords: ["community", "village", "neighbor", "volunteer"]) {
            if !relationships.isEmpty {
                let idx = Int.random(in: 0..<relationships.count)
                changes.append(RelationshipChange(
                    action: .update,
                    name: relationships[idx].name,
                    affinityDelta: choice.karmaEffect == "positive" ? 5 : -3
                ))
            }
        }

        // Choices involving family
        if choiceMentions(choice, keywords: ["family", "parent", "mother", "father", "child", "son", "daughter"]) {
            let familyRels = relationships.filter { $0.type == "family" }
            for rel in familyRels {
                let delta: Int
                if choice.karmaEffect == "positive" {
                    delta = randBetween(3, 8)
                } else if choice.karmaEffect == "negative" {
                    delta = randBetween(-8, -3)
                } else {
                    delta = randBetween(-2, 2)
                }
                changes.append(RelationshipChange(
                    action: .update,
                    name: rel.name,
                    affinityDelta: delta
                ))
            }
        }

        return changes
    }

    // MARK: - Outcome Text

    /// Generate narrative text describing the outcome of a choice.
    static func generateOutcomeText(
        _ choice: AdaptedChoice,
        character: Character,
        lifeStage: LifeStage
    ) -> String {
        // If the choice has explicit consequences text from the encounter seed, use it
        if let consequences = choice.consequences, !consequences.isEmpty {
            return personalizeText(consequences, character: character, lifeStage: lifeStage)
        }

        // Otherwise generate based on effect type and context
        let effect = choice.karmaEffect ?? "neutral"
        let templates = getOutcomeTemplates(effect: effect)
        let template = templates.randomElement() ?? ""
        return personalizeText(template, character: character, lifeStage: lifeStage)
    }

    /// Replace template variables with character-specific details.
    static func personalizeText(
        _ text: String,
        character: Character,
        lifeStage: LifeStage
    ) -> String {
        text
            .replacingOccurrences(of: "{name}", with: character.name)
            .replacingOccurrences(of: "{country}", with: character.country)
            .replacingOccurrences(of: "{age}", with: String(character.age))
            .replacingOccurrences(of: "{stage}", with: lifeStage.rawValue)
    }

    /// Check if a choice's text mentions any of the given keywords.
    static func choiceMentions(_ choice: AdaptedChoice, keywords: [String]) -> Bool {
        let text = choice.text.lowercased()
        return keywords.contains { text.contains($0) }
    }

    // MARK: - Outcome Templates

    /// Get outcome text templates based on the type of karmic effect.
    private static func getOutcomeTemplates(effect: String) -> [String] {
        let positive = [
            "The community takes notice of your generosity. Elders nod approvingly, and your reputation grows like a well-tended garden.",
            "Merit flows from your actions like water poured from a blessed vessel. You feel lighter, as though a burden has been set down.",
            "Your choice echoes the teachings. In the quiet after, something shifts -- a small opening toward wisdom.",
            "The monks speak of your deed during the next wan sin gathering. Your merit accumulates, visible to all who care to see.",
            "A warm feeling settles in your chest. The khwan are steady. You did the right thing.",
        ]

        let negative = [
            "A heaviness follows your decision. The elders say nothing, but their silence speaks volumes.",
            "You feel the weight of demerit accumulating, like mud on the lotus stem. The path ahead grows murkier.",
            "Word travels through the village faster than you expected. Some doors that were open now seem to close.",
            "That night, sleep comes uneasily. The spirits notice when the precepts are broken.",
            "Your khwan feel unsettled, as though something was lost that cannot easily be retrieved.",
        ]

        let complex = [
            "The consequences of your choice ripple outward in ways you cannot fully predict. Some good, some troubling -- such is the nature of karma.",
            "Wisdom comes from navigating complexity. You learn something true about the world, though the lesson is not comfortable.",
            "The village debates your decision. Some praise your courage; others question your judgment. Both have their reasons.",
            "Like the lotus that grows in murky water, something beautiful may yet emerge from this difficult choice. Or perhaps not. Time will tell.",
            "Your action sits at the crossroads of merit and demerit. The monks say even the Buddha could not always see the full reach of karma.",
        ]

        let neutral = [
            "Life continues its ordinary rhythm. Not every moment is a turning point -- some years pass like clouds.",
            "Your choice is practical, neither remarkable nor regrettable. The wheel turns.",
            "A quiet moment. The monastery bells sound in the distance. Tomorrow will bring its own concerns.",
            "Nothing dramatic follows, but perhaps that is its own form of wisdom -- knowing when not to act boldly.",
        ]

        switch effect {
        case "positive": return positive
        case "negative": return negative
        case "complex": return complex
        default: return neutral
        }
    }
}

// MARK: - AdaptedChoice

/// An event choice "adapted" from JSON format to the format the ConsequenceEngine expects.
/// Bridges the gap between EventChoice (from JSON) and the consequence engine's needs.
/// Mirrors the `adaptChoice` function from App.jsx.
struct AdaptedChoice {
    let id: String
    let text: String
    let karmaEffect: String?         // "positive", "negative", "complex", "neutral"
    let karmaIntensity: Double
    let statChanges: [String: Int]?
    let relationshipEffects: [RelationshipChange]?
    let consequences: String?         // outcomeText from JSON
    let effects: ChoiceEffects?       // original effects for KarmaEngine

    /// Adapt an EventChoice from JSON format to the format the consequence engine expects.
    /// Mirrors the `adaptChoice` function from App.jsx lines 52-74.
    static func from(_ choice: EventChoice) -> AdaptedChoice {
        let effects = choice.effects
        let karma = effects?.karma

        // Derive karmaEffect string from merit/demerit values
        var karmaEffect = "neutral"
        let meritVal = karma?.merit ?? 0
        let demeritVal = karma?.demerit ?? 0
        if meritVal > 0 && demeritVal == 0 { karmaEffect = "positive" }
        else if demeritVal > 0 && meritVal == 0 { karmaEffect = "negative" }
        else if meritVal > 0 && demeritVal > 0 { karmaEffect = "complex" }

        // Derive intensity from magnitude
        let maxKarma = max(meritVal, demeritVal)
        let karmaIntensity = maxKarma > 0 ? maxKarma / 8.0 : 1.0

        // Convert EventRelationshipEffect to RelationshipChange
        var relationshipChanges: [RelationshipChange]?
        if let relEffects = effects?.relationships, !relEffects.isEmpty {
            relationshipChanges = relEffects.map { effect in
                RelationshipChange(
                    action: RelationshipChange.Action(rawValue: effect.action ?? "update") ?? .update,
                    name: effect.name ?? effect.target ?? "",
                    type: effect.type,
                    affinity: effect.affinity,
                    affinityDelta: effect.affinityDelta ?? effect.change,
                    description: effect.description
                )
            }
        }

        return AdaptedChoice(
            id: choice.id,
            text: choice.text,
            karmaEffect: karmaEffect,
            karmaIntensity: karmaIntensity,
            statChanges: effects?.stats,
            relationshipEffects: relationshipChanges,
            consequences: choice.outcomeText,
            effects: effects
        )
    }
}
