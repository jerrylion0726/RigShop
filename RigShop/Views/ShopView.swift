//
//  ShopView.swift
//  RigShop
//
//  Today's supplier offers. Prices move every day, which is the whole
//  reason this screen exists — the signature element is the delta chip
//  showing how far today's price sits from the reference price.
//
//  Red means the price went up, which is bad news for a buyer.
//
//  CPUs and graphics cards carry a performance score; boards, memory
//  and power supplies do not. Those three decide whether the machine
//  runs at all, not how fast it is, so showing them a score would be
//  a lie.
//

import SwiftUI

struct ShopView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(store.marketByCategory, id: \.category) { group in
                        Section {
                            ForEach(group.listings) { listing in
                                ListingRow(listing: listing)
                                Rectangle()
                                    .fill(Theme.line)
                                    .frame(height: 1)
                                    .padding(.leading, 16)
                            }
                        } header: {
                            CategoryHeader(category: group.category)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Theme.ink)
            .navigationTitle("Supplier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.spec(13, .semibold))
                        .foregroundStyle(Theme.gold)
                }
            }
        }
    }
}

// MARK: - Section header

private struct CategoryHeader: View {
    let category: PartCategory

    /// Only two categories move the performance needle. Saying so in the
    /// header saves the player from hunting for a score that isn't there.
    private var note: String? {
        switch category {
        case .cpu, .gpu:              return "scored"
        case .motherboard, .memory:   return "compatibility only"
        case .psu:                    return "must cover the load"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.symbol)
                .font(.system(size: 12, weight: .semibold))
            Text(category.displayName.uppercased())
                .font(.spec(11, .semibold))
                .tracking(1.4)
            if let note {
                Text("· \(note)")
                    .font(.spec(9))
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
        }
        .foregroundStyle(category.tint)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.surface)
    }
}

// MARK: - Row

private struct ListingRow: View {
    @Environment(GameStore.self) private var store
    let listing: MarketListing

    private var blocked: String? { store.blockReason(for: listing) }

    /// Scores exist for CPUs and GPUs only.
    private var showsScore: Bool {
        listing.part.category == .cpu || listing.part.category == .gpu
    }

    var body: some View {
        HStack(spacing: 0) {
            // Category edge, like the colour band on a shelf label.
            Rectangle()
                .fill(listing.part.category.tint)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(listing.part.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(listing.part.specSummary)
                    Text("·")
                    Text("\(listing.stock) left")
                }
                .font(.spec(11))
                .foregroundStyle(Theme.muted)
            }
            .padding(.leading, 13)

            Spacer(minLength: 6)

            if showsScore {
                ScoreBadge(score: listing.part.score,
                           tint: listing.part.category.tint)
                    .padding(.trailing, 10)
            }

            VStack(alignment: .trailing, spacing: 3) {
                Text(listing.todayPrice.money)
                    .font(.spec(15, .semibold))
                    .foregroundStyle(Theme.gold)
                PriceDelta(percent: listing.priceDelta)
            }

            BuyButton(enabled: blocked == nil) {
                store.buy(listing)
            }
            .padding(.leading, 10)
        }
        .padding(.trailing, 14)
        .padding(.vertical, 11)
        .opacity(blocked == nil ? 1 : 0.45)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(blocked ?? "Buy one")
    }

    private var accessibilityText: String {
        let base = "\(listing.part.name), \(listing.todayPrice.money)"
        return showsScore ? base + ", scores \(listing.part.score)" : base
    }
}

// MARK: - Score badge
//
// The number that decides whether a customer walks away happy.
// Everything else on this row is a constraint; this is the value.

private struct ScoreBadge: View {
    let score: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 0) {
            Text("\(score)")
                .font(.spec(16, .bold))
                .foregroundStyle(tint)
            Text("PTS")
                .font(.spec(7, .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.muted)
        }
        .frame(minWidth: 30)
    }
}

// MARK: - Delta chip

private struct PriceDelta: View {
    let percent: Int

    var body: some View {
        if percent == 0 {
            Text("—")
                .font(.spec(10, .semibold))
                .foregroundStyle(Theme.muted)
        } else {
            HStack(spacing: 1) {
                Image(systemName: percent > 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 8, weight: .bold))
                Text("\(abs(percent))%")
                    .font(.spec(10, .semibold))
            }
            .foregroundStyle(percent > 0 ? Theme.fault : Theme.solder)
        }
    }
}

// MARK: - Buy button

private struct BuyButton: View {
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Buy")
                .font(.spec(12, .semibold))
                .foregroundStyle(enabled ? Theme.ink : Theme.muted)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(enabled ? Theme.gold : Theme.raised)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
