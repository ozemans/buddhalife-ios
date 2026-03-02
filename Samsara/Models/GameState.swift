import Foundation

// MARK: - Screen States

enum Screen: String, Codable, Equatable {
    case title
    case playing
    case event
    case endOfLife
}

// MARK: - Life Stages

enum LifeStage: String, Codable, Equatable {
    case childhood
    case adolescence
    case youngAdulthood = "young_adulthood"
    case adulthood
    case elderhood
}

// MARK: - Game Actions

enum GameAction {
    case startGame(CharacterConfig)
    case advanceYear(YearChanges)
    case triggerEvent(GameEvent)
    case makeChoice(consequences: ChoiceConsequences)
    case dismissEvent
    case endLife(EndOfLifeSummary?)
    case returnToTitle
    case restoreSave(SavedState)
    case setRelationships([Relationship])
}

// MARK: - Supporting Types

struct CharacterConfig {
    let name: String
    let country: String
    let background: String
    let birthYear: Int
    let gender: String
}

struct YearChanges {
    var statChanges: [String: Int] = [:]
    var newAge: Int = 0
    var newStage: LifeStage = .childhood
    var stageChanged: Bool = false
    var stageTransitionText: String? = nil
}

struct ChoiceConsequences {
    var statChanges: [String: Int]?
    var karma: Karma?
    var relationshipChanges: [RelationshipChange]?
    var lifeEventEntry: LifeEvent?
    var outcomeText: String?
}

struct RelationshipChange {
    enum Action: String {
        case add, update, remove
    }
    var action: Action
    var name: String
    var type: String?
    var affinity: Int?
    var affinityDelta: Int?
    var description: String?
}

struct EndOfLifeSummary: Codable {
    var deathQuality: String?
    var rebirthPrognosis: String?
}

// MARK: - Saved State (for persistence)

struct SavedState: Codable {
    var screen: Screen
    var character: Character
    var stats: Stats
    var karma: Karma
    var relationships: [Relationship]
    var lifeEvents: [LifeEvent]
    var year: Int
    var lifeStage: LifeStage
    var endOfLifeSummary: EndOfLifeSummary?
}
