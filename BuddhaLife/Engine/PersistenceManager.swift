import Foundation

// MARK: - PersistenceManager

/// Handles saving and loading game state to the Application Support directory.
/// Ported from the localStorage-based persistence in gameState.js.
struct PersistenceManager {

    private static let fileName = "buddhalife_save.json"

    // MARK: - File Path

    /// The full path to the save file in Application Support.
    private static var saveFileURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        // Ensure the directory exists
        try? FileManager.default.createDirectory(
            at: appSupport,
            withIntermediateDirectories: true
        )
        return appSupport.appendingPathComponent(fileName)
    }

    // MARK: - Public API

    /// Save the current game state to disk.
    /// Only saves when the game is in a playing or event state (caller should check).
    static func save(_ state: SavedState) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(state)
            try data.write(to: saveFileURL, options: .atomic)
        } catch {
            // Silently ignore write errors (mirrors JS behavior)
        }
    }

    /// Load a saved game state from disk, if one exists and is valid.
    static func load() -> SavedState? {
        let url = saveFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let state = try decoder.decode(SavedState.self, from: data)
            // Basic validity check: must have a screen and character with a name
            guard !state.character.name.isEmpty else { return nil }
            return state
        } catch {
            return nil
        }
    }

    /// Delete the save file.
    static func clear() {
        try? FileManager.default.removeItem(at: saveFileURL)
    }

    /// Check if a save file exists on disk.
    static func hasSave() -> Bool {
        FileManager.default.fileExists(atPath: saveFileURL.path)
    }
}
