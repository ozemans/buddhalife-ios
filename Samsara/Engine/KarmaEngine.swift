import Foundation

// MARK: - Karma Engine
//
// Karma is NOT a single number. Merit and demerit accumulate separately.
// Momentum tracks tendencies -- repeated good acts build virtuous momentum,
// making future merit slightly more effective (and vice versa).
// Uncertainty adds a small random factor to every karma change,
// reflecting the Buddhist teaching that karma's workings are subtle and
// not perfectly predictable by mortals.

// MARK: - Supporting Types

/// Karma effect label used by the magnitude-based system
enum KarmaEffectType: String {
    case positive
    case negative
    case neutral
    case complex
}

/// Magnitude values for each karma effect type
struct KarmaMagnitude {
    let merit: Double
    let demerit: Double
    let momentumShift: Double
}

/// A choice input for karma calculation. Wraps the karmaEffect label and optional intensity.
struct KarmaChoiceInput {
    let karmaEffect: KarmaEffectType
    let karmaIntensity: Double

    init(karmaEffect: KarmaEffectType = .neutral, karmaIntensity: Double = 1.0) {
        self.karmaEffect = karmaEffect
        self.karmaIntensity = karmaIntensity
    }
}

/// Karma level descriptor
enum KarmaLevel: String, CaseIterable {
    case burdened
    case troubled
    case balanced
    case virtuous
    case pure

    /// Ordered list from worst to best, matching the JS levels array
    static let ordered: [KarmaLevel] = [.burdened, .troubled, .balanced, .virtuous, .pure]
}

/// Full karma display information for the UI.
/// Lotus stage maps to 5 stages of spiritual development:
/// 1 = buried in mud, 5 = fully bloomed above water
struct KarmaDisplay {
    let level: KarmaLevel
    let lotusStage: Int
    let description: String
    let merit: Double
    let demerit: Double
    let momentum: Double
    let momentumDirection: String
}

/// Karma range filter used by event selection.
/// Matches the KarmaRange enum's .object case fields.
struct KarmaRangeFilter {
    var level: KarmaLevelFilter?
    var minMerit: Double?
    var maxMerit: Double?
    var minDemerit: Double?
    var maxDemerit: Double?
}

/// Level filter can be a single level or an array of levels
enum KarmaLevelFilter {
    case single(KarmaLevel)
    case multiple([KarmaLevel])
}

// MARK: - Karma Engine

struct KarmaEngine {

    // MARK: - Constants

    private static let karmaMagnitudes: [KarmaEffectType: KarmaMagnitude] = [
        .positive: KarmaMagnitude(merit: 8, demerit: 0, momentumShift: 0.05),
        .negative: KarmaMagnitude(merit: 0, demerit: 8, momentumShift: -0.05),
        .neutral:  KarmaMagnitude(merit: 1, demerit: 1, momentumShift: 0),
        .complex:  KarmaMagnitude(merit: 4, demerit: 4, momentumShift: 0),
    ]

    // MARK: - Public Methods

    /// Calculate the karma change from an AdaptedChoice (used by ConsequenceEngine).
    /// Bridges from the AdaptedChoice format to the internal KarmaChoiceInput format.
    static func calculateKarmaChange(_ adapted: AdaptedChoice, karma: Karma) -> Karma {
        let effectType = KarmaEffectType(rawValue: adapted.karmaEffect ?? "neutral") ?? .neutral
        let input = KarmaChoiceInput(karmaEffect: effectType, karmaIntensity: adapted.karmaIntensity)
        return calculateKarmaChange(choice: input, currentKarma: karma)
    }

    /// Calculate the karma change from a choice.
    /// Returns a new Karma object (not a delta -- the full updated state).
    static func calculateKarmaChange(choice: KarmaChoiceInput, currentKarma: Karma) -> Karma {
        let magnitude = karmaMagnitudes[choice.karmaEffect] ?? KarmaMagnitude(merit: 1, demerit: 1, momentumShift: 0)
        let intensity = choice.karmaIntensity

        let merit = currentKarma.merit
        let demerit = currentKarma.demerit
        let momentum = currentKarma.momentum
        let uncertainty = currentKarma.uncertainty

        // Base merit/demerit from this choice
        var meritGain = magnitude.merit * intensity
        var demeritGain = magnitude.demerit * intensity

        // Momentum modifier: past tendencies amplify matching actions slightly
        // If you've been virtuous (momentum > 0), merit gains get a small boost
        // If you've been troubled (momentum < 0), demerit gains get a small boost
        if momentum > 0 && meritGain > 0 {
            meritGain *= (1 + momentum * 0.5)
        }
        if momentum < 0 && demeritGain > 0 {
            demeritGain *= (1 + abs(momentum) * 0.5)
        }

        // Diminishing returns on repeated merit-making
        // The more merit you already have, the less each new unit adds
        // This prevents infinite merit stacking and reflects the Buddhist idea
        // that mechanical merit-making without understanding yields less
        let meritDiminish = 1.0 / (1.0 + merit * 0.005)
        let demeritDiminish = 1.0 / (1.0 + demerit * 0.005)
        meritGain *= meritDiminish
        demeritGain *= demeritDiminish

        // Uncertainty: small random wobble on every karma transaction
        // Reflects the unknowability of karma's exact workings
        let wobble = (Double.random(in: 0..<1) - 0.5) * uncertainty * 10
        meritGain = max(0, meritGain + (wobble > 0 ? wobble : 0))
        demeritGain = max(0, demeritGain + (wobble < 0 ? abs(wobble) : 0))

        // Update momentum: decays slightly each action, then shifts
        let momentumDecay = 0.95
        let newMomentum = clamp(
            momentum * momentumDecay + magnitude.momentumShift,
            min: -1,
            max: 1
        )

        // Uncertainty drifts very slowly (the cosmos is unpredictable)
        let newUncertainty = clamp(
            uncertainty + (Double.random(in: 0..<1) - 0.5) * 0.02,
            min: 0.01,
            max: 0.3
        )

        return Karma(
            merit: merit + meritGain,
            demerit: demerit + demeritGain,
            momentum: newMomentum,
            uncertainty: newUncertainty
        )
    }

    /// Get the net karma score (for quick comparison purposes).
    /// This is a simplification -- the game should generally use
    /// merit and demerit separately, but this is useful for thresholds.
    static func getNetKarma(_ karma: Karma) -> Double {
        return karma.merit - karma.demerit
    }

    /// Get a descriptive karma level based on the balance of merit and demerit.
    static func getKarmaLevel(_ karma: Karma) -> KarmaLevel {
        let net = getNetKarma(karma)
        let total = karma.merit + karma.demerit

        // If very little karma has accumulated either way, you're balanced
        if total < 5 { return .balanced }

        let ratio = total > 0 ? net / total : 0

        if ratio > 0.6 { return .pure }
        if ratio > 0.2 { return .virtuous }
        if ratio > -0.2 { return .balanced }
        if ratio > -0.6 { return .troubled }
        return .burdened
    }

    /// Get a full karma display object for the UI.
    static func getKarmaDisplay(_ karma: Karma) -> KarmaDisplay {
        let level = getKarmaLevel(karma)

        let lotusStages: [KarmaLevel: Int] = [
            .burdened: 1,
            .troubled: 2,
            .balanced: 3,
            .virtuous: 4,
            .pure: 5,
        ]

        let descriptions: [KarmaLevel: String] = [
            .pure: "Your actions radiate merit. Like the lotus risen above the water, your karma shines clearly.",
            .virtuous: "You walk a wholesome path. Merit outweighs demerit, and your momentum carries you toward the good.",
            .balanced: "Your karma is in equilibrium. Neither strongly meritorious nor burdened, the scales hang level.",
            .troubled: "Demerit weighs on your spirit. Like murky water obscuring the lotus, past actions cloud your path.",
            .burdened: "Heavy karma presses down. The weight of unwholesome actions demands attention and remedy.",
        ]

        let momentumDirection: String
        if karma.momentum > 0.1 {
            momentumDirection = "trending virtuous"
        } else if karma.momentum < -0.1 {
            momentumDirection = "trending troubled"
        } else {
            momentumDirection = "steady"
        }

        return KarmaDisplay(
            level: level,
            lotusStage: lotusStages[level] ?? 3,
            description: descriptions[level] ?? "Your karma is in equilibrium.",
            merit: (karma.merit * 10).rounded() / 10,
            demerit: (karma.demerit * 10).rounded() / 10,
            momentum: karma.momentum,
            momentumDirection: momentumDirection
        )
    }

    /// Check if karma qualifies for a specific range.
    /// Used by eventSelector to filter events by karma prerequisites.
    static func karmaInRange(_ karma: Karma, range: KarmaRangeFilter?) -> Bool {
        guard let range = range else { return true }

        if let levelFilter = range.level {
            let currentLevel = getKarmaLevel(karma)
            switch levelFilter {
            case .single(let level):
                if level != currentLevel { return false }
            case .multiple(let levels):
                if !levels.contains(currentLevel) { return false }
            }
        }

        if let minMerit = range.minMerit, karma.merit < minMerit { return false }
        if let maxMerit = range.maxMerit, karma.merit > maxMerit { return false }
        if let minDemerit = range.minDemerit, karma.demerit < minDemerit { return false }
        if let maxDemerit = range.maxDemerit, karma.demerit > maxDemerit { return false }

        return true
    }

    /// Convenience overload that accepts the existing KarmaRange enum from event JSON.
    static func karmaInRange(_ karma: Karma, range: KarmaRange?) -> Bool {
        guard let range = range else { return true }

        switch range {
        case .array(_, _):
            // Array format [-100, 100] is a net karma range check
            // For now, always pass (legacy format)
            return true
        case .object(let level, let minMerit, let maxMerit, let minDemerit, let maxDemerit):
            let filter = KarmaRangeFilter(
                level: level.flatMap { levelStr in
                    KarmaLevel(rawValue: levelStr).map { .single($0) }
                },
                minMerit: minMerit.map(Double.init),
                maxMerit: maxMerit.map(Double.init),
                minDemerit: minDemerit.map(Double.init),
                maxDemerit: maxDemerit.map(Double.init)
            )
            return karmaInRange(karma, range: filter)
        }
    }

    /// Get the lotus stage (1-5) for the current karma.
    /// 1 = buried in mud, 5 = fully bloomed above water
    static func getLotusStage(_ karma: Karma) -> Int {
        let level = getKarmaLevel(karma)
        let lotusStages: [KarmaLevel: Int] = [
            .burdened: 1,
            .troubled: 2,
            .balanced: 3,
            .virtuous: 4,
            .pure: 5,
        ]
        return lotusStages[level] ?? 3
    }

    // MARK: - Private Helpers

    private static func clamp(_ val: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, val))
    }
}
