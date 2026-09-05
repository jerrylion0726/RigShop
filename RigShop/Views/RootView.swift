//
//  RootView.swift
//  RigShop
//
//  Title screen first, then the shop floor. The tab bar is gone —
//  everything else is somewhere you walk over to: the supplier, the
//  stockroom, the door.
//

import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var store = GameStore()
    @State private var open = false

    var body: some View {
        Group {
            if open {
                HomeView()
                    .transition(.opacity)
            } else {
                TitleView(store: store) {
                    withAnimation(.easeInOut(duration: 0.3)) { open = true }
                }
                .transition(.opacity)
            }
        }
        .environment(store)
        .tint(Theme.gold)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            // Actions already save as they happen; this covers the swipe-away.
            if phase != .active { store.persist() }
        }
    }
}
