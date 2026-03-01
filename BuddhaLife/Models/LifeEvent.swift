import Foundation

struct LifeEvent: Codable, Equatable, Identifiable {
    var id: String { "\(age)-\(eventId)" }
    var eventId: String
    var title: String
    var choiceText: String
    var outcomeText: String
    var age: Int
    var year: Int
    var karmaEffect: String?   // "positive", "negative", "neutral"
}
