import Foundation

/// Get emoji avatar for a given age
func avatarEmoji(age: Int, gender: String) -> String {
    switch age {
    case 0..<3: return "👶"
    case 3..<13: return gender == "female" ? "👧" : "🧒"
    case 13..<20: return gender == "female" ? "👩" : "👦"
    case 20..<55: return gender == "female" ? "👩" : "👨"
    default: return gender == "female" ? "👵" : "👴"
    }
}

/// Get flag emoji for a country
func countryFlag(_ country: String) -> String {
    switch country {
    case "thailand": return "🇹🇭"
    case "myanmar": return "🇲🇲"
    case "cambodia": return "🇰🇭"
    case "vietnam": return "🇻🇳"
    case "laos": return "🇱🇦"
    default: return "🌏"
    }
}

/// Get display name for a country
func countryDisplayName(_ country: String) -> String {
    switch country {
    case "thailand": return "Thailand"
    case "myanmar": return "Myanmar"
    case "cambodia": return "Cambodia"
    case "vietnam": return "Vietnam"
    case "laos": return "Laos"
    default: return country.capitalized
    }
}

/// Get display name for a life stage
func lifeStageDisplayName(_ stage: LifeStage) -> String {
    switch stage {
    case .childhood: return "Childhood"
    case .adolescence: return "Adolescence"
    case .youngAdulthood: return "Young Adulthood"
    case .adulthood: return "Adulthood"
    case .elderhood: return "Elderhood"
    }
}

/// Get contextual emoji for event tags
func eventEmoji(tags: [String]?) -> String {
    guard let tags else { return "📜" }
    if tags.contains("ordination") || tags.contains("monastery") { return "⛩️" }
    if tags.contains("spiritual") || tags.contains("meditation") { return "☸️" }
    if tags.contains("festival") || tags.contains("ceremony") { return "🎉" }
    if tags.contains("death") || tags.contains("funeral") { return "🕊️" }
    if tags.contains("family") { return "👨‍👩‍👦" }
    if tags.contains("healing") || tags.contains("spirit") { return "🌿" }
    if tags.contains("money") || tags.contains("financial") { return "💰" }
    if tags.contains("moral") || tags.contains("temptation") { return "⚖️" }
    if tags.contains("education") { return "📚" }
    if tags.contains("nature") || tags.contains("environment") { return "🌳" }
    return "📜"
}
