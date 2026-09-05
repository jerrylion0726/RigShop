//
//  SaveStore.swift
//  RigShop
//
//  Local persistence. One JSON file in Documents.
//
//  Deliberately not iCloud: that needs a paid developer account, and
//  cross-device sync isn't the problem. The problem is that closing the
//  app used to wipe the shop.
//
//  GameState stores whole `Part` values rather than catalogue ids, which
//  costs a few bytes and buys immunity: an old save still decodes after
//  the catalogue is rebalanced or a part is removed.
//
//  Do NOT import SwiftUI in this file.
//

import Foundation

enum SaveStore {

    private static let filename = "rigshop-save.json"

    private static var url: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(filename)
    }

    static var hasSave: Bool {
        guard let url else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    static func save(_ state: GameState) {
        guard let url else { return }
        do {
            let data = try JSONEncoder().encode(state)
            // Atomic so a crash mid-write can't leave a half-file behind.
            try data.write(to: url, options: .atomic)
        } catch {
            // A failed save shouldn't take the game down with it.
            print("Save failed: \(error)")
        }
    }

    static func load() -> GameState? {
        guard let url, FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(GameState.self, from: data)
        } catch {
            // A save from an incompatible build is worse than no save.
            print("Load failed, discarding: \(error)")
            clear()
            return nil
        }
    }

    static func clear() {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
