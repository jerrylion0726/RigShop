//
//  Customer.swift
//  RigShop
//
//  Customers, what they want, and how happy they end up.
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

    /// Flavour text shown on the order card.
    var request: String {
        switch self {
        case .gaming:  return "Something that runs new titles smoothly."
        case .editing: return "I render video, so it needs to chew through timelines."
        case .office:  return "Spreadsheets and browser tabs. Nothing fancy."
        }
    }
}

// MARK: - Order

struct CustomerOrder: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let useCase: UseCase
    /// What the customer pays if the build satisfies them. Fixed price.
    let budget: Int
    /// The weighted score the build needs to hit.
    let expectedScore: Int
    /// Days this order has been sitting unfilled.
    var daysWaiting: Int

    init(id: UUID = UUID(),
         name: String,
         useCase: UseCase,
         budget: Int,
         expectedScore: Int,
         daysWaiting: Int = 0) {
        self.id = id
        self.name = name
        self.useCase = useCase
        self.budget = budget
        self.expectedScore = expectedScore
        self.daysWaiting = daysWaiting
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
            // 0 up to 39, scaling with how close they got.
            return max(0, Int((ratio / 0.8 * 39).rounded()))
        case ..<1.0:
            // 40 to 79 across the 0.8–1.0 band.
            return 40 + Int(((ratio - 0.8) / 0.2 * 39).rounded())
        case ..<1.2:
            // 80 to 100 across the 1.0–1.2 band.
            return 80 + Int(((ratio - 1.0) / 0.2 * 20).rounded())
        default:
            return 100
        }
    }

    /// Reputation delta from one completed order.
    static func reputationChange(satisfaction: Int) -> Int {
        switch satisfaction {
        case 80...:  return 3
        case 40..<80: return 0
        default:      return -5
        }
    }

    /// Reputation penalty when a customer gives up waiting.
    static let expiredOrderPenalty = -3
}
