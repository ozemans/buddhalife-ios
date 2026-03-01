import Foundation

struct GlossaryTerm: Codable, Identifiable {
    var id: String { term }
    let term: String
    let pali: String?
    let translation: String
    let description: String
    let countries: [String]?
}
