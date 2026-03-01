import Foundation

struct Karma: Codable, Equatable {
    var merit: Double = 0
    var demerit: Double = 0
    var momentum: Double = 0
    var uncertainty: Double = 0.1
}
