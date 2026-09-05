//
//  Customer.swift
//  RigShop
//
//  Customers, what they want, and how happy they end up.
//
//  Two kinds of job walk through the door. A new build is five empty
//  slots. A repair is a machine that already exists with one or two dead
//  parts in it — the same compatibility rules, read backwards: instead of
//  choosing five parts that agree with each other, you're finding the one
//  part that agrees with four you didn't pick.
//
//  Do NOT import SwiftUI in this file.
//

import Foundation

// MARK: - Use case

enum UseCase: String, Codable, CaseIterable, Identifiable {
    case gaming
    case editing
    case office

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gaming:  return "Gaming"
        case .editing: return "Video Editing"
        case .office:  return "Office Work"
        }
    }

    /// What the customer actually cares about.
    var cpuWeight: Double {
        switch self {
        case .gaming:  return 0.3
        case .editing: return 0.6
        case .office:  return 0.8
        }
    }

    var gpuWeight: Double { 1.0 - cpuWeight }

    /// Flavour text shown on a new-build order card.
    var request: String {
        switch self {
        case .gaming:  return "Something that runs new titles smoothly."
        case .editing: return "I render video, so it needs to chew through timelines."
        case .office:  return "Spreadsheets and browser tabs. Nothing fancy."
        }
    }
}

// MARK: - Repair

/// A machine brought in for repair, with the parts that have failed.
struct RepairJob: Codable, Equatable, Hashable {
    /// The machine as it stands, dead parts still fitted.
    let machine: PCBuild
    /// Which slots have failed. Usually one.
    let faults: [PartCategory]

    /// The machine with the dead parts pulled out — what the player
    /// actually has to work with.
    var openMachine: PCBuild { machine.removing(faults) }

    /// What the customer says is wrong, in their own words. Real symptoms,
    /// because learning to map "no display" to "graphics card" is the
    /// point of the mechanic.
    var symptom: String {
        guard let first = faults.first else { return "It just stopped working." }
        if faults.count > 1 {
            return "It died completely — no lights, no display, nothing. "
                 + "I think more than one thing went."
        }
        switch first {
        case .psu:
            return "Nothing at all. I hit the power button and not one light comes on."
        case .gpu:
            return "It powers up and the fans spin, but the monitor never wakes."
        case .memory:
            return "It crashes at random. Sometimes after minutes, sometimes hours."
        case .cpu:
            return "It boots to the desktop, then locks up hard the moment I do anything."
        case .motherboard:
            return "Half the USB ports quit on me, and now it won't post at all."
        }
    }

    /// One-line diagnosis for the card, so the player isn't guessing.
    var diagnosis: String {
        let names = faults.map(\.displayName).joined(separator: " and ")
        return faults.count > 1 ? "\(names) have failed." : "\(names) has failed."
    }

    /// Scrap credit for the dead parts, once they're out of the case.
    var scrapValue: Int {
        faults.compactMap { machine[$0] }.reduce(0) { $0 + $1.basePrice * 10 / 100 }
    }
}

// MARK: - Order

struct CustomerOrder: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let useCase: UseCase
    /// What the customer pays if the job satisfies them. Fixed price.
    let budget: Int
    /// The weighted score the finished machine needs to hit. For a repair
    /// this is what their machine scored before it broke — they expect it
    /// back the way it was, not worse.
    let expectedScore: Int
    /// Days this order has been sitting unfilled.
    var daysWaiting: Int
    /// Non-nil when the customer carried a machine in instead of ordering one.
    let repair: RepairJob?

    init(id: UUID = UUID(),
         name: String,
         useCase: UseCase,
         budget: Int,
         expectedScore: Int,
         daysWaiting: Int = 0,
         repair: RepairJob? = nil) {
        self.id = id
        self.name = name
        self.useCase = useCase
        self.budget = budget
        self.expectedScore = expectedScore
        self.daysWaiting = daysWaiting
        self.repair = repair
    }

    var isRepair: Bool { repair != nil }

    /// Slots the player has to fill: all five for a build, only the dead
    /// ones for a repair.
    var slotsToFill: [PartCategory] {
        repair?.faults ?? PartCategory.buildOrder
    }

    /// What the player starts from.
    var startingMachine: PCBuild {
        repair?.openMachine ?? PCBuild()
    }

    /// Customers give up after this many days.
    static let patience = 3

    var isExpired: Bool { daysWaiting >= CustomerOrder.patience }
}

// MARK: - Scoring

enum Scoring {

    /// Weighted performance of a build, for this customer's use case.
    static func weightedScore(of build: PCBuild, for useCase: UseCase) -> Int {
        let cpu = Double(build.cpu?.score ?? 0)
        let gpu = Double(build.gpu?.score ?? 0)
        let raw = cpu * useCase.cpuWeight + gpu * useCase.gpuWeight
        return Int(raw.rounded())
    }

    /// 0–100. Above expectation earns nothing extra — overbuilding
    /// costs the shop money and buys no goodwill.
    static func satisfaction(build: PCBuild, order: CustomerOrder) -> Int {
        guard order.expectedScore > 0 else { return 100 }
        let actual = weightedScore(of: build, for: order.useCase)
        let ratio = Double(actual) / Double(order.expectedScore)

        switch ratio {
        case ..<0.8:
            return max(0, Int((ratio / 0.8 * 39).rounded()))
        case ..<1.0:
            return 40 + Int(((ratio - 0.8) / 0.2 * 39).rounded())
        case ..<1.2:
            return 80 + Int(((ratio - 1.0) / 0.2 * 20).rounded())
        default:
            return 100
        }
    }

    /// Reputation delta from one completed order.
    static func reputationChange(satisfaction: Int) -> Int {
        switch satisfaction {
        case 80...:   return 3
        case 40..<80: return 0
        default:      return -5
        }
    }

    /// Reputation penalty when a customer gives up waiting.
    static let expiredOrderPenalty = -3
}
