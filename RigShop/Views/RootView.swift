//
//  RootView.swift
//  RigShop
//
//  The shell: a status bar that never goes away, and the tabs beneath it.
//  Day, cash and reputation stay visible because every decision in this
//  game is made against those three numbers.
//

import SwiftUI

struct RootView: View {
    @State private var store = GameStore()

    var body: some View {
        VStack(spacing: 0) {
            StatusBar()
            TabView {
                ShopView()
                    .tabItem { Label("Supplier", systemImage: "shippingbox") }
                ComingSoonView(title: "Inventory", step: 9)
                    .tabItem { Label("Inventory", systemImage: "tray.full") }
                ComingSoonView(title: "Orders", step: 10)
                    .tabItem { Label("Orders", systemImage: "person.2") }
            }
        }
        .background(Theme.ink)
        .environment(store)
        .tint(Theme.gold)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Status bar

struct StatusBar: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        HStack(spacing: 0) {
            stat(label: "DAY", value: "\(store.state.day)", tint: Theme.text)
            divider
            stat(label: "CASH", value: store.state.cash.money, tint: Theme.gold)
            divider
            stat(label: "REPUTATION", value: "\(store.state.reputation)", tint: reputationTint)
        }
        .padding(.vertical, 10)
        .background(Theme.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }

    private var reputationTint: Color {
        switch store.state.reputation {
        case ..<30:  return Theme.fault
        case ..<60:  return Theme.muted
        default:     return Theme.solder
        }
    }

    private var divider: some View {
        Rectangle().fill(Theme.line).frame(width: 1, height: 26)
    }

    private func stat(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.spec(9, .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(.spec(17, .semibold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Placeholder

struct ComingSoonView: View {
    let title: String
    let step: Int

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text("Arrives in Step \(step).")
                    .font(.spec(13))
                    .foregroundStyle(Theme.muted)
            }
        }
    }
}
