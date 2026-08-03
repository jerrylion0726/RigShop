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
        XCTAssertEqual(state.completedOrders, 0)
        XCTAssertEqual(state.level, 1)
        XCTAssertTrue(state.inventory.isEmpty)
        XCTAssertFalse(state.market.isEmpty)
        XCTAssertFalse(state.orders.isEmpty)
    }

    /// The player must never be structurally unable to build.
    func testMarketAlwaysOffersEveryCategory() {
        var rng = makeRNG()
        for level in 1...ShopLevel.maxLevel {
            for _ in 0..<40 {
                let market = GameState.rollMarket(level: level, using: &rng)
                for category in PartCategory.allCases {
                    XCTAssertTrue(market.contains { $0.part.category == category },
                                  "Level \(level) market has no \(category.rawValue)")
                }
            }
        }
    }

    /// The whole point of the unlock ladder.
    func testMarketNeverOffersLockedParts() {
        var rng = makeRNG()
        for level in 1...ShopLevel.maxLevel {
            for _ in 0..<40 {
                let market = GameState.rollMarket(level: level, using: &rng)
                for listing in market {
                    XCTAssertLessThanOrEqual(listing.part.unlockLevel, level,
                                             "\(listing.part.name) leaked in at level \(level)")
                }
            }
        }
    }

    func testTopTierPartsAreNotAvailableEarly() {
        var rng = makeRNG(99)
        for _ in 0..<80 {
            let market = GameState.rollMarket(level: 1, using: &rng)
            XCTAssertFalse(market.contains { $0.part.id == "gpu-rtx5090" },
                           "A level-1 shop should not be selling a 5090")
        }
    }

    // MARK: - Levels

    func testLevelClimbsWithCompletedOrders() {
        XCTAssertEqual(ShopLevel.level(forCompletedOrders: 0), 1)
        XCTAssertEqual(ShopLevel.level(forCompletedOrders: 2), 1)
        XCTAssertEqual(ShopLevel.level(forCompletedOrders: 3), 2)
        XCTAssertEqual(ShopLevel.level(forCompletedOrders: 18), 5)
        XCTAssertEqual(ShopLevel.level(forCompletedOrders: 65), 10)
        XCTAssertEqual(ShopLevel.level(forCompletedOrders: 500), ShopLevel.maxLevel,
                       "The ladder should stop at the top, not keep climbing")
    }

    func testLevelThresholdsOnlyIncrease() {
        for index in 1..<ShopLevel.thresholds.count {
            XCTAssertGreaterThan(ShopLevel.thresholds[index], ShopLevel.thresholds[index - 1])
        }
    }

    func testProgressStaysInRange() {
        for completed in 0...80 {
            let progress = ShopLevel.progress(completed: completed)
            XCTAssertTrue((0...1).contains(progress), "progress \(progress) at \(completed)")
        }
    }

    func testEveryLevelUnlocksSomething() {
        for level in 2...ShopLevel.maxLevel {
            XCTAssertFalse(PartCatalog.newlyUnlocked(at: level).isEmpty,
                           "Level \(level) unlocks nothing — that's a dead level-up")
        }
    }

    func testCheapestBuildUsesOnlyStarterParts() {
        let build = OrderGenerator.cheapestBuild
        XCTAssertTrue(build.isComplete)
        XCTAssertTrue(Compatibility.isValid(build))
        for part in build.parts {
            XCTAssertEqual(part.unlockLevel, 1,
                           "\(part.name) is not a starter part — the fallback would be locked")
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
            XCTAssertEqual(state.completedOrders, 1)
        }
    }

    func testThirdOrderLevelsTheShopUp() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)
        state.completedOrders = 2          // one short of level 2
        XCTAssertEqual(state.level, 1)

        let ids = stockAValidMachine(into: &state)
        let order = CustomerOrder(name: "Third", useCase: .office,
                                  budget: 1200, expectedScore: 30)
        state.orders = [order]

        guard case .success(let outcome) = state.fulfill(orderID: order.id, using: ids) else {
            return XCTFail("Fulfilment failed")
        }
        XCTAssertEqual(outcome.newLevel, 2)
        XCTAssertEqual(state.level, 2)
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
        XCTAssertEqual(state.completedOrders, 0, "A failed build must not count as progress")
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
            for order in state.orders {
                if let ids = greedySolution(for: order, in: &state, using: &rng) {
                    _ = state.fulfill(orderID: order.id, using: ids)
                }
            }
            state.advanceDay(using: &rng)

            XCTAssertGreaterThanOrEqual(state.cash, 0, "Cash went negative on day \(state.day)")
            XCTAssertTrue((0...100).contains(state.reputation))
            XCTAssertTrue((1...ShopLevel.maxLevel).contains(state.level))
            XCTAssertLessThan(state.orders.count, 40, "Orders are piling up unboundedly")
            XCTAssertLessThan(state.inventory.count, 200, "Inventory is growing unboundedly")
        }

        XCTAssertEqual(state.day, 31)
        XCTAssertFalse(state.log.isEmpty)
    }

    /// A shop that actually serves customers should climb the ladder.
    func testSimulationMakesProgressUpTheLadder() {
        var rng = makeRNG(777)
        var state = GameState.newGame(using: &rng)

        for _ in 0..<40 {
            for order in state.orders {
                if let ids = greedySolution(for: order, in: &state, using: &rng) {
                    _ = state.fulfill(orderID: order.id, using: ids)
                }
            }
            state.advanceDay(using: &rng)
        }

        XCTAssertGreaterThan(state.completedOrders, 10,
                             "Forty days of trading should close more than ten orders")
        XCTAssertGreaterThan(state.level, 1, "The shop never levelled up")
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
            if let owned = state.stock(in: category)
                .first(where: { Compatibility.canAdd($0.part, to: build) && !ids.contains($0.id) }) {
                build[category] = owned.part
                ids.append(owned.id)
                continue
            }
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
