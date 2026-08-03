//
//  ShopLevel.swift
//  RigShop
//
//  Progression. The shop levels up by finishing orders, and each level
//  is a key to part of the catalogue.
//
//  The curve widens on purpose: early levels arrive fast so the shop
//  stops feeling empty, later ones take real work so the next-gen
//  hardware still means something when it lands.
//
//  Do NOT import SwiftUI in this file.
//

import Foundation

enum ShopLevel {

    /// Completed orders required to reach level (index + 1).
    static let thresholds = [0, 3, 7, 12, 18, 25, 33, 42, 52, 65]

    static var maxLevel: Int { thresholds.count }

    static func level(forCompletedOrders count: Int) -> Int {
        var level = 1
        for (index, threshold) in thresholds.enumerated() where count >= threshold {
            level = index + 1
        }
        return level
    }

    /// Orders still owed before the next level. `nil` at the top.
    static func ordersToNextLevel(completed: Int) -> Int? {
        let current = level(forCompletedOrders: completed)
        guard current < thresholds.count else { return nil }
        return thresholds[current] - completed
    }

    /// 0...1 through the current level, for a progress bar. 1 at the top.
    static func progress(completed: Int) -> Double {
        let current = level(forCompletedOrders: completed)
        guard current < thresholds.count else { return 1 }
        let floor = thresholds[current - 1]
        let ceiling = thresholds[current]
        guard ceiling > floor else { return 1 }
        return Double(completed - floor) / Double(ceiling - floor)
    }
}
