//
//  GameStore.swift
//  RigShop
//
//  The bridge between Core/ and Views/. Owns the one mutable copy of
//  GameState and the random number generator, and exposes the four
//  verbs as plain methods.
//
//  Nothing in Core/ knows this file exists.
//

import Foundation
import Observation

@Observable
final class GameStore {

    /// Views read this. Only GameStore mutates it.
    private(set) var state: GameState

    /// Kept as a stored property so the sequence continues across days
    /// instead of restarting. Swap in a seeded generator here if you
    /// ever want a "daily challenge" mode where everyone gets the same
    /// market and customers.
    @ObservationIgnored
    private var rng: RandomNumberGenerator = SystemRandomNumberGenerator()

    init() {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        self.state = GameState.newGame(using: &generator)
        self.rng = generator
    }

    // MARK: - Actions

    @discardableResult
    func buy(_ listing: MarketListing) -> Bool {
        state.buy(listing)
    }

    /// Buy and hand back the unit that landed on the shelf, so the build
    /// screen can drop it straight into a slot. Buying and then hunting
    /// for "the one I just bought" would be guesswork — two identical
    /// cards bought on different days are different units at different
    /// cost bases.
    func buyForBuild(_ listing: MarketListing) -> StockItem? {
        guard state.buy(listing) else { return nil }
        return state.inventory.last
    }

    @discardableResult
    func sellBack(_ item: StockItem) -> Bool {
        state.sellBack(item)
    }

    func fulfill(orderID: UUID,
                 using stockIDs: [UUID]) -> Result<FulfillmentResult, FulfillmentError> {
        state.fulfill(orderID: orderID, using: stockIDs)
    }

    func advanceDay() {
        state.advanceDay(using: &rng)
    }

    func startNewGame() {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        state = GameState.newGame(using: &generator)
        rng = generator
    }

    // MARK: - Queries the UI asks a lot

    func canAfford(_ listing: MarketListing) -> Bool {
        state.cash >= listing.todayPrice && listing.stock > 0
    }

    /// Why a Buy button is disabled, or nil when it isn't.
    func blockReason(for listing: MarketListing) -> String? {
        if listing.stock == 0 { return "Out of stock" }
        if state.cash < listing.todayPrice { return "Not enough cash" }
        return nil
    }

    /// Today's offers, grouped for a sectioned list.
    var marketByCategory: [(category: PartCategory, listings: [MarketListing])] {
        PartCategory.buildOrder.compactMap { category in
            let listings = state.market
                .filter { $0.part.category == category }
                .sorted { $0.todayPrice < $1.todayPrice }
            return listings.isEmpty ? nil : (category, listings)
        }
    }
}
