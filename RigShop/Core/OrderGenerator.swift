//
//  OrderGenerator.swift
//  RigShop
//
//  Generates customer orders that are guaranteed solvable.
//
//  The naive approach — roll a random budget and a random expected
//  score — produces impossible orders: $600 for a score of 85 can
//  never be built, and the player just feels cheated.
//
//  So we work backwards. Pick a real, valid, affordable build first,
//  measure it, then derive the customer's budget and expectations
//  from that build. Every order therefore has at least one solution.
//
//  Repairs use the same trick from the other end: build a real machine,
//  break part of it, then price the job off a reference fix that is
//  known to work.
//
//  Do NOT import SwiftUI in this file.
//

import Foundation

enum OrderGenerator {

    private static let firstNames = [
        "Marcus", "Priya", "Dante", "Elena", "Tobias", "Nia",
        "Hector", "Yuki", "Amara", "Felix", "Rosa", "Kwame",
        "Lena", "Omar", "Sofia", "Jonah", "Mei", "Rafael"
    ]

    private static let lastInitials = ["B.", "C.", "D.", "K.", "M.", "N.", "R.", "S.", "T.", "V."]

    /// Share of walk-ins that are repairs rather than new builds.
    /// Repairs tie up less cash, so they're the lifeline when the till
    /// is empty — but they pay less per job.
    private static let repairShare = 35

    // MARK: - Tuning knobs

    private static func marginRange(reputation: Int) -> ClosedRange<Int> {
        switch reputation {
        case ..<30:   return 12...22
        case 30..<60: return 18...30
        case 60..<85: return 24...38
        default:      return 30...45
        }
    }

    /// Flat call-out fee on a repair, on top of parts and margin.
    /// Without it a $45 power supply swap earns single-digit profit and
    /// nobody would ever take the job.
    private static func labourFee(level: Int, using rng: inout RandomNumberGenerator) -> Int {
        let base = Int.random(in: 45...90, using: &rng)
        return base + base * 10 * max(0, level - 1) / 100
    }

    /// A hard ceiling on how big a job the shop attracts, by level.
    ///
    /// Reputation says how well regarded you are; level says how
    /// established. A shop that opened yesterday does not get a $1,500
    /// commission walking through the door however polite it was to its
    /// first three customers — and with a lean starting till, one of
    /// those would soft-lock the game on day one.
    private static func levelCeiling(_ level: Int) -> Int {
        switch level {
        case 1:  return 520
        case 2:  return 720
        case 3:  return 950
        case 4:  return 1_300
        case 5:  return 1_800
        default: return Int.max
        }
    }

    private static func costCeiling(reputation: Int,
                                    level: Int,
                                    using rng: inout RandomNumberGenerator) -> Int {
        let base: ClosedRange<Int>
        switch reputation {
        case ..<30:   base = 600...1000
        case 30..<60: base = 800...1500
        case 60..<85: base = 1100...2100
        default:      base = 1500...2900
        }
        let roll = Int.random(in: base, using: &rng)
        let withLevelBonus = roll + roll * 12 * max(0, level - 1) / 100
        return min(withLevelBonus, levelCeiling(level))
    }

    static func customerCount(reputation: Int, using rng: inout RandomNumberGenerator) -> Int {
        switch reputation {
        case ..<30:   return Int.random(in: 1...2, using: &rng)
        case 30..<60: return Int.random(in: 2...3, using: &rng)
        case 60..<85: return Int.random(in: 3...4, using: &rng)
        default:      return Int.random(in: 3...5, using: &rng)
        }
    }

    // MARK: - Entry point

    /// One walk-in: either a new build or a repair.
    static func makeOrder(reputation: Int,
                          level: Int,
                          using rng: inout RandomNumberGenerator) -> CustomerOrder? {
        if Int.random(in: 1...100, using: &rng) <= repairShare,
           let repair = makeRepair(reputation: reputation, level: level, using: &rng) {
            return repair
        }
        return makeNewBuild(reputation: reputation, level: level, using: &rng)
    }

    // MARK: - New build

    static func makeNewBuild(reputation: Int,
                             level: Int,
                             using rng: inout RandomNumberGenerator) -> CustomerOrder? {
        guard let useCase = UseCase.allCases.randomElement(using: &rng) else { return nil }

        let ceiling = costCeiling(reputation: reputation, level: level, using: &rng)
        let build = randomMachine(ceiling: ceiling, level: level, using: &rng) ?? cheapestBuild
        guard build.isComplete else { return nil }

        let cost = build.partsCost
        let margin = Int.random(in: marginRange(reputation: reputation), using: &rng)
        let budget = cost + (cost * margin / 100)

        let referenceScore = Scoring.weightedScore(of: build, for: useCase)
        let wobble = Int.random(in: -4...3, using: &rng)
        let expected = max(10, referenceScore + wobble)

        return CustomerOrder(name: randomName(using: &rng),
                             useCase: useCase,
                             budget: budget,
                             expectedScore: expected)
    }

    // MARK: - Repair

    static func makeRepair(reputation: Int,
                           level: Int,
                           using rng: inout RandomNumberGenerator) -> CustomerOrder? {
        guard let useCase = UseCase.allCases.randomElement(using: &rng) else { return nil }
        let ceiling = costCeiling(reputation: reputation, level: level, using: &rng)

        // Not every machine can be broken in a way the catalogue can fix —
        // a dead part with no affordable equal-or-better replacement is a
        // dead end. Roll until one lands.
        for _ in 0..<25 {
            guard let machine = randomMachine(ceiling: ceiling, level: level, using: &rng),
                  machine.isComplete else { continue }

            var faults: [PartCategory] = []
            guard let first = PartCategory.buildOrder.randomElement(using: &rng) else { continue }
            faults.append(first)
            if level >= 4, Int.random(in: 1...100, using: &rng) <= 20 {
                let others = PartCategory.buildOrder.filter { $0 != first }
                if let second = others.randomElement(using: &rng) { faults.append(second) }
            }

            let job = RepairJob(machine: machine, faults: faults)
            guard let plan = repairPlan(for: job, level: level) else { continue }

            let fairPartsCost = plan.values.reduce(0) { $0 + $1.basePrice }
            let margin = Int.random(in: marginRange(reputation: reputation), using: &rng)
            let fee = fairPartsCost + (fairPartsCost * margin / 100)
                    + labourFee(level: level, using: &rng)

            // They want the machine back the way it was, not worse.
            let expected = max(10, Scoring.weightedScore(of: machine, for: useCase))

            return CustomerOrder(name: randomName(using: &rng),
                                 useCase: useCase,
                                 budget: fee,
                                 expectedScore: expected,
                                 repair: job)
        }
        return nil
    }

    /// A reference fix for every dead slot, or nil if the catalogue can't
    /// produce one.
    ///
    /// Slots are filled in build order and each choice is made against the
    /// machine *as it stands*, not against the machine with every fault
    /// still open. That matters: choosing a graphics card while the power
    /// supply slot is empty skips the wattage rule entirely, so picking
    /// both independently can hand back a 575W card and a 550W supply.
    /// Power comes last, by which point the card is already fitted.
    static func repairPlan(for job: RepairJob, level: Int) -> [PartCategory: Part]? {
        var machine = job.openMachine
        var plan: [PartCategory: Part] = [:]

        for fault in PartCategory.buildOrder where job.faults.contains(fault) {
            guard let dead = job.machine[fault],
                  let replacement = cheapestAcceptableReplacement(for: fault,
                                                                  matching: dead,
                                                                  in: machine,
                                                                  level: level)
            else { return nil }
            machine[fault] = replacement
            plan[fault] = replacement
        }

        return Compatibility.isValid(machine) ? plan : nil
    }

    /// The cheapest unlocked part that fits this machine and is no worse
    /// than what died. This is the yardstick the fee is set against, so
    /// beating it is where a repair shop makes its money.
    static func cheapestAcceptableReplacement(for category: PartCategory,
                                              matching dead: Part,
                                              in machine: PCBuild,
                                              level: Int) -> Part? {
        PartCatalog.parts(in: category, unlockedAt: level)
            .filter { candidate in
                guard candidate.score >= dead.score else { return false }
                var trial = machine
                trial[category] = candidate
                // Slots still waiting on another fault don't count as problems.
                return Compatibility.check(trial).allSatisfy {
                    if case .missingPart = $0 { return true }
                    return false
                }
            }
            .min { $0.basePrice < $1.basePrice }
    }

    // MARK: - Budget-aware assembly

    private static func randomMachine(ceiling: Int,
                                      level: Int,
                                      using rng: inout RandomNumberGenerator) -> PCBuild? {
        for _ in 0..<40 {
            if let build = attemptBuild(ceiling: ceiling, level: level, using: &rng) {
                return build
            }
        }
        return nil
    }

    private static func attemptBuild(ceiling: Int,
                                     level: Int,
                                     using rng: inout RandomNumberGenerator) -> PCBuild? {
        var remaining = ceiling

        let affordableCPUs = PartCatalog.cpus.filter {
            guard $0.unlockLevel <= level, let socket = $0.socket else { return false }
            return $0.basePrice + minimumOverhead(for: socket) <= remaining
        }
        guard let cpu = affordableCPUs.randomElement(using: &rng),
              let socket = cpu.socket else { return nil }
        remaining -= cpu.basePrice

        let boards = PartCatalog.motherboards.filter {
            $0.unlockLevel <= level
                && $0.socket == socket
                && $0.basePrice + cheapestMemoryPrice + cheapestGPUPrice + cheapestPSUPrice <= remaining
        }
        guard let board = boards.randomElement(using: &rng) else { return nil }
        remaining -= board.basePrice

        let sticks = PartCatalog.memories.filter {
            guard $0.unlockLevel <= level, let type = $0.memoryType else { return false }
            return board.supportedMemoryTypes.contains(type)
                && $0.basePrice + cheapestGPUPrice + cheapestPSUPrice <= remaining
        }
        guard let memory = sticks.randomElement(using: &rng) else { return nil }
        remaining -= memory.basePrice

        let gpus = PartCatalog.gpus.filter {
            $0.unlockLevel <= level && $0.basePrice + cheapestPSUPrice <= remaining
        }
        guard let gpu = gpus.randomElement(using: &rng) else { return nil }
        remaining -= gpu.basePrice

        let needed = cpu.powerDraw + gpu.powerDraw + Compatibility.powerHeadroom
        guard let psu = PartCatalog.psus
            .filter({ $0.unlockLevel <= level && $0.watts >= needed && $0.basePrice <= remaining })
            .min(by: { $0.watts < $1.watts }) else { return nil }

        let build = PCBuild(cpu: cpu, motherboard: board, memory: memory, gpu: gpu, psu: psu)
        return Compatibility.isValid(build) ? build : nil
    }

    // MARK: - Helpers

    private static func randomName(using rng: inout RandomNumberGenerator) -> String {
        "\(firstNames.randomElement(using: &rng) ?? "Alex") "
        + "\(lastInitials.randomElement(using: &rng) ?? "K.")"
    }

    private static let cheapestMemoryPrice: Int =
        PartCatalog.memories.map(\.basePrice).min() ?? 0
    private static let cheapestGPUPrice: Int =
        PartCatalog.gpus.map(\.basePrice).min() ?? 0
    private static let cheapestPSUPrice: Int =
        PartCatalog.psus.map(\.basePrice).min() ?? 0

    private static func minimumOverhead(for socket: Socket) -> Int {
        overheadBySocket[socket] ?? Int.max
    }

    private static let overheadBySocket: [Socket: Int] = {
        var result: [Socket: Int] = [:]
        for socket in Socket.allCases {
            let boards = PartCatalog.motherboards.filter { $0.socket == socket }
            var best = Int.max
            for board in boards {
                let sticks = PartCatalog.memories.filter {
                    guard let type = $0.memoryType else { return false }
                    return board.supportedMemoryTypes.contains(type)
                }
                guard let stick = sticks.map(\.basePrice).min() else { continue }
                best = min(best, board.basePrice + stick)
            }
            if best != Int.max {
                result[socket] = best + cheapestGPUPrice + cheapestPSUPrice
            }
        }
        return result
    }()

    /// The cheapest valid build in the catalogue, searched over level-1
    /// parts only — they're unlocked at every level and are the cheapest
    /// in the catalogue, so this build is a legal fallback for any shop.
    static let cheapestBuild: PCBuild = {
        let cpus = PartCatalog.cpus.filter { $0.unlockLevel == 1 }
        let boards = PartCatalog.motherboards.filter { $0.unlockLevel == 1 }
        let sticks = PartCatalog.memories.filter { $0.unlockLevel == 1 }
        let gpus = PartCatalog.gpus.filter { $0.unlockLevel == 1 }
        let psus = PartCatalog.psus.filter { $0.unlockLevel == 1 }

        var best: PCBuild?
        var bestCost = Int.max

        for cpu in cpus {
            for board in boards where board.socket == cpu.socket {
                let fitting = sticks.filter {
                    guard let type = $0.memoryType else { return false }
                    return board.supportedMemoryTypes.contains(type)
                }
                for memory in fitting {
                    for gpu in gpus {
                        let needed = cpu.powerDraw + gpu.powerDraw + Compatibility.powerHeadroom
                        guard let psu = psus
                            .filter({ $0.watts >= needed })
                            .min(by: { $0.basePrice < $1.basePrice }) else { continue }

                        let build = PCBuild(cpu: cpu, motherboard: board,
                                            memory: memory, gpu: gpu, psu: psu)
                        let cost = build.partsCost
                        if cost < bestCost && Compatibility.isValid(build) {
                            bestCost = cost
                            best = build
                        }
                    }
                }
            }
        }
        return best ?? PCBuild()
    }()
}
