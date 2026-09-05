//
//  GameStore.swift
//  RigShop
//
//  The bridge between Core/ and Views/. Owns the one mutable copy of
//  GameState and the random number generator, and exposes the verbs as
//  plain methods.
//
//  It also owns persistence: every action that changes the shop writes
//  the save immediately. There's no "save" button because forgetting to
//  press one is not an interesting failure mode.
//
//  Nothing in Core/ knows this file exists.
//

import Foundation
import Observation

@Observable
final class GameStore {

    /// Views read this. Only GameStore mutates it.
    private(set) var state: GameState

    /// True when the state came off disk rather than being freshly rolled.
    private(set) var loadedFromSave: Bool

    /// Kept as a stored property so the sequence continues across days
    /// instead of restarting. Swap in a seeded generator here if you
    /// ever want a "daily challenge" mode where everyone gets the same
    /// market and customers.
    @ObservationIgnored
    private var rng: RandomNumberGenerator = SystemRandomNumberGenerator()

    init() {
        if let saved = SaveStore.load() {
            state = saved
            loadedFromSave = true
        } else {
            var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
            state = GameState.newGame(using: &generator)
            rng = generator
            loadedFromSave = false
        }
    }

    // MARK: - Actions

    @discardableResult
    func buy(_ listing: MarketListing) -> Bool {
        let ok = state.buy(listing)
        if ok { persist() }
        return ok
    }

    /// Buy and hand back the unit that landed on the shelf, so the build
    /// screen can drop it straight into a slot. Buying and then hunting
    /// for "the one I just bought" would be guesswork — two identical
    /// cards bought on different days are different units at different
    /// cost bases.
    func buyForBuild(_ listing: MarketListing) -> StockItem? {
        guard state.buy(listing) else { return nil }
        persist()
        return state.inventory.last
    }

    @discardableResult
    func sellBack(_ item: StockItem) -> Bool {
        let ok = state.sellBack(item)
        if ok { persist() }
        return ok
    }

    func fulfill(orderID: UUID,
                 using stockIDs: [UUID]) -> Result<FulfillmentResult, FulfillmentError> {
        let result = state.fulfill(orderID: orderID, using: stockIDs)
        if case .success = result { persist() }
        return result
    }

    func advanceDay() {
        state.advanceDay(using: &rng)
        persist()
    }

    func startNewGame() {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        state = GameState.newGame(using: &generator)
        rng = generator
        loadedFromSave = false
        persist()
    }

    /// Called when the app goes to the background, as a belt-and-braces
    /// write in case something changed outside the action methods.
    func persist() {
        SaveStore.save(state)
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
