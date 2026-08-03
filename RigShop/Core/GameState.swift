//
//  GameState.swift
//  RigShop
//
//  The whole game, as data plus four verbs:
//  buy, sell back, fulfill, advance day.
//
//  This type knows nothing about SwiftUI. Everything here is
//  deterministic given a seeded RNG, which is what makes the
//  30-day simulation test possible.
//
//  Do NOT import SwiftUI in this file.
//

import Foundation

// MARK: - Inventory

/// A part the shop owns, remembered at the price actually paid.
/// Without the paid price there is no cost basis, and "did I make
/// money on this build" has no answer.
struct StockItem: Identifiable, Codable, Hashable {
    let id: UUID
    let part: Part
    let paidPrice: Int

    init(id: UUID = UUID(), part: Part, paidPrice: Int) {
        self.id = id
        self.part = part
        self.paidPrice = paidPrice
    }
}

// MARK: - Market

struct MarketListing: Identifiable, Codable, Hashable {
    let part: Part
    /// Today's price. Base price times a daily swing.
    let todayPrice: Int
    var stock: Int

    var id: String { part.id }

    /// Percent off (negative) or over (positive) the reference price.
    var priceDelta: Int {
        guard part.basePrice > 0 else { return 0 }
        return (todayPrice - part.basePrice) * 100 / part.basePrice
    }
}

// MARK: - Results

enum FulfillmentError: Error, Equatable {
    case orderNotFound
    case incompatible([CompatibilityIssue])
    case partsNotInStock
}

struct FulfillmentResult: Equatable {
    let customerName: String
    let revenue: Int
    let cost: Int
    let satisfaction: Int
    let reputationChange: Int
    /// Non-nil when this order pushed the shop up a level.
    let newLevel: Int?

    var profit: Int { revenue - cost }
}

// MARK: - Game state

struct GameState: Codable {

    // MARK: Tuning

    static let startingCash = 3_000
    static let startingReputation = 50
    /// Fraction of base price recovered when dumping unsold stock.
    static let salvageRate = 60
    /// How many distinct parts the supplier offers each day.
    static let marketSize = 14

    // MARK: Stored

    var day: Int
    var cash: Int
    var reputation: Int
    /// Drives the level, which gates what the supplier will carry.
    var completedOrders: Int
    var inventory: [StockItem]
    var market: [MarketListing]
    var orders: [CustomerOrder]
    /// Newest first. Trimmed so saves don't grow forever.
    var log: [String]

    // MARK: Init

    init(day: Int = 1,
         cash: Int = GameState.startingCash,
         reputation: Int = GameState.startingReputation,
         completedOrders: Int = 0,
         inventory: [StockItem] = [],
         market: [MarketListing] = [],
         orders: [CustomerOrder] = [],
         log: [String] = []) {
        self.day = day
        self.cash = cash
        self.reputation = reputation
        self.completedOrders = completedOrders
        self.inventory = inventory
        self.market = market
        self.orders = orders
        self.log = log
    }

    /// A fresh game with day 1's market and customers already rolled.
    static func newGame(using rng: inout RandomNumberGenerator) -> GameState {
        var state = GameState()
        state.market = GameState.rollMarket(level: state.level, using: &rng)
        state.orders = GameState.rollCustomers(reputation: state.reputation,
                                               level: state.level,
                                               using: &rng)
        state.note("Day 1. You have \(state.cash.money) and a shop full of empty shelves.")
        return state
    }

    // MARK: - Derived

    /// Computed, never stored — a save file can't drift out of sync with
    /// the level curve if the level is always recalculated from orders.
    var level: Int { ShopLevel.level(forCompletedOrders: completedOrders) }

    var ordersToNextLevel: Int? { ShopLevel.ordersToNextLevel(completed: completedOrders) }

    var levelProgress: Double { ShopLevel.progress(completed: completedOrders) }

    var inventoryValue: Int {
        inventory.reduce(0) { $0 + $1.part.salvageValue }
    }

    /// Stock grouped by category, for the build screen.
    func stock(in category: PartCategory) -> [StockItem] {
        inventory.filter { $0.part.category == category }
    }

    // MARK: - Action: buy

    @discardableResult
    mutating func buy(_ listing: MarketListing) -> Bool {
        guard let index = market.firstIndex(where: { $0.id == listing.id }) else { return false }
        guard market[index].stock > 0 else { return false }
        let price = market[index].todayPrice
        guard cash >= price else { return false }

        cash -= price
        market[index].stock -= 1
        inventory.append(StockItem(part: listing.part, paidPrice: price))
        note("Bought \(listing.part.name) for \(price.money).")
        return true
    }

    // MARK: - Action: sell back

    @discardableResult
    mutating func sellBack(_ item: StockItem) -> Bool {
        guard let index = inventory.firstIndex(where: { $0.id == item.id }) else { return false }
        let refund = item.part.basePrice * GameState.salvageRate / 100
        inventory.remove(at: index)
        cash += refund
        let loss = item.paidPrice - refund
        note("Dumped \(item.part.name) for \(refund.money) (lost \(loss.money)).")
        return true
    }

    // MARK: - Action: fulfill

    /// Hand a finished machine to a customer.
    /// `stockIDs` identifies which physical units leave the shelf —
    /// two identical GPUs bought on different days cost different amounts.
    mutating func fulfill(orderID: UUID,
                          using stockIDs: [UUID]) -> Result<FulfillmentResult, FulfillmentError> {
        guard let orderIndex = orders.firstIndex(where: { $0.id == orderID }) else {
            return .failure(.orderNotFound)
        }
        let order = orders[orderIndex]

        // Resolve the chosen stock items.
        var chosen: [StockItem] = []
        for id in stockIDs {
            guard let item = inventory.first(where: { $0.id == id }) else {
                return .failure(.partsNotInStock)
            }
            chosen.append(item)
        }

        // Assemble and validate.
        var build = PCBuild()
        for item in chosen {
            build[item.part.category] = item.part
        }
        let issues = Compatibility.check(build)
        guard issues.isEmpty else { return .failure(.incompatible(issues)) }

        // Money and mood.
        let cost = chosen.reduce(0) { $0 + $1.paidPrice }
        let revenue = order.budget
        let satisfaction = Scoring.satisfaction(build: build, order: order)
        let repChange = Scoring.reputationChange(satisfaction: satisfaction)

        // Commit.
        inventory.removeAll { item in stockIDs.contains(item.id) }
        orders.remove(at: orderIndex)
        cash += revenue
        reputation = (reputation + repChange).clamped(to: 0...100)

        let levelBefore = level
        completedOrders += 1
        let levelAfter = level

        let profit = revenue - cost
        note("\(order.name) paid \(revenue.money). Profit \(profit.money), satisfaction \(satisfaction)%.")

        if levelAfter > levelBefore {
            let arrivals = PartCatalog.newlyUnlocked(at: levelAfter)
            if arrivals.isEmpty {
                note("Level \(levelAfter). Word is getting around.")
            } else {
                let names = arrivals.prefix(3).map(\.name).joined(separator: ", ")
                let extra = arrivals.count > 3 ? " and \(arrivals.count - 3) more" : ""
                note("Level \(levelAfter)! The supplier now carries \(names)\(extra).")
            }
        }

        return .success(FulfillmentResult(customerName: order.name,
                                          revenue: revenue,
                                          cost: cost,
                                          satisfaction: satisfaction,
                                          reputationChange: repChange,
                                          newLevel: levelAfter > levelBefore ? levelAfter : nil))
    }

    // MARK: - Action: advance day

    mutating func advanceDay(using rng: inout RandomNumberGenerator) {
        // Age every open order; drop the ones who gave up.
        for index in orders.indices {
            orders[index].daysWaiting += 1
        }
        let walkouts = orders.filter(\.isExpired)
        if !walkouts.isEmpty {
            orders.removeAll(where: \.isExpired)
            let penalty = Scoring.expiredOrderPenalty * walkouts.count
            reputation = (reputation + penalty).clamped(to: 0...100)
            for customer in walkouts {
                note("\(customer.name) got tired of waiting and left.")
            }
        }

        day += 1
        market = GameState.rollMarket(level: level, using: &rng)
        orders.append(contentsOf: GameState.rollCustomers(reputation: reputation,
                                                          level: level,
                                                          using: &rng))
        note("Day \(day). Cash \(cash.money), reputation \(reputation).")
    }

    // MARK: - Rolling

    static func rollMarket(level: Int, using rng: inout RandomNumberGenerator) -> [MarketListing] {
        // Always offer at least one part from every category, so the
        // player can never be structurally locked out of building.
        var picked: [Part] = []
        for category in PartCategory.allCases {
            if let part = PartCatalog.parts(in: category, unlockedAt: level)
                .randomElement(using: &rng) {
                picked.append(part)
            }
        }
        let rest = PartCatalog.unlocked(at: level)
            .filter { part in !picked.contains(where: { $0.id == part.id }) }
            .shuffled(using: &rng)
            .prefix(max(0, marketSize - picked.count))
        picked.append(contentsOf: rest)

        return picked.map { part in
            let swing = Int.random(in: 85...120, using: &rng)
            let price = max(1, part.basePrice * swing / 100)
            return MarketListing(part: part,
                                 todayPrice: price,
                                 stock: Int.random(in: 1...3, using: &rng))
        }
    }

    static func rollCustomers(reputation: Int,
                              level: Int,
                              using rng: inout RandomNumberGenerator) -> [CustomerOrder] {
        let count = OrderGenerator.customerCount(reputation: reputation, using: &rng)
        return (0..<count).compactMap { _ in
            OrderGenerator.makeOrder(reputation: reputation, level: level, using: &rng)
        }
    }

    // MARK: - Log

    mutating func note(_ line: String) {
        log.insert(line, at: 0)
        if log.count > 60 { log.removeLast(log.count - 60) }
    }
}

// MARK: - Utility

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
