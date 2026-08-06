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
//  Theme.Shop extends the same palette forward for the storefront:
//  warmer, lighter, but never leaving the family. The shop floor is
//  the front of house; the supplier and build screens are the back.
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

    /// Storefront-only tones. Same family, one step warmer and lighter.
    enum Shop {
        static let wallTop    = Color(red: 0.153, green: 0.216, blue: 0.255)
        static let wallBottom = Color(red: 0.110, green: 0.165, blue: 0.200)
        static let floor      = Color(red: 0.078, green: 0.118, blue: 0.145)
        static let shelf      = Color(red: 0.420, green: 0.337, blue: 0.263)
        static let shelfLip   = Color(red: 0.541, green: 0.435, blue: 0.337)
        static let counter    = Color(red: 0.278, green: 0.235, blue: 0.192)
        static let counterLip = Color(red: 0.380, green: 0.318, blue: 0.255)

        /// Merchandise accents — desaturated cousins of the category tints,
        /// so the shelves read as colourful stock without shouting.
        static let merch: [Color] = [
            Color(red: 0.376, green: 0.706, blue: 0.769),
            Color(red: 0.588, green: 0.510, blue: 0.812),
            Color(red: 0.851, green: 0.643, blue: 0.255),
            Color(red: 0.310, green: 0.643, blue: 0.420),
            Color(red: 0.839, green: 0.478, blue: 0.376),
            Color(red: 0.639, green: 0.694, blue: 0.729),
        ]

        /// Shirt colours for customer figures.
        static let shirts: [Color] = [
            Color(red: 0.831, green: 0.451, blue: 0.376),
            Color(red: 0.376, green: 0.635, blue: 0.729),
            Color(red: 0.549, green: 0.694, blue: 0.443),
            Color(red: 0.780, green: 0.616, blue: 0.322),
            Color(red: 0.635, green: 0.541, blue: 0.780),
            Color(red: 0.443, green: 0.702, blue: 0.667),
        ]

        static let skin = Color(red: 0.902, green: 0.784, blue: 0.663)
    }
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

extension UseCase {
    var symbol: String {
        switch self {
        case .gaming:  return "gamecontroller.fill"
        case .editing: return "film.fill"
        case .office:  return "doc.text.fill"
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
