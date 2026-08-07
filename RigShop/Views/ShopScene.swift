//
//  ShopScene.swift
//  RigShop
//
//  The storefront, drawn entirely with SwiftUI shapes. No image assets,
//  so it costs nothing, has no licensing questions, and stays sharp at
//  any size.
//
//  The top two shelves are live: they hold whatever you actually bought,
//  tinted by category. A wall of purple means you're sitting on graphics
//  cards. The bottom shelf is permanent set dressing — peripherals aren't
//  sellable yet, and without it an empty shop looks broken rather than
//  poor. Tapping the unit opens the stockroom.
//

import SwiftUI

// MARK: - Merchandise

enum Merch: CaseIterable {
    case gpu, ram, motherboard, cpu, psu, fan
    case monitor, keyboard, mouse, headset, box
}

extension PartCategory {
    /// How a part of this category is drawn on the shelf.
    var merch: Merch {
        switch self {
        case .cpu:         return .cpu
        case .motherboard: return .motherboard
        case .memory:      return .ram
        case .gpu:         return .gpu
        case .psu:         return .psu
        }
    }
}

struct MerchItem: View {
    let kind: Merch
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Group {
                switch kind {
                case .gpu:         graphicsCard(w, h)
                case .ram:         memoryStick(w, h)
                case .motherboard: board(w, h)
                case .cpu:         processor(w, h)
                case .psu:         powerSupply(w, h)
                case .fan:         caseFan(w, h)
                case .monitor:     monitor(w, h)
                case .keyboard:    keyboard(w, h)
                case .mouse:       mouse(w, h)
                case .headset:     headset(w, h)
                case .box:         boxedProduct(w, h)
                }
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }

    // MARK: Components

    /// Shroud, twin fans, and a strip of bare PCB along the bottom.
    private func graphicsCard(_ w: CGFloat, _ h: CGFloat) -> some View {
        bottomAligned(h * 0.60) {
            ZStack {
                RoundedRectangle(cornerRadius: 2).fill(tint)
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle().fill(Color.black.opacity(0.4)).frame(height: h * 0.07)
                }
                HStack(spacing: w * 0.07) {
                    fanFace(h * 0.34)
                    fanFace(h * 0.34)
                }
                .offset(y: -h * 0.03)
            }
        }
    }

    /// A DIMM standing on end, heat spreader teeth along the top.
    private func memoryStick(_ w: CGFloat, _ h: CGFloat) -> some View {
        bottomAligned(h * 0.86) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 1.5).fill(tint)
                    .frame(width: w * 0.34)
                HStack(spacing: 1.5) {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle().fill(Color.white.opacity(0.35))
                            .frame(width: 2, height: h * 0.10)
                    }
                }
                .offset(y: -h * 0.04)
                VStack {
                    Spacer()
                    Rectangle().fill(Color.black.opacity(0.35))
                        .frame(width: w * 0.34, height: h * 0.06)
                }
            }
        }
    }

    /// PCB with a socket, memory slots and a PCIe slot.
    private func board(_ w: CGFloat, _ h: CGFloat) -> some View {
        bottomAligned(h * 0.80) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 1.5).fill(tint)

                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black.opacity(0.4))
                    .frame(width: w * 0.26, height: w * 0.26)
                    .offset(x: w * 0.13, y: h * 0.14)

                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle().fill(Color.white.opacity(0.28))
                            .frame(width: 2, height: h * 0.36)
                    }
                }
                .offset(x: w * 0.58, y: h * 0.13)

                Rectangle().fill(Color.white.opacity(0.28))
                    .frame(width: w * 0.58, height: 2.5)
                    .offset(x: w * 0.13, y: h * 0.62)
            }
        }
    }

    /// Heat spreader with the corner alignment notch.
    private func processor(_ w: CGFloat, _ h: CGFloat) -> some View {
        let side = min(w, h) * 0.62
        return bottomAligned(side) {
            ZStack {
                RoundedRectangle(cornerRadius: 2).fill(tint)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.22))
                    .padding(side * 0.18)
                Path { p in
                    p.move(to: CGPoint(x: side * 0.14, y: side * 0.14))
                    p.addLine(to: CGPoint(x: side * 0.30, y: side * 0.14))
                    p.addLine(to: CGPoint(x: side * 0.14, y: side * 0.30))
                    p.closeSubpath()
                }
                .fill(Color.black.opacity(0.45))
            }
            .frame(width: side, height: side)
        }
    }

    /// Boxy unit with the intake fan grille and a vent panel.
    private func powerSupply(_ w: CGFloat, _ h: CGFloat) -> some View {
        bottomAligned(h * 0.66) {
            ZStack {
                RoundedRectangle(cornerRadius: 2).fill(tint)
                HStack(spacing: w * 0.06) {
                    fanFace(h * 0.42)
                    VStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle().fill(Color.black.opacity(0.3))
                                .frame(width: w * 0.22, height: 2)
                        }
                    }
                }
            }
        }
    }

    private func caseFan(_ w: CGFloat, _ h: CGFloat) -> some View {
        let side = min(w, h) * 0.74
        return bottomAligned(side) {
            ZStack {
                RoundedRectangle(cornerRadius: 2).fill(tint)
                fanFace(side * 0.78)
            }
            .frame(width: side, height: side)
        }
    }

    // MARK: Peripherals

    private func monitor(_ w: CGFloat, _ h: CGFloat) -> some View {
        VStack(spacing: 1) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(tint)
                .overlay(RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black.opacity(0.4)).padding(1.5))
                .frame(height: h * 0.56)
            Rectangle().fill(tint.opacity(0.8)).frame(width: w * 0.10, height: h * 0.12)
            Capsule().fill(tint.opacity(0.8)).frame(width: w * 0.42, height: 2.5)
        }
        .frame(width: w, height: h, alignment: .bottom)
    }

    private func keyboard(_ w: CGFloat, _ h: CGFloat) -> some View {
        bottomAligned(h * 0.40) {
            ZStack {
                RoundedRectangle(cornerRadius: 2).fill(tint)
                VStack(spacing: 1.5) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 1.5) {
                            ForEach(0..<7, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(Color.black.opacity(0.3))
                            }
                        }
                    }
                }
                .padding(2.5)
            }
        }
    }

    private func mouse(_ w: CGFloat, _ h: CGFloat) -> some View {
        bottomAligned(h * 0.56) {
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.30).fill(tint)
                    .frame(width: w * 0.44)
                Rectangle().fill(Color.black.opacity(0.32))
                    .frame(width: 1.2, height: h * 0.18)
                    .offset(y: -h * 0.13)
            }
        }
    }

    private func headset(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            Path { p in
                p.addArc(center: CGPoint(x: w / 2, y: h * 0.74),
                         radius: w * 0.28,
                         startAngle: .degrees(180), endAngle: .degrees(360),
                         clockwise: false)
            }
            .stroke(tint, lineWidth: 2.5)
            HStack(spacing: w * 0.40) {
                Capsule().fill(tint).frame(width: w * 0.15, height: h * 0.28)
                Capsule().fill(tint).frame(width: w * 0.15, height: h * 0.28)
            }
            .offset(y: h * 0.16)
        }
        .frame(width: w, height: h, alignment: .bottom)
    }

    private func boxedProduct(_ w: CGFloat, _ h: CGFloat) -> some View {
        bottomAligned(h * 0.70) {
            ZStack {
                RoundedRectangle(cornerRadius: 1.5).fill(tint)
                Rectangle().fill(Color.black.opacity(0.22)).frame(height: 2.5)
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: w * 0.32, height: 3)
                    .offset(y: h * 0.15)
            }
        }
    }

    // MARK: Shared pieces

    private func fanFace(_ diameter: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.42))
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: diameter * 0.14, height: diameter * 0.62)
                    .rotationEffect(.degrees(Double(index) * 60))
            }
            Circle().fill(Color.white.opacity(0.3)).frame(width: diameter * 0.24)
        }
        .frame(width: diameter, height: diameter)
    }

    private func bottomAligned<Content: View>(_ height: CGFloat,
                                              @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            content().frame(height: height)
        }
    }
}

// MARK: - Shelf board

private struct ShelfBoard: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.Shop.shelfLip).frame(height: 2)
            Rectangle().fill(Theme.Shop.shelf).frame(height: 6)
        }
    }
}

/// A shelf holding real stock. Fills from the left, the way a shop
/// shelf actually fills.
private struct StockShelf: View {
    let items: [StockItem]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(items) { item in
                    MerchItem(kind: item.part.category.merch,
                              tint: item.part.category.tint)
                        .frame(width: 42, height: 36)
                        .transition(.scale.combined(with: .opacity))
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 36, alignment: .bottomLeading)
            .padding(.horizontal, 16)

            ShelfBoard()
        }
    }
}

/// The permanent display shelf. Peripherals aren't sellable yet, so these
/// are shop dressing — and they keep the wall from looking broken on day one.
private struct DisplayShelf: View {
    let contents: [(Merch, Int)]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(contents.enumerated()), id: \.offset) { _, entry in
                    MerchItem(kind: entry.0,
                              tint: Theme.Shop.merch[entry.1 % Theme.Shop.merch.count])
                        .frame(width: 42, height: 36)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            ShelfBoard()
        }
    }
}

// MARK: - Scene

struct ShopScene<Foreground: View>: View {
    let stock: [StockItem]
    let onShelvesTapped: () -> Void
    @ViewBuilder var foreground: () -> Foreground

    /// Grouped by category so like sits with like, capped at what fits.
    private var shelved: [StockItem] {
        Array(stock.sorted { lhs, rhs in
            let l = PartCategory.buildOrder.firstIndex(of: lhs.part.category) ?? 0
            let r = PartCategory.buildOrder.firstIndex(of: rhs.part.category) ?? 0
            return l < r
        }.prefix(8))
    }

    private var topRow: [StockItem] { Array(shelved.prefix(4)) }
    private var secondRow: [StockItem] { Array(shelved.dropFirst(4)) }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Theme.Shop.wallTop, Theme.Shop.wallBottom],
                           startPoint: .top, endPoint: .bottom)

            VStack(spacing: 0) {
                Button(action: onShelvesTapped) {
                    VStack(spacing: 16) {
                        StockroomTag(count: stock.count)

                        ZStack {
                            VStack(spacing: 16) {
                                StockShelf(items: topRow)
                                StockShelf(items: secondRow)
                            }
                            if stock.isEmpty {
                                Text("Shelves are bare")
                                    .font(.spec(11))
                                    .foregroundStyle(Theme.muted)
                                    .offset(y: -8)
                            }
                        }

                        DisplayShelf(contents: [(.monitor, 5), (.keyboard, 0),
                                                (.mouse, 4), (.headset, 1)])
                    }
                    .padding(.top, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }

            // Floor
            VStack(spacing: 0) {
                Rectangle().fill(Theme.Shop.counterLip).frame(height: 2)
                Theme.Shop.floor
            }
            .frame(height: 118)

            foreground()
                .padding(.bottom, 14)
        }
        .clipped()
    }
}

// MARK: - Stockroom affordance
//
// The shelves show stock, but they're also the doorway to the stockroom.
// Without a label nobody would think to tap them.

private struct StockroomTag: View {
    let count: Int

    var body: some View {
        HStack(spacing: 5) {
            Text("STOCKROOM")
                .font(.spec(9, .semibold)).tracking(1.4)
            Text("·")
            Text(count == 1 ? "1 part" : "\(count) parts")
                .font(.spec(9, .semibold))
            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundStyle(count == 0 ? Theme.muted : Theme.gold)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Capsule().fill(Theme.ink.opacity(0.5)))
    }
}
