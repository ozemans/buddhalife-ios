import Foundation

// MARK: - Game Event (decoded from JSON)

struct GameEvent: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let country: String?
    let lifeStage: String?
    let minAge: Int?
    let maxAge: Int?
    let karmaRange: KarmaRange?
    let description: String
    let choices: [EventChoice]
    let tags: [String]?
    let source: String?
    let gender: String?
    let requires: [String]?
    let background: String?
    let karmaRelevance: String?
    let stakes: Bool?

    static func == (lhs: GameEvent, rhs: GameEvent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Event Choice

struct EventChoice: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let effects: ChoiceEffects?
    let outcomeText: String?
    let karmaHint: String?

    static func == (lhs: EventChoice, rhs: EventChoice) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Choice Effects

struct ChoiceEffects: Codable, Equatable {
    let karma: KarmaEffect?
    let stats: [String: Int]?
    let relationships: [EventRelationshipEffect]?

    // Handle stats being encoded with flexible keys
    enum CodingKeys: String, CodingKey {
        case karma, stats, relationships
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        karma = try container.decodeIfPresent(KarmaEffect.self, forKey: .karma)
        relationships = try container.decodeIfPresent([EventRelationshipEffect].self, forKey: .relationships)

        // Stats can have any string keys including non-standard ones like "education"
        if let statsDict = try? container.decode([String: Int].self, forKey: .stats) {
            stats = statsDict
        } else {
            stats = nil
        }
    }

    init(karma: KarmaEffect?, stats: [String: Int]?, relationships: [EventRelationshipEffect]?) {
        self.karma = karma
        self.stats = stats
        self.relationships = relationships
    }
}

// MARK: - Karma Effect (from event JSON)

struct KarmaEffect: Codable, Equatable {
    let merit: Double?
    let demerit: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Handle both Int and Double in JSON
        if let intVal = try? container.decode(Int.self, forKey: .merit) {
            merit = Double(intVal)
        } else {
            merit = try container.decodeIfPresent(Double.self, forKey: .merit)
        }
        if let intVal = try? container.decode(Int.self, forKey: .demerit) {
            demerit = Double(intVal)
        } else {
            demerit = try container.decodeIfPresent(Double.self, forKey: .demerit)
        }
    }

    init(merit: Double?, demerit: Double?) {
        self.merit = merit
        self.demerit = demerit
    }

    enum CodingKeys: String, CodingKey {
        case merit, demerit
    }
}

// MARK: - Event Relationship Effect (from event JSON)

struct EventRelationshipEffect: Codable, Equatable {
    let target: String?
    let change: Int?
    // Some events use action-based format
    let action: String?
    let name: String?
    let type: String?
    let affinity: Int?
    let affinityDelta: Int?
    let description: String?
}

// MARK: - Karma Range (flexible JSON format)

/// Handles both array format `[-100, 100]` and object format `{"level": "high", "minMerit": 50}`
enum KarmaRange: Codable, Equatable {
    case array(Int, Int)
    case object(level: String?, minMerit: Int?, maxMerit: Int?, minDemerit: Int?, maxDemerit: Int?)

    init(from decoder: Decoder) throws {
        // Try array format first: [-100, 100]
        if let container = try? decoder.singleValueContainer(),
           let arr = try? container.decode([Int].self),
           arr.count >= 2 {
            self = .array(arr[0], arr[1])
            return
        }

        // Try object format
        let container = try decoder.container(keyedBy: ObjectKeys.self)
        let level = try container.decodeIfPresent(String.self, forKey: .level)
        let minMerit = try container.decodeIfPresent(Int.self, forKey: .minMerit)
        let maxMerit = try container.decodeIfPresent(Int.self, forKey: .maxMerit)
        let minDemerit = try container.decodeIfPresent(Int.self, forKey: .minDemerit)
        let maxDemerit = try container.decodeIfPresent(Int.self, forKey: .maxDemerit)
        self = .object(level: level, minMerit: minMerit, maxMerit: maxMerit, minDemerit: minDemerit, maxDemerit: maxDemerit)
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .array(let min, let max):
            var container = encoder.singleValueContainer()
            try container.encode([min, max])
        case .object(let level, let minMerit, let maxMerit, let minDemerit, let maxDemerit):
            var container = encoder.container(keyedBy: ObjectKeys.self)
            try container.encodeIfPresent(level, forKey: .level)
            try container.encodeIfPresent(minMerit, forKey: .minMerit)
            try container.encodeIfPresent(maxMerit, forKey: .maxMerit)
            try container.encodeIfPresent(minDemerit, forKey: .minDemerit)
            try container.encodeIfPresent(maxDemerit, forKey: .maxDemerit)
        }
    }

    private enum ObjectKeys: String, CodingKey {
        case level, minMerit, maxMerit, minDemerit, maxDemerit
    }
}
