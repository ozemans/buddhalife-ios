import Foundation

struct Festival: Codable, Identifiable {
    var id: String { name }
    let name: String
    let country: String
    let month: String
    let description: String
    let gameEffect: FestivalGameEffect
}

struct FestivalGameEffect: Codable {
    let meritMultiplier: Double
    let events: [String]?
}
