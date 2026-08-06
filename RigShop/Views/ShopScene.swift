//
//  ShopScene.swift
//  RigShop
//
//  The storefront, drawn entirely with SwiftUI shapes. No image assets,
//  so it costs nothing, has no licensing questions, and stays sharp at
//  any size.
//
//  The shelf stock is decoration — keyboards, mice, headsets. When
//  peripherals become sellable in a later version, these become real.
//

import SwiftUI

// MARK: - Merchandise

enum Merch: CaseIterable {
    case keyboard, mouse, headset, monitor, box, fan
}

struct MerchItem: View {
    let kind: Merch
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            switch kind {
            case .keyboard: keyboard(w, h)
            case .mouse:    mouse(w, h)
            case .headset:  headset(w, h)
            case .monitor:  monitor(w, h)
            case .box:      box(w, h)
            case .fan:      fan(w, h)
            }
        }
    }

    private func keyboard(_ w: CGFloat, _ h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(tint)
                VStack(spacing: 1.5) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 1.5) {
                            ForEach(0..<6, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(Color.black.opacity(0.28))
                            }
                        }
                    }
                }
                .padding(2.5)
            }
            .frame(height: h * 0.42)
        }
        .frame(width: w, height: h)
    }

    private func mouse(_ w: CGFloat, _ h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.34)
                    .fill(tint)
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 1, height: h * 0.22)
                    .offset(y: -h * 0.15)
            }
            .frame(width: w * 0.5, height: h * 0.62)
        }
        .frame(width: w, height: h)
    }

    private func headset(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            Path { p in
                p.addArc(center: CGPoint(x: w / 2, y: h * 0.72),
                         radius: w * 0.3,
                         startAngle: .degrees(180),
                         endAngle: .degrees(360),
                         clockwise: false)
            }
            .stroke(tint, lineWidth: 2.5)

            HStack(spacing: w * 0.42) {
                Capsule().fill(tint).frame(width: w * 0.16, height: h * 0.3)
                Capsule().fill(tint).frame(width: w * 0.16, height: h * 0.3)
            }
            .offset(y: h * 0.18)
        }
        .frame(width: w, height: h)
    }

    private func monitor(_ w: CGFloat, _ h: CGFloat) -> some View {
        VStack(spacing: 1) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(tint)
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.black.opacity(0.35))
                        .padding(1.5)
                )
                .frame(height: h * 0.6)
            Rectangle().fill(tint.opacity(0.8)).frame(width: w * 0.12, height: h * 0.12)
            Capsule().fill(tint.opacity(0.8)).frame(width: w * 0.45, height: 2)
        }
        .frame(width: w, height: h)
    }

    private func box(_ w: CGFloat, _ h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack {
                RoundedRectangle(cornerRadius: 1.5).fill(tint)
                Rectangle()
                    .fill(Color.black.opacity(0.22))
                    .frame(height: 2.5)
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: w * 0.34, height: 3)
                    .offset(y: h * 0.16)
            }
            .frame(height: h * 0.72)
        }
        .frame(width: w, height: h)
    }

    private func fan(_ w: CGFloat, _ h: CGFloat) -> some View {
        let side = min(w, h) * 0.78
        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack {
                RoundedRectangle(cornerRadius: 2).fill(tint)
                Circle().fill(Color.black.opacity(0.3)).padding(2)
                Circle().fill(tint).frame(width: side * 0.28)
            }
            .frame(width: side, height: side)
        }
        .frame(width: w, height: h)
    }
}

// MARK: - Shelf

private struct Shelf: View {
    /// Fixed contents — this is set dressing, not data.
    let contents: [(Merch, Int)]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(contents.enumerated()), id: \.offset) { _, entry in
                    MerchItem(kind: entry.0,
                              tint: Theme.Shop.merch[entry.1 % Theme.Shop.merch.count])
                        .frame(width: 30, height: 26)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)

            // The board, with a lighter front lip for depth.
            Rectangle().fill(Theme.Shop.shelfLip).frame(height: 2)
            Rectangle().fill(Theme.Shop.shelf).frame(height: 5)
        }
    }
}

// MARK: - Scene

struct ShopScene<Foreground: View>: View {
    @ViewBuilder var foreground: () -> Foreground

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Theme.Shop.wallTop, Theme.Shop.wallBottom],
                           startPoint: .top, endPoint: .bottom)

            VStack(spacing: 20) {
                Shelf(contents: [(.keyboard, 0), (.mouse, 2), (.headset, 4), (.box, 3)])
                Shelf(contents: [(.monitor, 5), (.box, 1), (.fan, 3), (.keyboard, 2)])
                Spacer(minLength: 0)
            }
            .padding(.top, 18)

            // Floor
            VStack(spacing: 0) {
                Rectangle().fill(Theme.Shop.counterLip).frame(height: 2)
                Theme.Shop.floor
            }
            .frame(height: 118)

            // Whoever is standing in the shop right now.
            foreground()
                .padding(.bottom, 14)
        }
        .clipped()
    }
}
