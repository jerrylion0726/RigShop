//
//  Theme.swift
//  RigShop
//
//  Design tokens. Everything visual is derived from here, so the whole
//  app can be re-skinned by editing one file.
//
//  Direction: an anti-static workbench mat. Deep blue-slate ground,
//  PCB solder green for "go", contact gold for money, high-voltage
//  warning red for trouble. Numbers are always monospaced — this is
//  a game about reading spec sheets and price tags.
//

import SwiftUI

enum Theme {
    static let ink     = Color(red: 0.086, green: 0.137, blue: 0.165)
    static let surface = Color(red: 0.122, green: 0.184, blue: 0.220)
    static let raised  = Color(red: 0.157, green: 0.231, blue: 0.275)
    static let line    = Color(red: 0.200, green: 0.271, blue: 0.310)

    static let text    = Color(red: 0.910, green: 0.933, blue: 0.941)
    static let muted   = Color(red: 0.541, green: 0.631, blue: 0.678)

    static let solder  = Color(red: 0.310, green: 0.643, blue: 0.420)
    static let gold    = Color(red: 0.851, green: 0.643, blue: 0.255)
    static let fault   = Color(red: 0.839, green: 0.376, blue: 0.290)
}

extension Font {
    /// Anything that belongs in a column: prices, watts, scores, days.
    static func spec(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// Presentation-only knowledge about categories. Deliberately kept out of
// Core/ — the rules engine has no business knowing what colour a GPU is.
extension PartCategory {

    var tint: Color {
        switch self {
        case .cpu:         return Theme.gold
        case .motherboard: return Theme.solder
        case .memory:      return Color(red: 0.376, green: 0.706, blue: 0.769)
        case .gpu:         return Color(red: 0.588, green: 0.510, blue: 0.812)
        case .psu:         return Color(red: 0.882, green: 0.749, blue: 0.298)
        }
    }

    var symbol: String {
        switch self {
        case .cpu:         return "cpu"
        case .motherboard: return "square.grid.3x3"
        case .memory:      return "memorychip"
        case .gpu:         return "rectangle.3.group"
        case .psu:         return "bolt.fill"
        }
    }
}

// MARK: - Money

extension Int {
    /// Whole dollars, grouped. No cents anywhere in this game.
    var money: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return "$" + (formatter.string(from: NSNumber(value: self)) ?? "\(self)")
    }
}
