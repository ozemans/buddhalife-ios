import Foundation
import Observation

// MARK: - GameEngine

/// The central game state manager. Combines the reducer from gameState.js
/// and the orchestration logic from App.jsx (handleAdvanceYear, handleMakeChoice, etc.)
/// into a single @Observable class for SwiftUI binding.
@Observable
final class GameEngine {

    // MARK: - Event Probability by Life Stage

    /// Probability of a random event firing each year, keyed by life stage.
    /// Mirrors EVENT_CHANCE from App.jsx.
    private static let eventChance: [LifeStage: Double] = [
        .childhood: 0.4,
        .adolescence: 0.55,
        .youngAdulthood: 0.6,
        .adulthood: 0.55,
        .elderhood: 0.5,
    ]

    // MARK: - Observable State

    var screen: Screen = .title
    var character: Character = Character()
    var stats: Stats = Stats()
    var karma: Karma = Karma()
    var relationships: [Relationship] = []
    var lifeEvents: [LifeEvent] = []
    var currentEvent: GameEvent? = nil
    var year: Int = 0
    var lifeStage: LifeStage = .childhood
    var endOfLifeSummary: EndOfLifeSummary? = nil
    var seenEvents: Set<String> = []

    // MARK: - Internal State

    /// All events loaded from bundled JSON files.
    private var allEvents: [GameEvent] = []

    // MARK: - Init

    init() {
        loadAllEvents()
    }

    // MARK: - Event Loading

    /// Load all event JSON files from the app bundle.
    /// Mirrors the import of all country event files + shared events in App.jsx.
    private func loadAllEvents() {
        let eventFiles = ["thailand", "myanmar", "cambodia", "vietnam", "laos", "shared"]
        var events: [GameEvent] = []
        for file in eventFiles {
            if let url = Bundle.main.url(forResource: file, withExtension: "json", subdirectory: nil) ??
               Bundle.main.url(forResource: file, withExtension: "json") {
                do {
                    let data = try Data(contentsOf: url)
                    let decoded = try JSONDecoder().decode([GameEvent].self, from: data)
                    events.append(contentsOf: decoded)
                } catch {
                    // Skip files that fail to decode
                }
            }
        }
        allEvents = events
    }

    // MARK: - Start Game

    /// Initialize a new game with the given character configuration.
    /// Mirrors handleStartGame from App.jsx lines 108-124.
    func startGame(config: CharacterConfig) {
        // Reset to initial state
        screen = .playing
        character = Character(
            name: config.name,
            country: config.country,
            background: config.background,
            birthYear: config.birthYear,
            gender: config.gender,
            age: 0
        )
        stats = Stats()
        karma = Karma(merit: 0, demerit: 0, momentum: 0, uncertainty: Double.random(in: 0..<0.2))
        relationships = []
        lifeEvents = []
        currentEvent = nil
        year = 0
        lifeStage = .childhood
        endOfLifeSummary = nil
        seenEvents = []

        // Generate starting NPCs and set them as relationships
        let startingNPCs = NPCEngine.generateStartingNPCs(
            country: config.country,
            background: config.background
        )
        relationships = startingNPCs

        autoSave()
    }

    // MARK: - Advance Year

    /// THE CRITICAL METHOD. Advance the game by one year.
    /// Faithfully ports handleAdvanceYear from App.jsx lines 127-242.
    ///
    /// Flow:
    /// 1. Calculate natural aging changes via LifeProgression.advanceYear
    /// 2. Apply year advancement (age, stats, life stage)
    /// 3. Check for death
    /// 4. Age NPCs, check for NPC deaths
    /// 5. Check for festival event
    /// 6. Maybe trigger a regular random event
    func advanceYear() {
        // 1. Calculate natural aging changes
        let yearChanges = LifeProgression.advanceYear(
            character: character,
            stats: stats,
            karma: karma,
            lifeStage: lifeStage
        )

        // 2. Apply the year advancement (mirrors ADVANCE_YEAR reducer)
        let newAge = character.age + 1
        let newLifeStage = LifeProgression.getLifeStage(age: newAge)

        character.age = newAge
        stats.apply(changes: yearChanges.statChanges)
        year += 1
        lifeStage = newLifeStage

        // Play ambient bell on each year advance
        if !AudioEngine.shared.isMuted {
            AudioEngine.shared.playBell()
        }

        // 3. Check for death (using the updated state)
        if LifeProgression.checkDeath(age: character.age, health: stats.health) {
            let prognosis = LifeProgression.getRebirthPrognosis(
                character: character,
                stats: stats,
                karma: karma
            )
            endOfLifeSummary = EndOfLifeSummary(
                deathQuality: LifeProgression.getDeathQuality(
                    character: character,
                    stats: stats,
                    karma: karma
                ).rawValue,
                rebirthPrognosis: prognosis.text
            )
            screen = .endOfLife
            currentEvent = nil
            PersistenceManager.clear()
            return
        }

        // 3b. Age NPCs -- check for deaths
        let npcResult = NPCEngine.ageNPCs(
            relationships: relationships,
            playerAge: character.age
        )
        if npcResult.relationships != relationships {
            relationships = npcResult.relationships
        }
        if let deathNotification = npcResult.deathNotification {
            // NPC death event takes priority this year
            let deathEvent = createNPCDeathEvent(notification: deathNotification)
            triggerEvent(deathEvent)
            return
        }

        // 4. Check for festival event
        if let festival = FestivalEngine.checkForFestival(
            country: character.country,
            age: character.age
        ) {
            let festivalEvent = FestivalEngine.createFestivalEvent(
                festival: festival,
                age: character.age
            )
            triggerEvent(festivalEvent)
            return
        }

        // 5. Maybe trigger a regular event
        let stage = newLifeStage
        let eventProbability = Self.eventChance[stage] ?? 0.5

        if Double.random(in: 0..<1) < eventProbability {
            if let event = EventSelector.selectEvent(
                from: allEvents,
                character: character,
                stats: stats,
                karma: karma,
                lifeStage: stage,
                seenEvents: seenEvents
            ) {
                triggerEvent(event)
            }
        }

        autoSave()
    }

    // MARK: - Make Choice

    /// Handle the player making a choice in an event.
    /// Mirrors handleMakeChoice from App.jsx lines 245-273.
    func makeChoice(choiceId: String) {
        guard let event = currentEvent else { return }
        guard let rawChoice = event.choices.first(where: { $0.id == choiceId }) else { return }

        // Adapt the choice from JSON format to consequence engine format
        let adapted = AdaptedChoice.from(rawChoice)

        // Apply consequences
        var consequences = ConsequenceEngine.applyChoice(
            adapted,
            currentEvent: currentEvent,
            character: character,
            stats: stats,
            karma: karma,
            relationships: relationships,
            lifeStage: lifeStage,
            year: year
        )

        // Use the event's outcomeText if available, otherwise use generated text
        if let rawOutcome = rawChoice.outcomeText, !rawOutcome.isEmpty,
           (consequences.outcomeText == nil || consequences.outcomeText!.isEmpty) {
            consequences.outcomeText = rawOutcome
        }

        // Apply consequences to state (mirrors MAKE_CHOICE reducer)
        if let statChanges = consequences.statChanges {
            stats.apply(changes: statChanges)
        }

        if let newKarma = consequences.karma {
            karma = newKarma
        }

        if let relChanges = consequences.relationshipChanges, !relChanges.isEmpty {
            relationships = applyRelationshipChanges(relationships, changes: relChanges)
        }

        if let entry = consequences.lifeEventEntry {
            lifeEvents.append(entry)
        }

        // Mark event as seen
        seenEvents.insert(event.id)

        // Return to playing screen
        screen = .playing
        currentEvent = nil

        // Audio cues for choices
        if !AudioEngine.shared.isMuted {
            AudioEngine.shared.playChime()
            if adapted.karmaEffect == "positive" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    AudioEngine.shared.playMeritSound()
                }
            } else if adapted.karmaEffect == "negative" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    AudioEngine.shared.playDemeritSound()
                }
            }
        }

        autoSave()
    }

    // MARK: - Dismiss Event

    /// Clear the current event and return to the playing screen.
    /// Mirrors DISMISS_EVENT action.
    func dismissEvent() {
        screen = .playing
        currentEvent = nil
        autoSave()
    }

    // MARK: - Return to Title

    /// Reset everything and go back to the title screen.
    /// Mirrors RETURN_TO_TITLE action.
    func returnToTitle() {
        screen = .title
        character = Character()
        stats = Stats()
        karma = Karma()
        relationships = []
        lifeEvents = []
        currentEvent = nil
        year = 0
        lifeStage = .childhood
        endOfLifeSummary = nil
        seenEvents = []
        PersistenceManager.clear()
    }

    // MARK: - Restore Save

    /// Load a saved game from PersistenceManager.
    /// Mirrors RESTORE_SAVE action / handleContinue.
    func restoreSave() {
        guard let saved = PersistenceManager.load() else { return }
        screen = saved.screen
        character = saved.character
        stats = saved.stats
        karma = saved.karma
        relationships = saved.relationships
        lifeEvents = saved.lifeEvents
        year = saved.year
        lifeStage = saved.lifeStage
        endOfLifeSummary = saved.endOfLifeSummary
        currentEvent = nil
        // Rebuild seenEvents from lifeEvents timeline
        seenEvents = Set(saved.lifeEvents.map(\.eventId))
    }

    // MARK: - Private Helpers

    /// Trigger an event (show event screen).
    private func triggerEvent(_ event: GameEvent) {
        screen = .event
        currentEvent = event
        autoSave()
    }

    /// Auto-save when the game is in a playing or event state.
    private func autoSave() {
        guard screen == .playing || screen == .event else { return }
        let state = SavedState(
            screen: screen,
            character: character,
            stats: stats,
            karma: karma,
            relationships: relationships,
            lifeEvents: lifeEvents,
            year: year,
            lifeStage: lifeStage,
            endOfLifeSummary: endOfLifeSummary
        )
        PersistenceManager.save(state)
    }

    /// Apply relationship changes to the relationships array.
    /// Mirrors applyRelationshipChanges from gameState.js lines 200-227.
    private func applyRelationshipChanges(
        _ relationships: [Relationship],
        changes: [RelationshipChange]
    ) -> [Relationship] {
        var updated = relationships

        for change in changes {
            switch change.action {
            case .add:
                updated.append(Relationship(
                    name: change.name,
                    type: change.type ?? "friend",
                    affinity: change.affinity ?? 50,
                    description: change.description ?? ""
                ))

            case .update:
                if let idx = updated.firstIndex(where: { $0.name == change.name }) {
                    let currentAffinity = updated[idx].affinity
                    let delta = change.affinityDelta ?? 0
                    updated[idx].affinity = max(0, min(100, currentAffinity + delta))
                    if let desc = change.description {
                        updated[idx].description = desc
                    }
                }

            case .remove:
                updated.removeAll { $0.name == change.name }
            }
        }

        return updated
    }

    /// Create the NPC death event shown when a relationship dies.
    /// Mirrors the inline event object from App.jsx lines 169-218.
    private func createNPCDeathEvent(notification: String) -> GameEvent {
        GameEvent(
            id: "npc_death_\(Int(Date().timeIntervalSince1970))",
            title: "A Loss in the Family",
            country: nil,
            lifeStage: nil,
            minAge: nil,
            maxAge: nil,
            karmaRange: nil,
            description: notification,
            choices: [
                EventChoice(
                    id: "a",
                    text: "Attend the funeral and make merit offerings",
                    effects: ChoiceEffects(
                        karma: KarmaEffect(merit: 3, demerit: 0),
                        stats: ["happiness": -5, "spiritualDev": 3],
                        relationships: nil
                    ),
                    outcomeText: "You honor their memory with prayers and offerings. The merit made brings some comfort.",
                    karmaHint: nil
                ),
                EventChoice(
                    id: "b",
                    text: "Grieve quietly and reflect on impermanence",
                    effects: ChoiceEffects(
                        karma: KarmaEffect(merit: 1, demerit: 0),
                        stats: ["happiness": -3, "wisdom": 4],
                        relationships: nil
                    ),
                    outcomeText: "In your grief, you contemplate the Buddha's teaching on anicca -- all things are impermanent.",
                    karmaHint: nil
                ),
                EventChoice(
                    id: "c",
                    text: "Make a scene at the funeral and air your grievances",
                    effects: ChoiceEffects(
                        karma: KarmaEffect(merit: 0, demerit: 8),
                        stats: ["happiness": -8, "spiritualDev": -5, "socialStanding": -10],
                        relationships: [
                            EventRelationshipEffect(target: "family", change: -15, action: nil, name: nil, type: nil, affinity: nil, affinityDelta: nil, description: nil),
                            EventRelationshipEffect(target: "community", change: -10, action: nil, name: nil, type: nil, affinity: nil, affinityDelta: nil, description: nil),
                        ]
                    ),
                    outcomeText: "You erupt in front of everyone -- old arguments, unresolved anger, all of it spilling out over the coffin. The monks stop chanting. Your mother covers her face. The village will talk about this for years.",
                    karmaHint: nil
                ),
                EventChoice(
                    id: "d",
                    text: "Pocket some of the funeral donation money",
                    effects: ChoiceEffects(
                        karma: KarmaEffect(merit: 0, demerit: 6),
                        stats: ["happiness": -4, "spiritualDev": -3, "socialStanding": -8, "wealth": 5],
                        relationships: [
                            EventRelationshipEffect(target: "family", change: -10, action: nil, name: nil, type: nil, affinity: nil, affinityDelta: nil, description: nil),
                            EventRelationshipEffect(target: "monks", change: -5, action: nil, name: nil, type: nil, affinity: nil, affinityDelta: nil, description: nil),
                        ]
                    ),
                    outcomeText: "While the family is distracted with grief, you slip some of the donation envelopes into your pocket. The money feels heavy. That night, you dream of the deceased watching you with sad, knowing eyes.",
                    karmaHint: nil
                ),
            ],
            tags: ["family", "death", "funeral"],
            source: nil,
            gender: nil,
            requires: nil,
            background: nil,
            karmaRelevance: nil,
            stakes: nil
        )
    }
}
