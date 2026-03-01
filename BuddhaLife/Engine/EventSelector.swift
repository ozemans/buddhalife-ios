import Foundation

// MARK: - Event Selector

/// Selects appropriate events from the pool based on current game state.
/// Uses weighted random selection where events matching more criteria get higher weight.
struct EventSelector {

    // MARK: - Public API

    /// Select an appropriate event from the pool based on the current game state.
    /// Returns nil if no events match (triggers a "quiet year").
    static func selectEvent(
        from events: [GameEvent],
        character: Character,
        stats: Stats,
        karma: Karma,
        lifeStage: LifeStage,
        seenEvents: Set<String>
    ) -> GameEvent? {
        let available = getAvailableEvents(
            events: events,
            character: character,
            karma: karma,
            lifeStage: lifeStage,
            seenEventIds: seenEvents
        )

        if available.isEmpty { return nil }

        // Calculate weights for each available event
        let weighted = available.map { event in
            (event: event, weight: calculateWeight(
                event: event,
                character: character,
                karma: karma,
                lifeStage: lifeStage
            ))
        }

        // Weighted random selection
        let totalWeight = weighted.reduce(0.0) { $0 + $1.weight }
        if totalWeight == 0 { return nil }

        var roll = Double.random(in: 0..<totalWeight)
        for item in weighted {
            roll -= item.weight
            if roll <= 0 { return item.event }
        }

        // Fallback (shouldn't reach here, but safety)
        return weighted.last?.event
    }

    /// Get all events that could potentially fire for the current state.
    /// Filters by hard requirements, then returns the eligible pool.
    static func getAvailableEvents(
        events: [GameEvent],
        character: Character,
        karma: Karma,
        lifeStage: LifeStage,
        seenEventIds: Set<String>
    ) -> [GameEvent] {
        return events.filter { event in
            // Skip already-seen events
            if seenEventIds.contains(event.id) { return false }

            // Country filter: event must match player's country or be "shared"
            if let country = event.country,
               country != "shared",
               country != character.country {
                return false
            }

            // Life stage filter: event must match current life stage
            if let eventLifeStage = event.lifeStage,
               eventLifeStage != lifeStage.rawValue {
                return false
            }

            // Karma range filter (if the event specifies one)
            if let range = event.karmaRange,
               !karmaInRange(karma: karma, range: range) {
                return false
            }

            // Minimum age filter
            if let minAge = event.minAge, character.age < minAge {
                return false
            }

            // Maximum age filter
            if let maxAge = event.maxAge, character.age > maxAge {
                return false
            }

            // Gender filter (some events are gender-specific)
            if let gender = event.gender, gender != character.gender {
                return false
            }

            // Prerequisite events (must have seen certain events first)
            if let requires = event.requires {
                let met = requires.allSatisfy { seenEventIds.contains($0) }
                if !met { return false }
            }

            return true
        }
    }

    // MARK: - Private Helpers

    /// Calculate weight for an event based on how well it fits the current state.
    /// Higher weight = more likely to be selected.
    private static func calculateWeight(
        event: GameEvent,
        character: Character,
        karma: Karma,
        lifeStage: LifeStage
    ) -> Double {
        var weight = 1.0

        // Country-specific events get a boost over "shared" events
        if event.country == character.country {
            weight += 2.0
        } else if event.country == "shared" {
            weight += 0.5
        }

        // Events matching the exact life stage get a significant boost
        if event.lifeStage == lifeStage.rawValue {
            weight += 3.0
        }

        // Karma-relevant events get a boost
        // Events that address the player's current karma state feel more narratively apt
        if let karmaRelevance = event.karmaRelevance {
            let level = getApproxKarmaLevel(karma: karma)
            if karmaRelevance == level {
                weight += 2.0
            }
        }

        // Events with high narrative stakes get a slight boost
        if event.stakes == true {
            weight += 0.5
        }

        // Background-matching events (if the event references the player's background)
        if let background = event.background, background == character.background {
            weight += 1.5
        }

        // Slight randomness to prevent perfectly predictable selection
        weight *= Double.random(in: 0.8...1.2)

        return max(0.1, weight)
    }

    /// Quick karma level check for weighting (avoids circular dependency).
    private static func getApproxKarmaLevel(karma: Karma) -> String {
        let net = karma.merit - karma.demerit
        let total = karma.merit + karma.demerit
        if total < 5 { return "balanced" }
        let ratio = net / total
        if ratio > 0.6 { return "pure" }
        if ratio > 0.2 { return "virtuous" }
        if ratio > -0.2 { return "balanced" }
        if ratio > -0.6 { return "troubled" }
        return "burdened"
    }

    /// Check if karma qualifies for a specific range.
    /// Used to filter events by karma prerequisites.
    private static func karmaInRange(karma: Karma, range: KarmaRange) -> Bool {
        switch range {
        case .array(_, _):
            // Array format [min, max] represents a net karma range;
            // always passes since it's a loose constraint
            return true

        case .object(let level, let minMerit, let maxMerit, let minDemerit, let maxDemerit):
            // Level-based check
            if let level = level {
                let currentLevel = getApproxKarmaLevel(karma: karma)
                if level != currentLevel { return false }
            }

            // Merit bounds
            if let minMerit = minMerit, karma.merit < Double(minMerit) { return false }
            if let maxMerit = maxMerit, karma.merit > Double(maxMerit) { return false }

            // Demerit bounds
            if let minDemerit = minDemerit, karma.demerit < Double(minDemerit) { return false }
            if let maxDemerit = maxDemerit, karma.demerit > Double(maxDemerit) { return false }

            return true
        }
    }
}
