//
//  Part.swift
//  RigShop
//
//  Pure model layer. Do NOT import SwiftUI in this file.
//

import Foundation

// MARK: - Category

enum PartCategory: String, Codable, CaseIterable, Identifiable {
    case cpu
    case motherboard
    case memory
    case gpu
    case psu

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cpu:         return "CPU"
        case .motherboard: return "Motherboard"
        case .memory:      return "Memory"
        case .gpu:         return "Graphics Card"
        case .psu:         return "Power Supply"
        }
    }

    /// The order slots appear in the build screen.
    static let buildOrder: [PartCategory] = [.cpu, .motherboard, .memory, .gpu, .psu]
}

// MARK: - Hardware enums

enum Socket: String, Codable, Hashable, CaseIterable {
    case lga1700 = "LGA1700"
    case lga1851 = "LGA1851"
    case am4     = "AM4"
    case am5     = "AM5"
}

enum MemoryType: String, Codable, Hashable, CaseIterable {
    case ddr4 = "DDR4"
    case ddr5 = "DDR5"
}

// MARK: - Spec

/// Category-specific attributes.
///
/// Using an enum with associated values means a power supply
/// *cannot* have a CPU socket — the compiler rejects it.
enum Spec: Codable, Hashable {
    case cpu(socket: Socket, powerDraw: Int)
    case motherboard(socket: Socket, memoryTypes: [MemoryType])
    case memory(type: MemoryType, capacityGB: Int)
    case gpu(powerDraw: Int)
    case psu(watts: Int)
}

// MARK: - Part

struct Part: Identifiable, Codable, Hashable {
    /// Stable slug, e.g. "cpu-i5-13400f". Used as the save-file key.
    let id: String
    /// Display name, e.g. "Intel Core i5-13400F".
    let name: String
    /// Wholesale reference price in whole dollars. Daily price floats around this.
    let basePrice: Int
    /// Shop level required before the supplier will carry this part.
    /// 1 means available from day one; 10 is the top of the ladder.
    let unlockLevel: Int
    /// How much this part contributes to a machine's performance.
    ///
    /// Every part scores, not just the processor and graphics card. A
    /// fast card paired with 8GB of memory still stutters, and a machine
    /// is only as good as the part holding it back — so memory capacity,
    /// board tier and power quality all carry weight. Entry level sits
    /// near 12; the halo parts run past 100. Satisfaction compares
    /// ratios, not absolutes, so the scale has no ceiling it must respect.
    let score: Int
    let spec: Spec

    init(id: String,
         name: String,
         basePrice: Int,
         unlockLevel: Int = 1,
         score: Int,
         spec: Spec) {
        self.id = id
        self.name = name
        self.basePrice = basePrice
        self.unlockLevel = unlockLevel
        self.score = score
        self.spec = spec
    }
}

// MARK: - Convenience accessors
//
// These wrap the `switch spec` boilerplate so the rest of the
// codebase can read `part.powerDraw` instead of pattern matching.

extension Part {

    var category: PartCategory {
        switch spec {
        case .cpu:         return .cpu
        case .motherboard: return .motherboard
        case .memory:      return .memory
        case .gpu:         return .gpu
        case .psu:         return .psu
        }
    }

    /// CPUs and motherboards only. `nil` for everything else.
    var socket: Socket? {
        switch spec {
        case .cpu(let socket, _):         return socket
        case .motherboard(let socket, _): return socket
        default:                          return nil
        }
    }

    /// Peak wattage drawn under load. Only CPUs and GPUs draw meaningful power.
    var powerDraw: Int {
        switch spec {
        case .cpu(_, let watts): return watts
        case .gpu(let watts):    return watts
        default:                 return 0
        }
    }

    /// Power supplies only. 0 for everything else.
    var watts: Int {
        if case .psu(let watts) = spec { return watts }
        return 0
    }

    /// Motherboards only. Empty for everything else.
    var supportedMemoryTypes: [MemoryType] {
        if case .motherboard(_, let types) = spec { return types }
        return []
    }

    /// Memory modules only. `nil` for everything else.
    var memoryType: MemoryType? {
        if case .memory(let type, _) = spec { return type }
        return nil
    }

    /// Memory modules only. 0 for everything else.
    var capacityGB: Int {
        if case .memory(_, let gb) = spec { return gb }
        return 0
    }

    /// What the supplier pays to take unsold stock back: 60% of base price.
    /// Integer division on purpose — never use Double for money.
    var salvageValue: Int { basePrice * 60 / 100 }

    /// One-line spec summary for list rows.
    var specSummary: String {
        switch spec {
        case .cpu(let socket, let power):
            return "\(socket.rawValue) · \(power)W"
        case .motherboard(let socket, let types):
            return "\(socket.rawValue) · \(types.map(\.rawValue).joined(separator: "/"))"
        case .memory(let type, let gb):
            return "\(gb)GB \(type.rawValue)"
        case .gpu(let power):
            return "\(power)W"
        case .psu(let watts):
            return "\(watts)W"
        }
    }
}
