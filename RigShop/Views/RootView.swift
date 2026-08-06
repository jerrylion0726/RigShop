//
//  RootView.swift
//  RigShop
//
//  The tab bar is gone. The shop floor is the hub, and everything else
//  is something you walk over to: the supplier, the stockroom, the door.
//

import SwiftUI

struct RootView: View {
    @State private var store = GameStore()

    var body: some View {
        HomeView()
            .environment(store)
            .tint(Theme.gold)
            .preferredColorScheme(.dark)
    }
}
