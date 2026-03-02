import Foundation

// MARK: - Life Progression Engine
//
// Handles aging, life stage transitions, natural stat changes,
// and death probability. The life course follows the Theravada/Shan
// model: childhood vulnerability, adolescent ordination,
// young adult household-building, midlife merit leadership,
// and elder temple sleeping.

// MARK: - Death Quality

enum DeathQuality: String {
    case transcendent  // Rare: achieved deep peace
    case peaceful      // Good death: old, meritorious, calm
    case ordinary      // Normal death
    case troubled      // Some unresolved karma
    case dangerous     // Young/violent/burdened death
}

// MARK: - Rebirth Quality

enum RebirthQuality: String {
    case excellent
    case good
    case average
    case poor
    case dire
}

// MARK: - Rebirth Prognosis

struct RebirthPrognosis {
    let text: String
    let rebirthQuality: RebirthQuality
}

// MARK: - Life Stage Config

private struct LifeStageConfig {
    let min: Int
    let max: Int   // Int.max for infinity
    let label: String
}

// MARK: - Life Progression Engine

struct LifeProgression {

    // MARK: - Constants

    private static let lifeStageConfigs: [LifeStage: LifeStageConfig] = [
        .childhood:       LifeStageConfig(min: 0,  max: 12,      label: "Childhood"),
        .adolescence:     LifeStageConfig(min: 13, max: 18,      label: "Adolescence"),
        .youngAdulthood:  LifeStageConfig(min: 19, max: 30,      label: "Young Adulthood"),
        .adulthood:       LifeStageConfig(min: 31, max: 55,      label: "Adulthood"),
        .elderhood:       LifeStageConfig(min: 56, max: Int.max, label: "Elderhood"),
    ]

    // MARK: - Public Methods

    /// Get the life stage for a given age.
    static func getLifeStage(age: Int) -> LifeStage {
        if age <= 12 { return .childhood }
        if age <= 18 { return .adolescence }
        if age <= 30 { return .youngAdulthood }
        if age <= 55 { return .adulthood }
        return .elderhood
    }

    /// Get the display label for a life stage.
    static func getLifeStageLabel(_ stage: LifeStage) -> String {
        return lifeStageConfigs[stage]?.label ?? stage.rawValue
    }

    /// Check whether the character has just transitioned to a new life stage.
    static func isLifeStageTransition(prevAge: Int, newAge: Int) -> Bool {
        return getLifeStage(age: prevAge) != getLifeStage(age: newAge)
    }

    /// Advance one year and return the changes that should be applied.
    /// This does NOT modify state -- it returns a YearChanges struct for the reducer.
    static func advanceYear(
        character: Character,
        stats: Stats,
        karma: Karma,
        lifeStage: LifeStage
    ) -> YearChanges {
        let age = character.age + 1
        let stage = getLifeStage(age: age)
        let prevStage = lifeStage
        let stageChanged = stage != prevStage

        let statChanges = calculateNaturalStatChanges(
            age: age,
            stage: stage,
            stats: stats
        )

        let transitionText: String?
        if stageChanged {
            transitionText = getStageTransitionText(
                newStage: stage,
                character: character
            )
        } else {
            transitionText = nil
        }

        return YearChanges(
            statChanges: statChanges,
            newAge: age,
            newStage: stage,
            stageChanged: stageChanged,
            stageTransitionText: transitionText
        )
    }

    /// Check if the character dies this year.
    /// Death probability increases with age and decreases with health.
    /// A "good death" (old, meritorious, calm) is the ideal.
    static func checkDeath(age: Int, health: Int) -> Bool {
        // No natural death before 10 (though events could still kill)
        if age < 10 { return false }

        // Very small chance of accidental death in youth (10-30)
        if age < 30 {
            return Double.random(in: 0..<1) < 0.001
        }

        // Small chance in adulthood (30-59)
        if age < 60 {
            let baseChance = 0.002 + Double(age - 30) * 0.0005
            let healthMod = Double(100 - health) * 0.0003
            return Double.random(in: 0..<1) < (baseChance + healthMod)
        }

        // Increasing chance in elderhood
        // Base: 2% at 60, rising ~2% per year, modified by health
        let baseChance = 0.02 + Double(age - 60) * 0.02
        let healthMod = Double(100 - health) * 0.005
        let totalChance = min(baseChance + healthMod, 0.95)

        // Health at 0 = guaranteed death
        if health <= 0 { return true }

        return Double.random(in: 0..<1) < totalChance
    }

    /// Determine the quality of death based on the character's state.
    /// In Buddhist belief, the quality of death profoundly affects rebirth.
    static func getDeathQuality(
        character: Character,
        stats: Stats,
        karma: Karma
    ) -> DeathQuality {
        let age = character.age
        let spiritualDev = stats.spiritualDev
        let wisdom = stats.wisdom
        let happiness = stats.happiness
        let merit = karma.merit
        let demerit = karma.demerit
        let stage = getLifeStage(age: age)

        // A "good death" is old, meritorious, calm, and prepared
        var quality = 0

        // Age: dying old is much better than dying young
        if age >= 70 {
            quality += 3
        } else if age >= 56 {
            quality += 2
        } else if age >= 30 {
            quality += 0
        } else {
            quality -= 3  // Young death is a tragedy
        }

        // Spiritual development
        if spiritualDev > 60 {
            quality += 3
        } else if spiritualDev > 30 {
            quality += 1
        } else {
            quality -= 1
        }

        // Wisdom
        if wisdom > 60 {
            quality += 2
        } else if wisdom > 30 {
            quality += 1
        }

        // Karma balance
        let net = merit - demerit
        if net > 30 {
            quality += 3
        } else if net > 10 {
            quality += 1
        } else if net < -30 {
            quality -= 4
        } else if net < -10 {
            quality -= 2
        }

        // Emotional state (happiness as proxy for calm acceptance)
        if happiness > 60 {
            quality += 1
        } else if happiness < 20 {
            quality -= 2
        }

        // Sudden vs. expected
        if stage != .elderhood {
            quality -= 1
        }

        if quality >= 7 { return .transcendent }
        if quality >= 4 { return .peaceful }
        if quality >= 1 { return .ordinary }
        if quality >= -2 { return .troubled }
        return .dangerous
    }

    /// Generate a rebirth prognosis based on death quality and karma.
    static func getRebirthPrognosis(
        character: Character,
        stats: Stats,
        karma: Karma
    ) -> RebirthPrognosis {
        let quality = getDeathQuality(
            character: character,
            stats: stats,
            karma: karma
        )

        switch quality {
        case .transcendent:
            return RebirthPrognosis(
                text: "Your spirit rises like incense smoke toward the heavens. Monks will say you achieved what few can -- a death with no wot remaining. Your next life will begin in auspicious circumstances.",
                rebirthQuality: .excellent
            )
        case .peaceful:
            return RebirthPrognosis(
                text: "You pass gently, surrounded by the merit of a life well-lived. The monks chant and pour water, transferring your accumulated merit. A good rebirth awaits.",
                rebirthQuality: .good
            )
        case .ordinary:
            return RebirthPrognosis(
                text: "Your death is neither remarkable nor troubled. Some merit, some demerit -- the wheel turns. Your next life will reflect the balance of your actions.",
                rebirthQuality: .average
            )
        case .troubled:
            return RebirthPrognosis(
                text: "Unresolved karma weighs on your passing. Your khwan are restless, and your family must make extra merit to ease your journey. The path ahead is uncertain.",
                rebirthQuality: .poor
            )
        case .dangerous:
            return RebirthPrognosis(
                text: "A dangerous death. Your spirit is volatile, caught between worlds. The living must perform special rituals -- song phi to send away your spirit, extra merit-making, perhaps a three-day emergency ordination. Without these, you may linger as a hungry phi.",
                rebirthQuality: .dire
            )
        }
    }

    // MARK: - Private Methods

    /// Calculate natural stat changes that happen each year due to aging.
    /// These are small drifts that reflect the rhythms of a Southeast Asian life.
    private static func calculateNaturalStatChanges(
        age: Int,
        stage: LifeStage,
        stats: Stats
    ) -> [String: Int] {
        var changes: [String: Int] = [
            "health": 0,
            "happiness": 0,
            "wealth": 0,
            "wisdom": 0,
            "socialStanding": 0,
            "spiritualDev": 0,
        ]

        switch stage {
        case .childhood:
            // Children grow healthier, gain a little wisdom from learning
            changes["health", default: 0] += randBetween(0, 2)
            changes["wisdom", default: 0] += randBetween(0, 1)
            changes["happiness", default: 0] += randBetween(-1, 2)

        case .adolescence:
            // Volatile happiness, some wisdom growth, health peaks
            changes["health", default: 0] += randBetween(0, 1)
            changes["wisdom", default: 0] += randBetween(1, 2)
            changes["happiness", default: 0] += randBetween(-3, 3)
            // Social standing starts to matter
            changes["socialStanding", default: 0] += randBetween(-1, 1)

        case .youngAdulthood:
            // Building wealth, accumulating wisdom, health stable
            changes["wealth", default: 0] += randBetween(-1, 2)
            changes["wisdom", default: 0] += randBetween(1, 2)
            changes["socialStanding", default: 0] += randBetween(0, 1)
            // Slight spiritual growth if already on that path
            if stats.spiritualDev > 10 {
                changes["spiritualDev", default: 0] += randBetween(0, 1)
            }

        case .adulthood:
            // Peak earning years, wisdom accumulates steadily
            // Health begins very slow decline after 40
            changes["wealth", default: 0] += randBetween(0, 2)
            changes["wisdom", default: 0] += randBetween(1, 3)
            changes["socialStanding", default: 0] += randBetween(0, 1)
            changes["spiritualDev", default: 0] += randBetween(0, 1)
            if age > 40 {
                changes["health", default: 0] += randBetween(-2, 0)
            }

        case .elderhood:
            // Health declines, but wisdom and spiritual development peak
            // This is the temple-sleeping phase -- spirituality accelerates
            changes["health", default: 0] += randBetween(-3, -1)
            changes["wisdom", default: 0] += randBetween(2, 4)
            changes["spiritualDev", default: 0] += randBetween(1, 3)
            // Happiness depends on spiritual development
            if stats.spiritualDev > 30 {
                changes["happiness", default: 0] += randBetween(0, 2)
            } else {
                changes["happiness", default: 0] += randBetween(-2, 0)
            }
            // Social standing rises with age in Buddhist cultures
            changes["socialStanding", default: 0] += randBetween(0, 2)
            // Wealth may decline as you give more to the temple
            changes["wealth", default: 0] += randBetween(-2, 0)

            // Steeper health decline past 70
            if age > 70 {
                changes["health", default: 0] += randBetween(-3, -1)
            }
            // And past 80
            if age > 80 {
                changes["health", default: 0] += randBetween(-4, -1)
            }
        }

        return changes
    }

    /// Get narrative text for a life stage transition.
    private static func getStageTransitionText(
        newStage: LifeStage,
        character: Character
    ) -> String {
        let name = character.name
        let country = character.country

        switch newStage {
        case .adolescence:
            let highlands = country == "thailand" ? "the Shan highlands" : country
            return "\(name) enters adolescence. The world grows larger and more complex. In \(highlands), this is the age when the community begins to expect more."
        case .youngAdulthood:
            return "\(name) steps into young adulthood. The time for building a household, earning a livelihood, and finding one's place in the web of obligations has arrived."
        case .adulthood:
            return "\(name) enters full adulthood. This is the season for demonstrating maturity -- sponsoring ceremonies, leading the community, and accumulating merit in earnest."
        case .elderhood:
            return "\(name) crosses into elderhood. The body slows, but the spirit quickens. People begin speaking of temple sleeping, of precepts, of preparing for what comes next."
        case .childhood:
            return ""
        }
    }
}
