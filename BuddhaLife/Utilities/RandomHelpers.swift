import Foundation

/// Return a random integer between min and max (inclusive)
func randBetween(_ min: Int, _ max: Int) -> Int {
    guard max > min else { return min }
    return Int.random(in: min...max)
}

/// Return a random double between min and max
func randDoubleBetween(_ min: Double, _ max: Double) -> Double {
    Double.random(in: min...max)
}

/// Return true with the given probability (0.0 to 1.0)
func chance(_ probability: Double) -> Bool {
    Double.random(in: 0..<1) < probability
}

/// Pick a random element from an array
func pickRandom<T>(_ array: [T]) -> T? {
    array.randomElement()
}

/// Weighted random selection. Returns the index of the chosen item.
func weightedRandom(weights: [Double]) -> Int {
    let total = weights.reduce(0, +)
    guard total > 0 else { return 0 }
    var roll = Double.random(in: 0..<total)
    for (i, w) in weights.enumerated() {
        roll -= w
        if roll <= 0 { return i }
    }
    return weights.count - 1
}
