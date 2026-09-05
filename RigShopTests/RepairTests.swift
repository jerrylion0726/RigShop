//
//  RepairTests.swift
//  RigShopTests
//
//  Run with Cmd + U.
//

import XCTest
@testable import RigShop

final class RepairTests: XCTestCase {

    private func makeRNG(_ seed: UInt64 = 31415) -> RandomNumberGenerator {
        SeededGenerator(seed: seed)
    }

    private func part(_ id: String) -> Part {
        guard let part = PartCatalog.part(id: id) else { fatalError("Missing \(id)") }
        return part
    }

    /// A machine known to be valid: LGA1700 + DDR4 + a 750W supply.
    private func workingMachine() -> PCBuild {
        PCBuild(cpu: part("cpu-i5-13400f"),
                motherboard: part("mb-b660m-hdv"),
                memory: part("ram-lpx-16-ddr4"),
                gpu: part("gpu-rtx4060"),
                psu: part("psu-focus-750"))
    }

    // MARK: - Model

    func testOpenMachineHasTheDeadSlotEmpty() {
        let job = RepairJob(machine: workingMachine(), faults: [.gpu])
        XCTAssertNil(job.openMachine.gpu)
        XCTAssertNotNil(job.openMachine.cpu, "Only the dead slot should be emptied")
        XCTAssertEqual(job.openMachine.missingCategories, [.gpu])
    }

    func testSymptomIsSpecificToTheFault() {
        for category in PartCategory.allCases {
            let job = RepairJob(machine: workingMachine(), faults: [category])
            XCTAssertFalse(job.symptom.isEmpty)
            XCTAssertTrue(job.diagnosis.contains(category.displayName))
        }
    }

    func testScrapValueComesOnlyFromDeadParts() {
        let machine = workingMachine()
        let job = RepairJob(machine: machine, faults: [.gpu])
        XCTAssertEqual(job.scrapValue, machine.gpu!.basePrice * 10 / 100)
    }

    func testOrderReportsWhichSlotsNeedFilling() {
        let job = RepairJob(machine: workingMachine(), faults: [.psu])
        let order = CustomerOrder(name: "Test", useCase: .gaming,
                                  budget: 200, expectedScore: 40, repair: job)
        XCTAssertTrue(order.isRepair)
        XCTAssertEqual(order.slotsToFill, [.psu])

        let newBuild = CustomerOrder(name: "Test", useCase: .gaming,
                                     budget: 900, expectedScore: 40)
        XCTAssertFalse(newBuild.isRepair)
        XCTAssertEqual(newBuild.slotsToFill, PartCategory.buildOrder)
    }

    // MARK: - The reference fix

    /// Picking each replacement against the machine with every fault still
    /// open skips the wattage rule, which lets a hungry card and a small
    /// supply both pass on their own and fail together. The plan fills
    /// slots in order so power is decided last.
    func testPlanHandlesAGPUAndPSUFailingTogether() {
        let machine = workingMachine()
        let job = RepairJob(machine: machine, faults: [.gpu, .psu])

        guard let plan = OrderGenerator.repairPlan(for: job, level: 10) else {
            return XCTFail("No plan for a card and supply dying together")
        }

        var fixed = job.openMachine
        for (category, part) in plan { fixed[category] = part }
        XCTAssertTrue(Compatibility.isValid(fixed),
                      "The reference fix has to produce a machine that runs")
    }

    // MARK: - Generation

    /// The one that matters: every repair the game hands out must be
    /// fixable with parts the shop can actually buy, at a price that
    /// leaves money on the table.
    func testGeneratedRepairsAreFixableAndProfitable() {
        var rng = makeRNG()

        for level in [1, 3, 5, 8, 10] {
            for _ in 0..<120 {
                guard let order = OrderGenerator.makeRepair(reputation: 50,
                                                            level: level,
                                                            using: &rng) else {
                    XCTFail("Repair generator returned nil at level \(level)")
                    continue
                }
                guard let job = order.repair else {
                    return XCTFail("makeRepair produced a non-repair order")
                }

                XCTAssertTrue(job.machine.isComplete, "The machine brought in is incomplete")
                XCTAssertFalse(job.faults.isEmpty)

                guard let plan = OrderGenerator.repairPlan(for: job, level: level) else {
                    XCTFail("No reference fix exists at level \(level)")
                    continue
                }

                var fixed = job.openMachine
                var partsBill = 0
                for (category, replacement) in plan {
                    XCTAssertLessThanOrEqual(replacement.unlockLevel, level,
                                             "\(replacement.name) is still locked")
                    fixed[category] = replacement
                    partsBill += replacement.basePrice
                }

                XCTAssertTrue(Compatibility.isValid(fixed),
                              "The reference fix doesn't produce a working machine")
                XCTAssertGreaterThan(order.budget, partsBill,
                                     "The fee doesn't even cover parts")
            }
        }
    }

    func testRepairsAreCheaperToTakeOnThanNewBuilds() {
        var rng = makeRNG(2718)
        var repairParts = 0, repairCount = 0
        var buildParts = 0, buildCount = 0

        for _ in 0..<200 {
            if let repair = OrderGenerator.makeRepair(reputation: 50, level: 5, using: &rng),
               let job = repair.repair {
                repairParts += job.faults.compactMap { job.machine[$0]?.basePrice }.reduce(0, +)
                repairCount += 1
            }
            if let build = OrderGenerator.makeNewBuild(reputation: 50, level: 5, using: &rng) {
                buildParts += build.budget
                buildCount += 1
            }
        }

        XCTAssertGreaterThan(repairCount, 0)
        XCTAssertGreaterThan(buildCount, 0)
        XCTAssertLessThan(repairParts / max(1, repairCount),
                          buildParts / max(1, buildCount),
                          "Repairs should tie up less cash than new builds")
    }

    func testMixedWalkInsProduceBothKinds() {
        var rng = makeRNG(161803)
        var repairs = 0, builds = 0
        for _ in 0..<400 {
            guard let order = OrderGenerator.makeOrder(reputation: 50, level: 5, using: &rng)
            else { continue }
            if order.isRepair { repairs += 1 } else { builds += 1 }
        }
        XCTAssertGreaterThan(repairs, 40, "Repairs almost never show up")
        XCTAssertGreaterThan(builds, 40, "New builds almost never show up")
    }

    // MARK: - Fulfilment

    func testRepairPaysFeePlusScrapAndOnlyChargesForNewParts() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)

        let machine = workingMachine()
        let job = RepairJob(machine: machine, faults: [.gpu])
        let order = CustomerOrder(name: "Rosa T.", useCase: .gaming,
                                  budget: 380,
                                  expectedScore: Scoring.weightedScore(of: machine, for: .gaming),
                                  repair: job)
        state.orders = [order]

        // The shop supplies one graphics card, nothing else.
        let replacement = StockItem(part: part("gpu-rtx4060"), paidPrice: 290)
        state.inventory = [replacement]
        let cashBefore = state.cash

        switch state.fulfill(orderID: order.id, using: [replacement.id]) {
        case .failure(let error):
            XCTFail("Should have succeeded, got \(error)")
        case .success(let outcome):
            XCTAssertTrue(outcome.wasRepair)
            XCTAssertEqual(outcome.cost, 290, "Only the part the shop supplied should count")
            XCTAssertEqual(outcome.scrap, job.scrapValue)
            XCTAssertEqual(state.cash, cashBefore + 380 + job.scrapValue)
            // Restoring the machine exactly lands on the target, and hitting
            // the target exactly scores 80 — the band above it is reserved
            // for genuinely exceeding what they asked for.
            XCTAssertGreaterThanOrEqual(outcome.satisfaction, 80,
                                        "Like-for-like should read as a good job")
            XCTAssertTrue(state.inventory.isEmpty)
            XCTAssertEqual(state.completedOrders, 1)
        }
    }

    func testRepairRefusesAnIncompatibleReplacement() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)

        // Their board is LGA1700; hand over an AM5 processor.
        let job = RepairJob(machine: workingMachine(), faults: [.cpu])
        let order = CustomerOrder(name: "Test", useCase: .office,
                                  budget: 400, expectedScore: 40, repair: job)
        state.orders = [order]

        let wrong = StockItem(part: part("cpu-r7-7700x"), paidPrice: 280)
        state.inventory = [wrong]

        guard case .failure(.incompatible(let issues)) =
                state.fulfill(orderID: order.id, using: [wrong.id]) else {
            return XCTFail("An AM5 chip should not go into an LGA1700 board")
        }
        XCTAssertTrue(issues.contains(.socketMismatch(cpu: .am5, board: .lga1700)))
        XCTAssertEqual(state.inventory.count, 1, "Nothing should leave the shelf on failure")
        XCTAssertEqual(state.orders.count, 1)
    }

    func testRepairRefusesAnUnfilledFault() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)

        let job = RepairJob(machine: workingMachine(), faults: [.psu])
        let order = CustomerOrder(name: "Test", useCase: .office,
                                  budget: 200, expectedScore: 40, repair: job)
        state.orders = [order]

        guard case .failure(.faultNotReplaced(let category)) =
                state.fulfill(orderID: order.id, using: []) else {
            return XCTFail("Handing back a machine with the dead part still in it should fail")
        }
        XCTAssertEqual(category, .psu)
    }

    /// Fitting something weaker than what died is allowed — it just
    /// disappoints, which is the interesting trade-off.
    func testDowngradeIsAllowedButDisappoints() {
        var rng = makeRNG()
        var state = GameState.newGame(using: &rng)

        let machine = workingMachine()   // RTX 4060, score 45
        let job = RepairJob(machine: machine, faults: [.gpu])
        let order = CustomerOrder(name: "Test", useCase: .gaming,
                                  budget: 380,
                                  expectedScore: Scoring.weightedScore(of: machine, for: .gaming),
                                  repair: job)
        state.orders = [order]

        let cheap = StockItem(part: part("gpu-gtx1630"), paidPrice: 105)  // score 12
        state.inventory = [cheap]

        guard case .success(let outcome) =
                state.fulfill(orderID: order.id, using: [cheap.id]) else {
            return XCTFail("A weaker card still makes the machine run")
        }
        XCTAssertLessThan(outcome.satisfaction, 60,
                          "Slipping a much weaker card in should be noticed")
        XCTAssertGreaterThan(outcome.profit, 0, "It is at least profitable in the short run")
    }
}
