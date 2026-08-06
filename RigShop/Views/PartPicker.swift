//
//  PartPicker.swift
//  RigShop
//
//  Choosing a part for one slot.
//
//  It lists your shelf *and* today's supplier offers together, because a
//  picker that only shows what you already own is useless on day one —
//  you would have to leave, guess what to buy, and come back. Buying from
//  here means every purchase is made against a target you can see.
//
//  When nothing in the list can be picked, the screen says so and says
//  what to do about it. A wall of greyed-out rows with no explanation
//  reads as a broken app, not as scarcity.
//

import SwiftUI

struct PartPicker: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let category: PartCategory
    let order: CustomerOrder
    let build: PCBuild
    /// Units already committed to other slots in this build.
    let usedIDs: Set<UUID>
    let onPick: (UUID) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let advice = deadEndAdvice {
                        DeadEnd(text: advice)
                    }

                    Header(text: "ON YOUR SHELF",
                           note: owned.isEmpty ? "nothing here yet" : "\(owned.count)")
                    ForEach(owned) { item in
                        OwnedRow(item: item,
                                 order: order,
                                 blocked: blockReason(for: item.part)) {
                            onPick(item.id)
                        }
                        Divider().overlay(Theme.line).padding(.leading, 16)
                    }

                    Header(text: "BUY TODAY",
                           note: offers.isEmpty ? "supplier is out" : "\(offers.count)")
                    ForEach(offers) { listing in
                        OfferRow(listing: listing,
                                 order: order,
                                 blocked: blockReason(for: listing.part)
                                          ?? affordability(listing)) {
                            if let bought = store.buyForBuild(listing) {
                                onPick(bought.id)
                            }
                        }
                        Divider().overlay(Theme.line).padding(.leading, 16)
                    }

                    Color.clear.frame(height: 20)
                }
            }
            .background(Theme.ink)
            .navigationTitle(category.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(.spec(13, .semibold))
                        .foregroundStyle(Theme.muted)
                }
            }
        }
    }

    // MARK: Data

    private var owned: [StockItem] {
        store.state.stock(in: category).filter { !usedIDs.contains($0.id) }
    }

    private var offers: [MarketListing] {
        store.state.market
            .filter { $0.part.category == category && $0.stock > 0 }
            .sorted { $0.todayPrice < $1.todayPrice }
    }

    /// Why this part can't go in the slot, in the player's language.
    private func blockReason(for part: Part) -> String? {
        var candidate = build
        candidate[category] = part
        let newIssues = Compatibility.check(candidate).filter {
            if case .missingPart = $0 { return false }
            return true
        }
        return newIssues.first?.message
    }

    private func affordability(_ listing: MarketListing) -> String? {
        store.state.cash >= listing.todayPrice ? nil : "Not enough cash"
    }

    // MARK: Dead ends

    private var hasPickableOption: Bool {
        owned.contains { blockReason(for: $0.part) == nil }
            || offers.contains { blockReason(for: $0.part) == nil && affordability($0) == nil }
    }

    /// Everything visible is compatible, but too expensive.
    private var blockedOnlyByMoney: Bool {
        !offers.isEmpty
            && offers.allSatisfy { blockReason(for: $0.part) == nil }
            && offers.allSatisfy { affordability($0) != nil }
            && owned.isEmpty
    }

    private var deadEndAdvice: String? {
        guard !hasPickableOption else { return nil }

        if owned.isEmpty && offers.isEmpty {
            return "The supplier is out of \(category.displayName.lowercased()) today, "
                 + "and your shelf is bare. Close up — stock is refreshed every morning."
        }
        if blockedOnlyByMoney {
            return "These all fit, but you can't afford any of them. "
                 + "Dump something from inventory to free up cash, or take a cheaper job first."
        }
        return "Nothing here works with the parts you've already slotted. "
             + "Tap the ✕ on a slot to change it, or close up — the supplier restocks tomorrow."
    }
}

// MARK: - Dead end banner

private struct DeadEnd: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.gold)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 11).fill(Theme.gold.opacity(0.13)))
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }
}

// MARK: - Header

private struct Header: View {
    let text: String
    let note: String?

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.spec(10, .semibold)).tracking(1.3)
                .foregroundStyle(Theme.muted)
            if let note {
                Text("· \(note)")
                    .font(.spec(9))
                    .foregroundStyle(Theme.muted.opacity(0.7))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 7)
    }
}

// MARK: - Rows

private struct OwnedRow: View {
    let item: StockItem
    let order: CustomerOrder
    let blocked: String?
    let pick: () -> Void

    var body: some View {
        PartRow(part: item.part,
                order: order,
                trailingLabel: "OWNED",
                trailingValue: "paid \(item.paidPrice.money)",
                trailingTint: Theme.muted,
                blocked: blocked,
                action: pick)
    }
}

private struct OfferRow: View {
    let listing: MarketListing
    let order: CustomerOrder
    let blocked: String?
    let buy: () -> Void

    var body: some View {
        PartRow(part: listing.part,
                order: order,
                trailingLabel: "BUY",
                trailingValue: listing.todayPrice.money,
                trailingTint: Theme.gold,
                blocked: blocked,
                action: buy)
    }
}

private struct PartRow: View {
    let part: Part
    let order: CustomerOrder
    let trailingLabel: String
    let trailingValue: String
    let trailingTint: Color
    let blocked: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(part.category.tint)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 3) {
                    Text(part.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)

                    if let blocked {
                        Text(blocked)
                            .font(.spec(10))
                            .foregroundStyle(Theme.fault)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(part.specSummary)
                            .font(.spec(10))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .padding(.leading, 12)

                Spacer(minLength: 8)

                // What this part is worth to *this* customer.
                if let points = part.contribution(for: order.useCase) {
                    VStack(spacing: 0) {
                        Text("+\(points)")
                            .font(.spec(15, .bold))
                            .foregroundStyle(part.category.tint)
                        Text("PTS")
                            .font(.spec(7, .semibold)).tracking(0.7)
                            .foregroundStyle(Theme.muted)
                    }
                    .frame(minWidth: 34)
                    .padding(.trailing, 10)
                }

                VStack(alignment: .trailing, spacing: 1) {
                    Text(trailingLabel)
                        .font(.spec(7, .semibold)).tracking(0.8)
                        .foregroundStyle(Theme.muted)
                    Text(trailingValue)
                        .font(.spec(13, .semibold))
                        .foregroundStyle(trailingTint)
                }
            }
            .padding(.trailing, 16)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
            .opacity(blocked == nil ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(blocked != nil)
        .accessibilityLabel(part.name)
        .accessibilityHint(blocked ?? "Select")
    }
}
