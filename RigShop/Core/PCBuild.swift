//
//  PCBuild.swift
//  RigShop
//
//  A machine under assembly. Slots may be empty while the player works.
//
//  Do NOT import SwiftUI in this file.
//

import Foundation

struct PCBuild: Equatable {
    var cpu: Part?
    var motherboard: Part?
    var memory: Part?
    var gpu: Part?
    var psu: Part?

    init(cpu: Part? = nil,
         motherboard: Part? = nil,
         memory: Part? = nil,
         gpu: Part? = nil,
         psu: Part? = nil) {
        self.cpu = cpu
        self.motherboard = motherboard
        self.memory = memory
        self.gpu = gpu
        self.psu = psu
    }
}

extension PCBuild {

    /// Every part currently slotted, empty slots skipped.
    var parts: [Part] {
        [cpu, motherboard, memory, gpu, psu].compactMap { $0 }
    }

    /// Slots that are still empty.
    var missingCategories: [PartCategory] {
        PartCategory.buildOrder.filter { self[$0] == nil }
    }

    var isComplete: Bool { missingCategories.isEmpty }

    /// What this build cost the shop, at the prices actually paid.
    /// Uses base price here; the real cost basis is tracked in Step 7.
    var partsCost: Int {
        parts.reduce(0) { $0 + $1.basePrice }
    }

    /// Combined peak draw of CPU and GPU.
    var totalPowerDraw: Int {
        parts.reduce(0) { $0 + $1.powerDraw }
    }

    /// Subscript access by slot, so UI code can loop over categories.
    subscript(category: PartCategory) -> Part? {
        get {
            switch category {
            case .cpu:         return cpu
            case .motherboard: return motherboard
            case .memory:      return memory
            case .gpu:         return gpu
            case .psu:         return psu
            }
        }
        set {
            switch category {
            case .cpu:         cpu = newValue
            case .motherboard: motherboard = newValue
            case .memory:      memory = newValue
            case .gpu:         gpu = newValue
            case .psu:         psu = newValue
            }
        }
    }
}
