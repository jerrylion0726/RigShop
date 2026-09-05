//
//  TitleView.swift
//  RigShop
//
//  The way in.
//
//  There is nothing to load — a spinner here would be theatre. What the
//  screen actually does is let you pick up where you left off, which is
//  the thing that was missing.
//
//  Account sign-in lives here eventually. Sign in with Apple needs a paid
//  Apple Developer Program membership, which is also required to ship to
//  the App Store, so it arrives with that rather than before it.
//

import SwiftUI

struct TitleView: View {
    let store: GameStore
    let start: () -> Void

    @State private var appeared = false
    @State private var confirmingNewGame = false

    private var hasSave: Bool { store.loadedFromSave }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.Shop.wallTop, Theme.ink],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Wordmark(spinning: appeared)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)

                Text("A shop, a shelf, and someone who needs a machine.")
                    .font(.spec(11))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 14)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 10) {
                    if hasSave {
                        Button(action: start) {
                            VStack(spacing: 3) {
                                Text("Continue")
                                    .font(.spec(15, .semibold))
                                Text(summary)
                                    .font(.spec(10))
                                    .foregroundStyle(Theme.ink.opacity(0.65))
                            }
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.gold))
                        }
                        .buttonStyle(.plain)

                        Button { confirmingNewGame = true } label: {
                            Text("New Game")
                                .font(.spec(14, .semibold))
                                .foregroundStyle(Theme.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.raised))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            store.startNewGame()
                            start()
                        } label: {
                            Text("Open the Shop")
                                .font(.spec(15, .semibold))
                                .foregroundStyle(Theme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.gold))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 34)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)

                // Reserved for Sign in with Apple, once the shop has a
                // paid developer account behind it.
                Text("Accounts and cloud saves — later")
                    .font(.spec(9))
                    .foregroundStyle(Theme.muted.opacity(0.6))
                    .padding(.top, 18)
                    .padding(.bottom, 26)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { appeared = true }
        }
        .alert("Start over?", isPresented: $confirmingNewGame) {
            Button("Cancel", role: .cancel) { }
            Button("New Game", role: .destructive) {
                store.startNewGame()
                start()
            }
        } message: {
            Text("This wipes \(summary). There's only one save slot.")
        }
    }

    private var summary: String {
        "Day \(store.state.day) · Lv \(store.state.level) · \(store.state.cash.money)"
    }
}

// MARK: - Wordmark
//
// The mark is a case fan, because that's the one part every machine in
// this shop has in common. It idles slowly rather than spinning fast —
// a shop at rest, not a loading indicator.

private struct Wordmark: View {
    let spinning: Bool
    @State private var angle: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Theme.gold.opacity(0.5), lineWidth: 2)
                    .frame(width: 74, height: 74)

                ZStack {
                    Circle().fill(Theme.ink.opacity(0.6)).frame(width: 58, height: 58)
                    ForEach(0..<5, id: \.self) { index in
                        Capsule()
                            .fill(Theme.gold.opacity(0.75))
                            .frame(width: 9, height: 34)
                            .offset(y: -8)
                            .rotationEffect(.degrees(Double(index) * 72))
                    }
                    Circle().fill(Theme.gold).frame(width: 15)
                }
                .rotationEffect(.degrees(angle))
            }

            Text("RIGSHOP")
                .font(.spec(28, .bold))
                .tracking(5)
                .foregroundStyle(Theme.text)
        }
        .onAppear {
            guard spinning else { return }
            withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
                angle = 360
            }
        }
    }
}
