//
//  CustomerFigure.swift
//  RigShop
//
//  A customer standing in the shop. Drawn, not imported.
//
//  The mouth curve is driven by `daysWaiting`. A mechanic that used to
//  live invisibly inside the data — customers give up after three days —
//  is now something you can see on their face.
//

import SwiftUI

struct CustomerFigure: View {
    let order: CustomerOrder
    var isSelected: Bool = false

    /// 1.0 = just walked in, 0.0 = about to leave.
    private var patienceLeft: Double {
        let left = Double(CustomerOrder.patience - order.daysWaiting)
        return (left / Double(CustomerOrder.patience)).clamped(to: 0...1)
    }

    /// Stable across launches: derived from the UUID's own bytes rather
    /// than hashValue, which is seeded per process.
    private var shirt: Color {
        let byte = Int(order.id.uuid.0)
        return Theme.Shop.shirts[byte % Theme.Shop.shirts.count]
    }

    var body: some View {
        VStack(spacing: 3) {
            WantBubble(symbol: order.useCase.symbol, urgent: patienceLeft <= 0.34)

            ZStack(alignment: .bottom) {
                // Body
                UnevenRoundedRectangle(topLeadingRadius: 11,
                                       bottomLeadingRadius: 2,
                                       bottomTrailingRadius: 2,
                                       topTrailingRadius: 11)
                    .fill(shirt)
                    .frame(width: 26, height: 32)

                // Head
                Face(patience: patienceLeft)
                    .frame(width: 24, height: 24)
                    .offset(y: -28)
            }
            .frame(height: 56, alignment: .bottom)

            PatienceDots(remaining: CustomerOrder.patience - order.daysWaiting)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.gold.opacity(isSelected ? 0.16 : 0))
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(order.name), wants \(order.useCase.displayName)")
        .accessibilityHint("Budget \(order.budget.money)")
    }
}

// MARK: - Face

private struct Face: View {
    /// 1.0 happy, 0.0 fed up.
    let patience: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Circle().fill(Theme.Shop.skin)

                // Eyes
                HStack(spacing: w * 0.22) {
                    eye(w)
                    eye(w)
                }
                .offset(y: -h * 0.06)

                // Mouth: curves up when patient, down when not.
                Path { p in
                    let left  = CGPoint(x: w * 0.34, y: h * 0.66)
                    let right = CGPoint(x: w * 0.66, y: h * 0.66)
                    // +0.14 at full patience, -0.10 at none.
                    let bend = h * (patience * 0.24 - 0.10)
                    p.move(to: left)
                    p.addQuadCurve(to: right,
                                   control: CGPoint(x: w * 0.5, y: h * 0.66 + bend))
                }
                .stroke(Color.black.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            }
        }
    }

    private func eye(_ w: CGFloat) -> some View {
        Circle()
            .fill(Color.black.opacity(0.7))
            .frame(width: w * 0.11, height: w * 0.11)
    }
}

// MARK: - Want bubble

private struct WantBubble: View {
    let symbol: String
    let urgent: Bool

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.ink)
            .frame(width: 22, height: 20)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(urgent ? Theme.fault : Theme.text)
            )
    }
}

// MARK: - Patience

private struct PatienceDots: View {
    let remaining: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<CustomerOrder.patience, id: \.self) { index in
                Circle()
                    .fill(index < remaining ? tint : Theme.line)
                    .frame(width: 4, height: 4)
            }
        }
    }

    private var tint: Color {
        switch remaining {
        case ...1: return Theme.fault
        case 2:    return Theme.gold
        default:   return Theme.solder
        }
    }
}
