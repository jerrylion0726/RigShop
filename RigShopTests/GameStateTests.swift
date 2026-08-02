//
//  GameStateTests.swift
//  RigShopTests
//
//  Run with Cmd + U.
//

import XCTest
@testable import RigShop

final class GameStateTests: XCTestCase {

    private func makeRNG(_ seed: UInt64 = 20260802) -> RandomNumberGenerator {
        SeededGenerator(seed: seed)
    }

    private func part(_ id: String) -> Part {
        guard let part = PartCatalog.part(id: id) else { fatalError("Missing \(id)") }
        return part
    }

    // MARK: - New game

    func testNewGameStartsSane() {
        var rng = makeRNG()
        let state = GameState.newGame(using: &rng)

        XCTAssertEqual(state.day, 1)
        XCTAssertEqual(state.cash, GameState.startingCash)
        XCTAssertEqual(state.reputation, GameState.startingReputation)
        XCTAssertTrue(state.inventory.isEmpty)
        XCTAssertFalse(state.market.isEmpty)
        XCTAssertFalse(state.orders.isEmpty)
    }

    /// The player must never be structurally unable to build.
    func testMarketAlwaysOffersEveryCategory() {
        var rng = makeRNG()
        for _ in 0..<200 {
            let market = GameState.rollMarket(using: &rng)
            for category in PartCategory.allCases {
                XCTAssertTrue(market.contains { $0.part.category == category },
                              "Market has no \(category.rawValue)")
            }
        }
    }

    // MARK: - Buying

    func testBuyMovesCashIntoInventory() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)
        let listing = state.market[0]
        let before = state.cash

        XCTAssertTrue(state.buy(listing))
        XCTAssertEqual(state.cash, before - listing.todayPrice)
        XCTAssertEqual(state.inventory.count, 1)
        XCTAssertEqual(state.inventory[0].paidPrice, listing.todayPrice)
    }

    func testCannotBuyWithoutCash() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)
        state.cash = 0
        XCTAssertFalse(state.buy(state.market[0]))
        XCTAssertTrue(state.inventory.isEmpty)
    }

    func testCannotBuyMoreThanStock() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)
        let listing = state.market[0]
        let available = listing.stock

        for _ in 0..<available { XCTAssertTrue(state.buy(listing)) }
        XCTAssertFalse(state.buy(listing), "Bought past the supplier's stock")
    }

    // MARK: - Selling back

    func testSellBackRecoversPartOfTheMoney() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)
        state.buy(state.market[0])
        let item = state.inventory[0]
        let before = state.cash

        XCTAssertTrue(state.sellBack(item))
        XCTAssertTrue(state.inventory.isEmpty)
        XCTAssertEqual(state.cash, before + item.part.salvageValue)
        XCTAssertLessThan(item.part.salvageValue, item.part.basePrice,
                          "Dumping stock should always be a loss")
    }

    // MARK: - Fulfilling

    /// Put a specific, known-good machine into inventory and hand it over.
    private func stockAValidMachine(into state: inout GameState) -> [UUID] {
        let parts = [part("cpu-i5-13400f"),
                     part("mb-b660m-hdv"),
                     part("ram-lpx-16-ddr4"),
                     part("gpu-rtx4060"),
                     part("psu-focus-750")]
        var ids: [UUID] = []
        for p in parts {
            let item = StockItem(part: p, paidPrice: p.basePrice)
            state.inventory.append(item)
            ids.append(item.id)
        }
        return ids
    }

    func testFulfillPaysAndClearsInventory() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)
        let ids = stockAValidMachine(into: &state)

        // Give the customer an expectation this machine comfortably meets.
        let order = CustomerOrder(name: "Test Buyer", useCase: .gaming,
                                  budget: 1200, expectedScore: 30)
        state.orders = [order]
        let cashBefore = state.cash

        let result = state.fulfill(orderID: order.id, using: ids)

        switch result {
        case .failure(let error):
            XCTFail("Should have succeeded, got \(error)")
        case .success(let outcome):
            XCTAssertEqual(outcome.revenue, 1200)
            XCTAssertEqual(state.cash, cashBefore + 1200)
            XCTAssertTrue(state.inventory.isEmpty, "Parts should leave the shelf")
            XCTAssertTrue(state.orders.isEmpty, "Order should be closed")
            XCTAssertEqual(outcome.satisfaction, 100)
            XCTAssertGreaterThan(outcome.profit, 0)
        }
    }

    func testFulfillRejectsIncompatibleBuild() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)

        // AM5 CPU on an LGA1700 board.
        let parts = [part("cpu-r7-7700x"),
                     part("mb-b660m-hdv"),
                     part("ram-lpx-16-ddr4"),
                     part("gpu-rtx4060"),
                     part("psu-focus-750")]
        var ids: [UUID] = []
        for p in parts {
            let item = StockItem(part: p, paidPrice: p.basePrice)
            state.inventory.append(item)
            ids.append(item.id)
        }

        let order = CustomerOrder(name: "Test", useCase: .gaming,
                                  budget: 1200, expectedScore: 30)
        state.orders = [order]

        let result = state.fulfill(orderID: order.id, using: ids)
        guard case .failure(.incompatible(let issues)) = result else {
            return XCTFail("Should have been rejected")
        }
        XCTAssertTrue(issues.contains(.socketMismatch(cpu: .am5, board: .lga1700)))
        XCTAssertEqual(state.inventory.count, 5, "Nothing should leave the shelf on failure")
        XCTAssertEqual(state.orders.count, 1, "The order should still be open")
    }

    // MARK: - Day advance

    func testCustomersLeaveAfterWaitingTooLong() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)
        state.orders = [CustomerOrder(name: "Impatient", useCase: .office,
                                      budget: 800, expectedScore: 30)]
        let repBefore = state.reputation

        for _ in 0..<CustomerOrder.patience {
            state.advanceDay(using: &rng)
        }

        XCTAssertFalse(state.orders.contains { $0.name == "Impatient" })
        XCTAssertLessThan(state.reputation, repBefore, "Walkouts should cost reputation")
    }

    func testReputationNeverLeavesZeroToHundred() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)

        state.reputation = 2
        for _ in 0..<20 {
            state.orders = [CustomerOrder(name: "X", useCase: .office,
                                          budget: 500, expectedScore: 30)]
            for _ in 0..<CustomerOrder.patience { state.advanceDay(using: &rng) }
            XCTAssertTrue((0...100).contains(state.reputation))
        }
    }

    // MARK: - The big one

    /// Play thirty days automatically with a greedy strategy and check
    /// the economy doesn't collapse or run away. This is the test that
    /// catches balance problems before they reach the screen.
    func testThirtyDaySimulationStaysStable() {
        var rng = makeRNG(4242)
        var state = GameState.newGame(using: &rng)

        for _ in 0..<30 {
            // Try each open order, cheapest satisfying machine first.
            for order in state.orders {
                if let ids = greedySolution(for: order, in: &state, using: &rng) {
                    _ = state.fulfill(orderID: order.id, using: ids)
                }
            }
            state.advanceDay(using: &rng)

            XCTAssertGreaterThanOrEqual(state.cash, 0, "Cash went negative on day \(state.day)")
            XCTAssertTrue((0...100).contains(state.reputation))
            XCTAssertLessThan(state.orders.count, 40, "Orders are piling up unboundedly")
            XCTAssertLessThan(state.inventory.count, 200, "Inventory is growing unboundedly")
        }

        XCTAssertEqual(state.day, 31)
        XCTAssertFalse(state.log.isEmpty)
    }

    /// Buy whatever is needed, cheapest first, to satisfy one order.
    /// Deliberately dumb — the point is to exercise the state machine,
    /// not to play well.
    private func greedySolution(for order: CustomerOrder,
                                in state: inout GameState,
                                using rng: inout RandomNumberGenerator) -> [UUID]? {
        var build = PCBuild()
        var ids: [UUID] = []

        for category in PartCategory.buildOrder {
            // Prefer something already on the shelf that fits.
            if let owned = state.stock(in: category)
                .first(where: { Compatibility.canAdd($0.part, to: build) && !ids.contains($0.id) }) {
                build[category] = owned.part
                ids.append(owned.id)
                continue
            }
            // Otherwise buy the cheapest compatible listing we can afford.
            let options = state.market
                .filter { $0.part.category == category
                        && $0.stock > 0
                        && $0.todayPrice <= state.cash
                        && Compatibility.canAdd($0.part, to: build) }
                .sorted { $0.todayPrice < $1.todayPrice }

            guard let pick = options.first, state.buy(pick) else { return nil }
            guard let bought = state.inventory.last else { return nil }
            build[category] = bought.part
            ids.append(bought.id)
        }

        return Compatibility.isValid(build) ? ids : nil
    }
}
