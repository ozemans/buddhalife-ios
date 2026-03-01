import Foundation

struct Stats: Codable, Equatable {
    var health: Int = 100
    var happiness: Int = 50
    var wealth: Int = 50
    var wisdom: Int = 0
    var socialStanding: Int = 50
    var spiritualDev: Int = 0

    mutating func apply(changes: [String: Int]) {
        for (key, delta) in changes {
            switch key {
            case "health": health = clamp(health + delta, max: 100)
            case "happiness": happiness = clamp(happiness + delta, max: 100)
            case "wealth": wealth = clamp(wealth + delta, max: 200)
            case "wisdom": wisdom = clamp(wisdom + delta, max: 100)
            case "socialStanding": socialStanding = clamp(socialStanding + delta, max: 100)
            case "spiritualDev": spiritualDev = clamp(spiritualDev + delta, max: 100)
            default: break
            }
        }
    }

    private func clamp(_ value: Int, max: Int) -> Int {
        Swift.max(0, Swift.min(max, value))
    }
}
