//
//  HomeView.swift
//  RigShop
//
//  The hub. Everything else opens from here.
//
//  Order of operations matters: you see who is standing in your shop
//  before you see the supplier's catalogue. Buying first and finding
//  out what people wanted afterwards is how you go broke on day one.
//

import SwiftUI

struct HomeView: View {
    @Environment(GameStore.self) private var store

    @State private var showSupplier = false
    @State private var showInventory = false
    @State private var selectedOrder: CustomerOrder?
    /// Held while the order card dismisses, then promoted to `building`.
    /// Presenting a sheet from inside a dismissing sheet drops the second
    /// one, so the handoff happens in onDismiss instead.
    @State private var pendingBuild: CustomerOrder?
    @State private var building: CustomerOrder?

    var body: some View {
        VStack(spacing: 0) {
            TopBar()

            ShopScene(stock: store.state.inventory,
                      onShelvesTapped: { showInventory = true }) {
                CustomerRow(selected: $selectedOrder)
            }

            ActionBar(supplier: { showSupplier = true },
                      inventory: { showInventory = true },
                      endDay: {
                          withAnimation(.easeInOut(duration: 0.25)) { store.advanceDay() }
                      })
        }
        .background(Theme.ink)
        .sheet(isPresented: $showSupplier) { ShopView() }
        .sheet(isPresented: $showInventory) { InventoryView() }
        .sheet(item: $selectedOrder, onDismiss: {
            if let pending = pendingBuild {
                pendingBuild = nil
                building = pending
            }
        }) { order in
            OrderCard(order: order) {
                pendingBuild = order
                selectedOrder = nil
            }
        }
        .fullScreenCover(item: $building) { order in
            BuildView(order: order)
        }
    }
}

// MARK: - Score vocabulary
//
// A bare number has no frame of reference. "27" tells the player
// nothing until it also says "Entry".

enum PerformanceTier: String {
    case basic   = "Basic"
    case entry   = "Entry"
    case solid   = "Solid"
    case strong  = "Strong"
    case highEnd = "High-end"
    case extreme = "Extreme"

    init(score: Int) {
        switch score {
        case ..<25:  self = .basic
        case ..<45:  self = .entry
        case ..<65:  self = .solid
        case ..<85:  self = .strong
        case ..<105: self = .highEnd
        default:     self = .extreme
        }
    }

    var tint: Color {
        switch self {
        case .basic, .entry:   return Theme.muted
        case .solid, .strong:  return Theme.solder
        case .highEnd:         return Theme.gold
        case .extreme:         return Theme.fault
        }
    }
}

// MARK: - Top bar

private struct TopBar: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        VStack(spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("CASH")
                        .font(.spec(9, .semibold)).tracking(1.2)
                        .foregroundStyle(Theme.muted)
                    Text(store.state.cash.money)
                        .font(.spec(24, .bold))
                        .foregroundStyle(Theme.gold)
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 12)

                HStack(spacing: 16) {
                    stat("DAY", "\(store.state.day)", Theme.text)
                    stat("REP", "\(store.state.reputation)", repTint)
                    stat("LVL", "\(store.state.level)", Theme.gold)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)

            LevelBar(progress: store.state.levelProgress,
                     toNext: store.state.ordersToNextLevel)
        }
        .background(Theme.surface)
    }

    private var repTint: Color {
        switch store.state.reputation {
        case ..<30: return Theme.fault
        case ..<60: return Theme.muted
        default:    return Theme.solder
        }
    }

    private func stat(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(label)
                .font(.spec(9, .semibold)).tracking(1.2)
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(.spec(16, .semibold))
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Level progress

private struct LevelBar: View {
    let progress: Double
    let toNext: Int?

    var body: some View {
        VStack(spacing: 3) {
            Text(caption)
                .font(.spec(9))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Theme.line)
                    Rectangle()
                        .fill(Theme.gold)
                        .frame(width: max(0, geo.size.width * progress))
                }
            }
            .frame(height: 3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
    }

    private var caption: String {
        guard let toNext else { return "Top level — the supplier has nothing left to unlock." }
        return toNext == 1
            ? "1 more order unlocks new stock"
            : "\(toNext) more orders unlock new stock"
    }
}

// MARK: - Customers on the floor

private struct CustomerRow: View {
    @Environment(GameStore.self) private var store
    @Binding var selected: CustomerOrder?

    var body: some View {
        Group {
            if store.state.orders.isEmpty {
                Text("Nobody's in yet. Close up and try tomorrow.")
                    .font(.spec(12))
                    .foregroundStyle(Theme.muted)
                    .padding(.bottom, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(store.state.orders) { order in
                            CustomerFigure(order: order)
                                .onTapGesture { selected = order }
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Action bar

private struct ActionBar: View {
    @Environment(GameStore.self) private var store
    let supplier: () -> Void
    let inventory: () -> Void
    let endDay: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ActionButton(title: "Supplier", symbol: "shippingbox.fill",
                         filled: true, badge: nil, action: supplier)
            ActionButton(title: "Inventory", symbol: "tray.full.fill",
                         filled: false,
                         badge: store.state.inventory.isEmpty
                                ? nil : "\(store.state.inventory.count)",
                         action: inventory)
            ActionButton(title: "Close Up", symbol: "moon.fill",
                         filled: false, badge: nil, action: endDay)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(Theme.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }
}

private struct ActionButton: View {
    let title: String
    let symbol: String
    let filled: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 15, weight: .semibold))
                Text(title).font(.spec(11, .semibold))
            }
            .foregroundStyle(filled ? Theme.ink : Theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(filled ? Theme.gold : Theme.raised)
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.spec(9, .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.gold))
                        .offset(x: -6, y: 6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Order card

private struct OrderCard: View {
    let order: CustomerOrder
    let build: () -> Void

    private var tier: PerformanceTier { PerformanceTier(score: order.expectedScore) }

    private var shortName: String {
        order.name.split(separator: " ").first.map(String.init) ?? order.name
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Capsule().fill(Theme.line).frame(width: 36, height: 4).padding(.top, 10)

                CustomerFigure(order: order)

                Text(order.name)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Theme.text)

                Text(order.useCase.request)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                HStack(spacing: 0) {
                    figure("BUDGET", order.budget.money, Theme.gold, sub: "you get paid this")
                    Rectangle().fill(Theme.line).frame(width: 1, height: 44)
                    figure("TARGET", "\(order.expectedScore) pts", Theme.text,
                           sub: tier.rawValue, subTint: tier.tint)
                    Rectangle().fill(Theme.line).frame(width: 1, height: 44)
                    figure("DAYS LEFT", "\(CustomerOrder.patience - order.daysWaiting)",
                           Theme.muted, sub: "then they walk")
                }
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                .padding(.horizontal, 18)

                WeightBreakdown(order: order)

                Text("Reach \(order.expectedScore) and \(shortName) is happy. "
                     + "Going far past it earns nothing extra — that's your own money.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
                    .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Theme.ink)
        // Pinned outside the scroll view. A primary action should never
        // need scrolling to find, and anything sitting on the sheet's
        // bottom edge competes with the home-indicator gesture area.
        .safeAreaInset(edge: .bottom) {
            Button(action: build) {
                Label("Build for \(shortName)", systemImage: "wrench.and.screwdriver.fill")
                    .font(.spec(14, .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.gold))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
        }
        .presentationDetents([.medium, .large])
    }

    private func figure(_ label: String,
                        _ value: String,
                        _ tint: Color,
                        sub: String,
                        subTint: Color = Theme.muted) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.spec(9, .semibold)).tracking(1.1).foregroundStyle(Theme.muted)
            Text(value).font(.spec(15, .semibold)).foregroundStyle(tint)
            Text(sub).font(.spec(8)).foregroundStyle(subTint)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - What this customer weighs

private struct WeightBreakdown: View {
    let order: CustomerOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("WHAT \(firstName.uppercased()) WEIGHS")
                .font(.spec(9, .semibold)).tracking(1.1)
                .foregroundStyle(Theme.muted)

            bar("CPU", order.useCase.cpuWeight, PartCategory.cpu.tint)
            bar("GPU", order.useCase.gpuWeight, PartCategory.gpu.tint)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var firstName: String {
        order.name.split(separator: " ").first.map(String.init) ?? order.name
    }

    private func bar(_ label: String, _ weight: Double, _ tint: Color) -> some View {
        HStack(spacing: 9) {
            Text(label)
                .font(.spec(10, .semibold))
                .foregroundStyle(Theme.muted)
                .frame(width: 26, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.raised)
                    Capsule().fill(tint).frame(width: geo.size.width * weight)
                }
            }
            .frame(height: 7)

            Text("\(Int((weight * 100).rounded()))%")
                .font(.spec(10, .semibold))
                .foregroundStyle(Theme.text)
                .frame(width: 34, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(Int((weight * 100).rounded())) percent")
    }
}

// MARK: - Inventory

private struct InventoryView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.state.inventory.isEmpty {
                    VStack(spacing: 6) {
                        Text("Shelf's empty.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.text)
                        Text("Parts you buy land here until a machine needs them.")
                            .font(.spec(11))
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(PartCategory.buildOrder, id: \.self) { category in
                            let items = store.state.stock(in: category)
                            if !items.isEmpty {
                                HStack {
                                    Text(category.displayName.uppercased())
                                        .font(.spec(10, .semibold)).tracking(1.3)
                                        .foregroundStyle(category.tint)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 6)

                                ForEach(items) { item in
                                    StockRow(item: item) { store.sellBack(item) }
                                    Divider().overlay(Theme.line).padding(.leading, 16)
                                }
                            }
                        }
                        Color.clear.frame(height: 20)
                    }
                }
            }
            .background(Theme.ink)
            .navigationTitle("Inventory · \(store.state.inventoryValue.money)")
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

private struct StockRow: View {
    let item: StockItem
    let sell: () -> Void

    private var loss: Int { item.paidPrice - item.part.salvageValue }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(item.part.category.tint).frame(width: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.part.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text("\(item.part.specSummary) · paid \(item.paidPrice.money)")
                    .font(.spec(10))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.leading, 12)

            Spacer(minLength: 8)

            Button(action: sell) {
                VStack(spacing: 1) {
                    Text("Dump")
                        .font(.spec(11, .semibold))
                    Text("\(item.part.salvageValue.money)")
                        .font(.spec(10))
                }
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 7).fill(Theme.raised))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Sell back at a loss of \(loss.money)")
        }
        .padding(.trailing, 16)
        .padding(.vertical, 10)
    }
}
