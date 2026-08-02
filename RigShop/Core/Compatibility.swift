//
//  Compatibility.swift
//  RigShop
//
//  The three rules that decide whether a build actually works.
//
//  This returns a *list of specific problems*, not a Bool. The UI needs
//  to tell the player WHY a build fails, otherwise the puzzle is unfair.
//
//  Do NOT import SwiftUI in this file.
//

import Foundation

// MARK: - Issue

enum CompatibilityIssue: Equatable, Hashable {
    /// A slot is still empty.
    case missingPart(PartCategory)
    /// CPU socket does not match the motherboard socket.
    case socketMismatch(cpu: Socket, board: Socket)
    /// The memory module's type is not on the motherboard's supported list.
    case memoryUnsupported(has: MemoryType, boardSupports: [MemoryType])
    /// Power supply cannot cover peak draw plus headroom.
    case insufficientPower(needs: Int, has: Int)

    /// Player-facing explanation.
    var message: String {
        switch self {
        case .missingPart(let category):
            return "No \(category.displayName) selected."
        case .socketMismatch(let cpu, let board):
            return "CPU is \(cpu.rawValue) but the motherboard is \(board.rawValue)."
        case .memoryUnsupported(let has, let supports):
            let list = supports.map(\.rawValue).joined(separator: " or ")
            return "Motherboard takes \(list) — this module is \(has.rawValue)."
        case .insufficientPower(let needs, let has):
            return "Needs \(needs)W including headroom, but the PSU is only \(has)W."
        }
    }
}

// MARK: - Checker

enum Compatibility {

    /// Safety margin on top of CPU + GPU peak draw, in watts.
    /// Covers the motherboard, drives, and fans, which we don't model as parts.
    static let powerHeadroom = 100

    /// Every problem with this build. Empty array means it works.
    static func check(_ build: PCBuild) -> [CompatibilityIssue] {
        var issues: [CompatibilityIssue] = []

        // Rule 0: every slot filled.
        for category in build.missingCategories {
            issues.append(.missingPart(category))
        }

        // Rule 1: CPU socket must match motherboard socket.
        if let cpuSocket = build.cpu?.socket,
           let boardSocket = build.motherboard?.socket,
           cpuSocket != boardSocket {
            issues.append(.socketMismatch(cpu: cpuSocket, board: boardSocket))
        }

        // Rule 2: memory type must be on the motherboard's supported list.
        if let memoryType = build.memory?.memoryType,
           let board = build.motherboard,
           !board.supportedMemoryTypes.contains(memoryType) {
            issues.append(.memoryUnsupported(has: memoryType,
                                             boardSupports: board.supportedMemoryTypes))
        }

        // Rule 3: PSU must cover peak draw plus headroom.
        if let psu = build.psu {
            let needs = build.totalPowerDraw + powerHeadroom
            if psu.watts < needs {
                issues.append(.insufficientPower(needs: needs, has: psu.watts))
            }
        }

        return issues
    }

    static func isValid(_ build: PCBuild) -> Bool {
        check(build).isEmpty
    }

    /// Whether a single part can still be slotted without creating a new conflict.
    /// Used to grey out impossible options in the build screen.
    static func canAdd(_ part: Part, to build: PCBuild) -> Bool {
        var candidate = build
        candidate[part.category] = part
        let newIssues = check(candidate).filter {
            if case .missingPart = $0 { return false }
            return true
        }
        return newIssues.isEmpty
    }
}
