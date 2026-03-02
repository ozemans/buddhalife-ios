import Foundation

struct Relationship: Codable, Equatable, Identifiable {
    var id: String { name }
    var name: String
    var type: String        // "family", "friend", "mentor", "rival"
    var role: String?       // "mother", "father", "sibling", "monk", "childhood_friend"
    var affinity: Int = 50  // 0-100
    var description: String = ""
    var alive: Bool = true
}
