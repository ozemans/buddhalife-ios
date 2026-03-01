import Foundation

struct Background: Codable, Identifiable {
    let id: String
    let label: String
    let region: String
    let `class`: String
    let startStats: BackgroundStats
    let description: String
}

struct BackgroundStats: Codable {
    let happiness: Int?
    let health: Int?
    let spiritualDev: Int?
    let education: Int?
    let wealth: Int?
    let socialStatus: Int?
}

/// Wrapper for decoding backgrounds.json which is keyed by country
typealias BackgroundsByCountry = [String: [Background]]
