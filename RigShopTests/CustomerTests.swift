//
//  CustomerTests.swift
//  RigShopTests
//
//  Run with Cmd + U.
//

import XCTest
@testable import RigShop

final class CustomerTests: XCTestCase {

    private func part(_ id: String) -> Part {
        guard let part = PartCatalog.part(id: id) else {
            fatalError("Catalog is missing \(id)")
        }
        return part
    }

    // MARK: - Weights

    func testUseCaseWeightsSumToOne() {
        for useCase in UseCase.allCases {
            let total = PartCategory.allCases.reduce(0.0) { $0 + useCase.weight(for: $1) }
            XCTAssertEqual(total, 1.0, accuracy: 0.0001,
                           "\(useCase.rawValue) weights don't sum to 1")
        }
    }

    func testEverySlotCarriesSomeWeight() {
        for useCase in UseCase.allCases {
            for category in PartCategory.allCases {
                XCTAssertGreaterThan(useCase.weight(for: category), 0,
                                     "\(category.rawValue) is dead weight for \(useCase.rawValue)")
            }
        }
    }

    func testProcessorAndCardStillDominate() {
        for useCase in UseCase.allCases {
            let big = useCase.weight(for: .cpu) + useCase.weight(for: .gpu)
            XCTAssertGreaterThan(big, 0.6,
                                 "\(useCase.rawValue) leans too little on the two big levers")
        }
    }

    /// The whole point of use cases: same build, different verdicts.
    func testSameBuildScoresDifferentlyPerUseCase() {
        // Weak processor, strong card.
        let build = PCBuild(cpu: part("cpu-i3-12100f"),      // 32
                            gpu: part("gpu-rtx4070"))        // 68

        let gaming = Scoring.weightedScore(of: build, for: .gaming)
        let office = Scoring.weightedScore(of: build, for: .office)

        XCTAssertGreaterThan(gaming, office,
                             "A card-heavy build should suit gaming better than office work")
    }

    /// Starving a good machine of memory has to cost it. This is the
    /// reason memory scores at all.
    func testWeakMemoryDragsDownAStrongMachine() {
        let base = PCBuild(cpu: part("cpu-i7-13700kf"),
                           motherboard: part("mb-z790-plus"),
                           gpu: part("gpu-rtx4070"),
                           psu: part("psu-rm850x"))

        var starved = base
        starved.memory = part("ram-crucial-8-ddr4")          // 15
        var healthy = base
        healthy.memory = part("ram-tridentz5-32-ddr5")       // 78

        for useCase in UseCase.allCases {
            XCTAssertLessThan(Scoring.weightedScore(of: starved, for: useCase),
                              Scoring.weightedScore(of: healthy, for: useCase),
                              "8GB should hold \(useCase.rawValue) back")
        }
    }

    /// Cheap board and supply are a real, if small, drag.
    func testBoardAndSupplyQualityMove_theNeedle() {
        let base = PCBuild(cpu: part("cpu-i5-13400f"),
                           memory: part("ram-ripjaws-32-ddr4"),
                           gpu: part("gpu-rtx4060"))

        var budget = base
        budget.motherboard = part("mb-b660m-hdv")            // 25
        budget.psu = part("psu-evga-500")                    // 18

        var better = base
        better.motherboard = part("mb-b760-gaming-x-ddr4")   // 45
        better.psu = part("psu-focus-750")                   // 62

        XCTAssertGreaterThan(Scoring.weightedScore(of: better, for: .gaming),
                             Scoring.weightedScore(of: budget, for: .gaming))
    }

    // MARK: - Satisfaction

    private func order(expecting score: Int, useCase: UseCase = .gaming) -> CustomerOrder {
        CustomerOrder(name: "Test", useCase: useCase, budget: 1000, expectedScore: score)
    }

    func testMeetingExpectationExactlyScoresEighty() {
        let build = PCBuild(cpu: part("cpu-i3-12100f"), gpu: part("gpu-rtx4070"))
        let score = Scoring.weightedScore(of: build, for: .gaming)
        XCTAssertEqual(Scoring.satisfaction(build: build, order: order(expecting: score)), 80)
    }

    func testFallingWellShortScoresLow() {
        let build = PCBuild(cpu: part("cpu-i3-12100f"), gpu: part("gpu-gtx1650"))
        let satisfaction = Scoring.satisfaction(build: build, order: order(expecting: 60))
        XCTAssertLessThan(satisfaction, 40)
    }

    /// Overbuilding is capped — this is what makes the economy a puzzle.
    func testOverbuildingIsCappedAtOneHundred() {
        let modest = PCBuild(cpu: part("cpu-i5-13400f"), gpu: part("gpu-rtx4060"))
        let extreme = PCBuild(cpu: part("cpu-i9-14900k"), gpu: part("gpu-rtx4080s"))
        let easyOrder = order(expecting: 20)

        XCTAssertEqual(Scoring.satisfaction(build: modest, order: easyOrder), 100)
        XCTAssertEqual(Scoring.satisfaction(build: extreme, order: easyOrder), 100,
                       "Spending far more buys no extra goodwill")
    }

    func testSatisfactionStaysInRange() {
        for expected in stride(from: 10, through: 120, by: 5) {
            for cpu in PartCatalog.cpus {
                let build = PCBuild(cpu: cpu, gpu: PartCatalog.gpus[0])
                let s = Scoring.satisfaction(build: build, order: order(expecting: expected))
                XCTAssertTrue((0...100).contains(s), "Satisfaction \(s) out of range")
            }
        }
    }

    // MARK: - Reputation

    func testReputationRewardsAndPunishes() {
        XCTAssertEqual(Scoring.reputationChange(satisfaction: 95), 3)
        XCTAssertEqual(Scoring.reputationChange(satisfaction: 80), 3)
        XCTAssertEqual(Scoring.reputationChange(satisfaction: 60), 0)
        XCTAssertEqual(Scoring.reputationChange(satisfaction: 10), -5)
    }

    // MARK: - Order expiry

    func testOrderExpiresAfterPatienceRunsOut() {
        var o = order(expecting: 50)
        XCTAssertFalse(o.isExpired)
        o.daysWaiting = CustomerOrder.patience
        XCTAssertTrue(o.isExpired)
    }

    // MARK: - Generator

    /// Every generated order must be solvable and must leave room for profit.
    func testGeneratedOrdersAreAlwaysSolvableAndProfitable() {
        var rng: RandomNumberGenerator = SeededGenerator(seed: 20260802)

        for reputation in [0, 25, 50, 75, 100] {
            for _ in 0..<200 {
                guard let order = OrderGenerator.makeOrder(reputation: reputation,
                                                           level: 5, using: &rng) else {
                    XCTFail("Generator returned nil at reputation \(reputation)")
                    continue
                }
                XCTAssertGreaterThan(order.budget, 0)
                XCTAssertGreaterThan(order.expectedScore, 0)
                XCTAssertFalse(order.name.isEmpty)
            }
        }
    }

    func testCustomerCountGrowsWithReputation() {
        var rng: RandomNumberGenerator = SeededGenerator(seed: 7)
        var lowTotal = 0
        var highTotal = 0
        for _ in 0..<300 {
            lowTotal += OrderGenerator.customerCount(reputation: 10, using: &rng)
            highTotal += OrderGenerator.customerCount(reputation: 95, using: &rng)
        }
        XCTAssertGreaterThan(highTotal, lowTotal,
                             "Good reputation should bring in more customers")
    }

    func testCheapestBuildIsValidAndCheap() {
        let build = OrderGenerator.cheapestBuild
        XCTAssertTrue(build.isComplete, "Fallback build must fill every slot")
        XCTAssertTrue(Compatibility.isValid(build), "Fallback build must be buildable")
        XCTAssertLessThan(build.partsCost, 600,
                          "If this jumps, the low-end catalog changed — recheck cost ceilings")
    }
}

// MARK: - Deterministic RNG for tests

/// Tests must not be flaky. This gives repeatable "random" values.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
