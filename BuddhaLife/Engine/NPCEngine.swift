import Foundation

// MARK: - NPC Engine

/// Generates and manages NPCs (non-player characters) including family members,
/// mentors, and friends. Handles name generation, aging, and death events.
struct NPCEngine {

    // MARK: - Name Pools

    /// Country-appropriate name pools (~8 male + 8 female per country)
    private static let namePools: [String: (male: [String], female: [String])] = [
        "thailand": (
            male: ["Somchai", "Prasert", "Wichai", "Anon", "Narong", "Boonmee", "Kittisak", "Surasak"],
            female: ["Suda", "Malai", "Noi", "Pranee", "Wilai", "Kanya", "Supatra", "Duangjai"]
        ),
        "myanmar": (
            male: ["Aung", "Kyaw", "Zaw", "Htun", "Myint", "Thura", "Naing", "Myo"],
            female: ["Aye", "Thin", "Khin", "May", "Nwe", "Su", "Phyu", "Wai"]
        ),
        "cambodia": (
            male: ["Sokha", "Dara", "Vibol", "Rith", "Pheakdey", "Bopha", "Kosal", "Sovann"],
            female: ["Chantrea", "Sreymom", "Kunthea", "Rachana", "Mealea", "Sophea", "Theary", "Vanna"]
        ),
        "vietnam": (
            male: ["Minh", "Duc", "Thanh", "Hieu", "Quang", "Tuan", "Trung", "Phong"],
            female: ["Lan", "Huong", "Mai", "Linh", "Thao", "Ngoc", "Hanh", "Tuyet"]
        ),
        "laos": (
            male: ["Somphone", "Khamla", "Bounmy", "Sengdao", "Vilay", "Thongkham", "Keo", "Outhit"],
            female: ["Khamphone", "Bouachanh", "Daovanh", "Chansouk", "Vanthong", "Manivanh", "Souliya", "Phonesavanh"]
        ),
    ]

    /// Monk/mentor name pools (gender-neutral or male, since Theravada monks are male)
    private static let monkNames: [String: [String]] = [
        "thailand": ["Phra Somchai", "Luang Pho Boon", "Phra Ajahn Tawee", "Phra Kru Wisit"],
        "myanmar": ["Sayadaw U Pandita", "U Nyanissara", "Ashin Sandima", "U Kovida"],
        "cambodia": ["Lok Kru Dhammo", "Preah Bhikkhu Sumedho", "Lok Kru Sokhon", "Achar Vannak"],
        "vietnam": ["Thay Minh Hanh", "Su Ong Duc Nhien", "Thay Quang Thanh", "Thich Hue Phap"],
        "laos": ["Ajahn Khamtan", "Phra Khu Bounpheng", "Ajahn Somphet", "Phra Khu Singkham"],
    ]

    // MARK: - Public API

    /// Generate starting NPCs for a new character.
    /// Returns 3-5 relationships: mother, father, village monk, and optionally a sibling or friend.
    static func generateStartingNPCs(country: String, background: String) -> [Relationship] {
        var usedNames = Set<String>()
        var npcs: [Relationship] = []

        // Mother
        let motherName = pickUniqueName(country: country, gender: "female", usedNames: &usedNames)
        npcs.append(Relationship(
            name: motherName,
            type: "family",
            role: "mother",
            affinity: 80,
            description: "Your mother",
            alive: true
        ))

        // Father
        let fatherName = pickUniqueName(country: country, gender: "male", usedNames: &usedNames)
        npcs.append(Relationship(
            name: fatherName,
            type: "family",
            role: "father",
            affinity: 75,
            description: "Your father",
            alive: true
        ))

        // Village/Neighborhood monk
        let monkPool = monkNames[country] ?? monkNames["thailand"]!
        let monkName = monkPool.randomElement()!
        npcs.append(Relationship(
            name: monkName,
            type: "mentor",
            role: "monk",
            affinity: 60,
            description: "The local monk who watches over your community",
            alive: true
        ))

        // ~50% chance of a sibling
        if chance(0.5) {
            let siblingGender = chance(0.5) ? "male" : "female"
            let siblingName = pickUniqueName(country: country, gender: siblingGender, usedNames: &usedNames)
            npcs.append(Relationship(
                name: siblingName,
                type: "family",
                role: "sibling",
                affinity: 70,
                description: siblingGender == "male" ? "Your brother" : "Your sister",
                alive: true
            ))
        }

        // ~40% chance of a childhood friend
        if chance(0.4) {
            let friendGender = chance(0.5) ? "male" : "female"
            let friendName = pickUniqueName(country: country, gender: friendGender, usedNames: &usedNames)
            npcs.append(Relationship(
                name: friendName,
                type: "friend",
                role: "childhood_friend",
                affinity: 65,
                description: "A childhood friend from your neighborhood",
                alive: true
            ))
        }

        return npcs
    }

    /// Given current relationships and event tags, return an NPC that could
    /// be mentioned in the event. Returns nil if no match.
    static func getNPCForEvent(relationships: [Relationship], eventTags: [String]) -> Relationship? {
        guard !relationships.isEmpty, !eventTags.isEmpty else { return nil }

        let tagStr = eventTags.joined(separator: " ").lowercased()
        let alive = relationships.filter { $0.alive }
        guard !alive.isEmpty else { return nil }

        // Family tags
        if tagStr.range(of: "family|parent|child|mother|father|sibling", options: .regularExpression) != nil {
            let familyNPCs = alive.filter { $0.type == "family" }
            if let pick = familyNPCs.randomElement() { return pick }
        }

        // Spiritual/temple tags
        if tagStr.range(of: "spiritual|temple|monastery|monk|ordination|meditation|dharma|merit", options: .regularExpression) != nil {
            let mentorNPCs = alive.filter { $0.type == "mentor" }
            if let pick = mentorNPCs.randomElement() { return pick }
        }

        // Relationship/community tags
        if tagStr.range(of: "relationship|community|friend|social|village", options: .regularExpression) != nil {
            let friendNPCs = alive.filter { $0.type == "friend" }
            if let pick = friendNPCs.randomElement() { return pick }
            // Fall back to family if no friends
            let familyNPCs = alive.filter { $0.type == "family" }
            if let pick = familyNPCs.randomElement() { return pick }
        }

        return nil
    }

    /// Age NPCs each year. Small chance (~3%) that a family NPC dies,
    /// increasing when the player is older (parents more likely to die when player is 40+).
    /// Returns updated relationships and an optional death notification string.
    static func ageNPCs(
        relationships: [Relationship],
        playerAge: Int
    ) -> (relationships: [Relationship], deathNotification: String?) {
        guard !relationships.isEmpty else {
            return (relationships: relationships, deathNotification: nil)
        }

        var updated = relationships
        var deathNotification: String? = nil

        for i in updated.indices {
            guard updated[i].alive else { continue }
            guard updated[i].type == "family" else { continue }

            var deathChance = 0.03

            // Parents die more often when player is older
            if (updated[i].role == "mother" || updated[i].role == "father") && playerAge >= 40 {
                deathChance = 0.06
            }
            if (updated[i].role == "mother" || updated[i].role == "father") && playerAge >= 55 {
                deathChance = 0.10
            }

            if chance(deathChance) {
                updated[i].alive = false
                let roleLabel: String
                switch updated[i].role {
                case "mother": roleLabel = "mother"
                case "father": roleLabel = "father"
                case "sibling": roleLabel = "sibling"
                default: roleLabel = "family member"
                }
                deathNotification = "Your \(roleLabel), \(updated[i].name), has passed away. The community gathers to honor their memory with prayers and merit-making."
                break  // Only one death per year
            }
        }

        return (relationships: updated, deathNotification: deathNotification)
    }

    /// Get a random name for a given country and gender.
    static func getRandomName(country: String, gender: String) -> String {
        let pool = namePools[country] ?? namePools["thailand"]!
        let list = gender == "female" ? pool.female : pool.male
        return list.randomElement()!
    }

    /// Generate a monk name appropriate for the given country.
    static func generateMonkName(country: String) -> String {
        let pool = monkNames[country] ?? monkNames["thailand"]!
        return pool.randomElement()!
    }

    // MARK: - Private Helpers

    /// Pick a unique name that hasn't been used yet. Falls back to any name if all are taken.
    private static func pickUniqueName(country: String, gender: String, usedNames: inout Set<String>) -> String {
        let pool = namePools[country] ?? namePools["thailand"]!
        let list = gender == "female" ? pool.female : pool.male
        let available = list.filter { !usedNames.contains($0) }
        let name: String
        if available.isEmpty {
            name = list.randomElement()!
        } else {
            name = available.randomElement()!
        }
        usedNames.insert(name)
        return name
    }
}
