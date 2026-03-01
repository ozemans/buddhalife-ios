import Foundation

struct LifeEvent: Codable, Equatable, Identifiable {
    var id: String
    var eventId: String
    var title: String
    var choiceText: String
    var outcomeText: String
    var age: Int
    var year: Int
    var karmaEffect: String?   // "positive", "negative", "neutral"

    init(
        id: String = UUID().uuidString,
        eventId: String,
        title: String,
        choiceText: String,
        outcomeText: String,
        age: Int,
        year: Int,
        karmaEffect: String? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.title = title
        self.choiceText = choiceText
        self.outcomeText = outcomeText
        self.age = age
        self.year = year
        self.karmaEffect = karmaEffect
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.eventId = try container.decode(String.self, forKey: .eventId)
        self.title = try container.decode(String.self, forKey: .title)
        self.choiceText = try container.decode(String.self, forKey: .choiceText)
        self.outcomeText = try container.decode(String.self, forKey: .outcomeText)
        self.age = try container.decode(Int.self, forKey: .age)
        self.year = try container.decode(Int.self, forKey: .year)
        self.karmaEffect = try container.decodeIfPresent(String.self, forKey: .karmaEffect)
    }
}
