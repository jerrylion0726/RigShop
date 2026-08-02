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
//  Selection is budget-aware at every step: each slot only considers
//  parts we can still afford once the remaining slots are paid for.
//  Pure rejection sampling looked simpler but failed roughly 0.4% of
//  the time at tight budgets, because the affordable region is a
//  sliver of the search space.
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

    // MARK: - Tuning knobs

    /// Profit margin baked into the customer's budget, as a percentage
    /// above the reference build's parts cost.
    /// Tighter at low reputation, more generous at high reputation.
    private static func marginRange(reputation: Int) -> ClosedRange<Int> {
        switch reputation {
        case ..<30:   return 12...22
        case 30..<60: return 18...30
        case 60..<85: return 24...38
        default:      return 30...45
        }
    }

    /// Price ceiling for the reference build, so early-game customers
    /// don't all show up wanting a 4080.
    private static func costCeiling(reputation: Int, using rng: inout RandomNumberGenerator) -> Int {
        switch reputation {
        case ..<30:   return Int.random(in: 600...1000, using: &rng)
        case 30..<60: return Int.random(in: 800...1500, using: &rng)
        case 60..<85: return Int.random(in: 1100...2100, using: &rng)
        default:      return Int.random(in: 1500...2900, using: &rng)
        }
    }

    /// How many customers show up, given current reputation.
    static func customerCount(reputation: Int, using rng: inout RandomNumberGenerator) -> Int {
        switch reputation {
        case ..<30:   return Int.random(in: 1...2, using: &rng)
        case 30..<60: return Int.random(in: 2...3, using: &rng)
        case 60..<85: return Int.random(in: 3...4, using: &rng)
        default:      return Int.random(in: 3...5, using: &rng)
        }
    }

    // MARK: - Order

    /// Build a single order. Never returns nil for a non-empty catalog —
    /// the cheapest valid build is used as a last resort.
    static func makeOrder(reputation: Int,
                          using rng: inout RandomNumberGenerator) -> CustomerOrder? {
        guard let useCase = UseCase.allCases.randomElement(using: &rng) else { return nil }

        let ceiling = costCeiling(reputation: reputation, using: &rng)
        var reference: PCBuild?
        for _ in 0..<40 {
            if let build = attemptBuild(ceiling: ceiling, using: &rng) {
                reference = build
                break
            }
        }
        // Fallback: guaranteed to exist, guaranteed valid.
        let build = reference ?? cheapestBuild
        guard build.isComplete else { return nil }

        let cost = build.partsCost
        let margin = Int.random(in: marginRange(reputation: reputation), using: &rng)
        let budget = cost + (cost * margin / 100)

        // The customer expects roughly what the reference build delivers,
        // give or take a little, so hitting it exactly is not required.
        let referenceScore = Scoring.weightedScore(of: build, for: useCase)
        let wobble = Int.random(in: -4...3, using: &rng)
        let expected = max(10, referenceScore + wobble)

        let name = "\(firstNames.randomElement(using: &rng) ?? "Alex") "
                 + "\(lastInitials.randomElement(using: &rng) ?? "K.")"

        return CustomerOrder(name: name,
                             useCase: useCase,
                             budget: budget,
                             expectedScore: expected)
    }

    // MARK: - Budget-aware assembly

    /// One attempt at a valid build under `ceiling`.
    /// Each slot filters to what is still affordable, so most attempts succeed.
    private static func attemptBuild(ceiling: Int,
                                     using rng: inout RandomNumberGenerator) -> PCBuild? {
        var remaining = ceiling

        // CPU — must leave room for the cheapest possible rest-of-machine.
        let affordableCPUs = PartCatalog.cpus.filter {
            guard let socket = $0.socket else { return false }
            return $0.basePrice + minimumOverhead(for: socket) <= remaining
        }
        guard let cpu = affordableCPUs.randomElement(using: &rng),
              let socket = cpu.socket else { return nil }
        remaining -= cpu.basePrice

        // Motherboard — socket must match, and we still need memory + GPU + PSU.
        let boards = PartCatalog.motherboards.filter {
            $0.socket == socket
                && $0.basePrice + cheapestMemoryPrice + cheapestGPUPrice + cheapestPSUPrice <= remaining
        }
        guard let board = boards.randomElement(using: &rng) else { return nil }
        remaining -= board.basePrice

        // Memory — type must be on the board's list.
        let sticks = PartCatalog.memories.filter {
            guard let type = $0.memoryType else { return false }
            return board.supportedMemoryTypes.contains(type)
                && $0.basePrice + cheapestGPUPrice + cheapestPSUPrice <= remaining
        }
        guard let memory = sticks.randomElement(using: &rng) else { return nil }
        remaining -= memory.basePrice

        // GPU — leave enough for a PSU.
        let gpus = PartCatalog.gpus.filter {
            $0.basePrice + cheapestPSUPrice <= remaining
        }
        guard let gpu = gpus.randomElement(using: &rng) else { return nil }
        remaining -= gpu.basePrice

        // PSU — smallest one that actually covers the load and fits the money.
        let needed = cpu.powerDraw + gpu.powerDraw + Compatibility.powerHeadroom
        guard let psu = PartCatalog.psus
            .filter({ $0.watts >= needed && $0.basePrice <= remaining })
            .min(by: { $0.watts < $1.watts }) else { return nil }

        let build = PCBuild(cpu: cpu, motherboard: board, memory: memory, gpu: gpu, psu: psu)
        return Compatibility.isValid(build) ? build : nil
    }

    // MARK: - Catalog floors (computed once)

    private static let cheapestMemoryPrice: Int =
        PartCatalog.memories.map(\.basePrice).min() ?? 0
    private static let cheapestGPUPrice: Int =
        PartCatalog.gpus.map(\.basePrice).min() ?? 0
    private static let cheapestPSUPrice: Int =
        PartCatalog.psus.map(\.basePrice).min() ?? 0

    /// Cheapest board + compatible memory + GPU + PSU for a CPU of this socket.
    /// Used as a floor so we never pick a CPU we can't finish a machine around.
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

    /// The cheapest valid build the catalog allows. Exhaustive search,
    /// computed once. Guarantees `makeOrder` always has something to work with.
    static let cheapestBuild: PCBuild = {
        var best: PCBuild?
        var bestCost = Int.max

        for cpu in PartCatalog.cpus {
            for board in PartCatalog.motherboards where board.socket == cpu.socket {
                let sticks = PartCatalog.memories.filter {
                    guard let type = $0.memoryType else { return false }
                    return board.supportedMemoryTypes.contains(type)
                }
                for memory in sticks {
                    for gpu in PartCatalog.gpus {
                        let needed = cpu.powerDraw + gpu.powerDraw + Compatibility.powerHeadroom
                        guard let psu = PartCatalog.psus
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
