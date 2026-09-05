//
//  BuildView.swift
//  RigShop
//
//  Where the game actually happens.
//
//  Two jobs share this screen. A new build is five empty slots. A repair
//  is a machine that already exists with a dead part in it — four slots
//  locked, one you have to fill, and every compatibility rule now working
//  against choices somebody else made.
//
//  Every number is answered from the customer's point of view, not the
//  part's. A 45-point graphics card is worth 32 points to a gamer and 9
//  to someone doing spreadsheets; the player should never have to do that
//  multiplication in their head.
//

import SwiftUI

// MARK: - Shared helper

extension Part {
    /// What this part adds to a build's weighted score for this customer.
    /// Only CPUs and graphics cards contribute; everything else decides
    /// whether the machine runs at all, not how fast it is.
    func contribution(for useCase: UseCase) -> Int? {
        switch category {
        case .cpu: return Int((Double(score) * useCase.cpuWeight).rounded())
        case .gpu: return Int((Double(score) * useCase.gpuWeight).rounded())
        default:   return nil
        }
    }
}

/// `sheet(item:)` needs an identity. FulfillmentResult is a value with no
/// natural id, so wrap it here rather than bending the Core model to suit
/// a presentation detail.
private struct ResultBox: Identifiable {
    let id = UUID()
    let outcome: FulfillmentResult
}

/// What's sitting in one slot right now.
private enum SlotState {
    /// Already in the customer's machine. Not yours, not for sale, not movable.
    case theirs(Part)
    /// Waiting on you — an empty slot on a new build, or a dead one on a repair.
    case open
    /// Something you supplied.
    case yours(StockItem)
}

// MARK: - Build screen

struct BuildView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let order: CustomerOrder

    /// Category → the specific StockItem chosen for that slot.
    @State private var slots: [PartCategory: UUID] = [:]
    @State private var picking: PartCategory?
    @State private var result: ResultBox?
    @State private var failure: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let repair = order.repair {
                        SymptomCard(repair: repair)
                    }

                    Scoreboard(order: order,
                               score: weightedScore,
                               cost: cost,
                               isComplete: build.isComplete)

                    VStack(spacing: 0) {
                        ForEach(PartCategory.buildOrder, id: \.self) { category in
                            SlotRow(category: category,
                                    state: slotState(for: category),
                                    useCase: order.useCase,
                                    isRepair: order.isRepair,
                                    choose: {
                                        if order.slotsToFill.contains(category) {
                                            picking = category
                                        }
                                    },
                                    clear: { slots.removeValue(forKey: category) })
                            if category != PartCategory.buildOrder.last {
                                Rectangle().fill(Theme.line).frame(height: 1)
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
                    .padding(.horizontal, 16)

                    IssueList(issues: issues)

                    Color.clear.frame(height: 90)
                }
                .padding(.top, 10)
            }
            .background(Theme.ink)
            .navigationTitle(order.isRepair ? "Repair for \(shortName)" : "Build for \(shortName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .font(.spec(13, .semibold))
                        .foregroundStyle(Theme.muted)
                }
            }
            .safeAreaInset(edge: .bottom) {
                DeliverBar(enabled: issues.isEmpty,
                           label: deliverLabel,
                           action: deliver)
            }
        }
        .sheet(item: $picking) { category in
            PartPicker(category: category,
                       order: order,
                       build: build,
                       usedIDs: Set(slots.values)) { pickedID in
                slots[category] = pickedID
                picking = nil
            }
        }
        .sheet(item: $result) { box in
            DeliveryResult(outcome: box.outcome) { dismiss() }
        }
        .alert("Couldn't hand it over",
               isPresented: Binding(get: { failure != nil },
                                    set: { if !$0 { failure = nil } })) {
            Button("OK", role: .cancel) { failure = nil }
        } message: {
            Text(failure ?? "")
        }
    }

    // MARK: Derived

    private var shortName: String {
        order.name.split(separator: " ").first.map(String.init) ?? order.name
    }

    private func item(for category: PartCategory) -> StockItem? {
        guard let id = slots[category] else { return nil }
        return store.state.inventory.first { $0.id == id }
    }

    private func slotState(for category: PartCategory) -> SlotState {
        if let item = item(for: category) { return .yours(item) }
        if let theirs = order.startingMachine[category] { return .theirs(theirs) }
        return .open
    }

    /// Their machine plus whatever you've fitted. For a new build the
    /// starting machine is empty, so this is just your five parts.
    private var build: PCBuild {
        var result = order.startingMachine
        for category in PartCategory.buildOrder {
            if let item = item(for: category) { result[category] = item.part }
        }
        return result
    }

    private var chosenIDs: [UUID] {
        PartCategory.buildOrder.compactMap { slots[$0] }
    }

    /// Real cost basis: what each unit actually cost you. Parts already in
    /// the customer's machine cost the shop nothing.
    private var cost: Int {
        chosenIDs.compactMap { id in
            store.state.inventory.first { $0.id == id }?.paidPrice
        }.reduce(0, +)
    }

    private var weightedScore: Int {
        Scoring.weightedScore(of: build, for: order.useCase)
    }

    private var issues: [CompatibilityIssue] {
        Compatibility.check(build)
    }

    private var deliverLabel: String {
        let missing = build.missingCategories.count
        if missing > 0 {
            if order.isRepair {
                return missing == 1 ? "Still one dead part" : "Still \(missing) dead parts"
            }
            return missing == 1 ? "1 slot empty" : "\(missing) slots empty"
        }
        if !issues.isEmpty { return "Won't run yet" }
        return order.isRepair
            ? "Hand it back for \(order.budget.money)"
            : "Deliver for \(order.budget.money)"
    }

    // MARK: Action

    private func deliver() {
        switch store.fulfill(orderID: order.id, using: chosenIDs) {
        case .success(let outcome):
            result = ResultBox(outcome: outcome)
        case .failure(let error):
            switch error {
            case .orderNotFound:    failure = "\(shortName) already left."
            case .partsNotInStock:  failure = "Some of those parts aren't on the shelf anymore."
            case .incompatible(let list):
                failure = list.first?.message ?? "That machine won't run."
            case .faultNotReplaced(let category):
                failure = "The dead \(category.displayName.lowercased()) is still in there."
            }
        }
    }
}

// MARK: - Symptom

private struct SymptomCard: View {
    let repair: RepairJob

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
                Text(repair.symptom)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 7) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 10))
                Text(repair.diagnosis)
                    .font(.spec(11, .semibold))
            }
            .foregroundStyle(Theme.fault)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .padding(.horizontal, 16)
    }
}

// MARK: - Scoreboard

private struct Scoreboard: View {
    let order: CustomerOrder
    let score: Int
    let cost: Int
    let isComplete: Bool

    private var shortName: String {
        order.name.split(separator: " ").first.map(String.init) ?? order.name
    }

    private var scrap: Int { order.repair?.scrapValue ?? 0 }
    private var meetsTarget: Bool { score >= order.expectedScore }
    private var profit: Int { order.budget + scrap - cost }

    /// The bar reaches the target marker at the requirement, with room
    /// beyond it so overshoot is visible rather than pegged.
    private var fill: Double {
        guard order.expectedScore > 0 else { return 0 }
        return min(1, Double(score) / (Double(order.expectedScore) * 1.4))
    }

    private let targetMark: Double = 1 / 1.4

    var body: some View {
        VStack(spacing: 12) {
            Text("WHAT \(shortName.uppercased()) SEES")
                .font(.spec(9, .semibold)).tracking(1.3)
                .foregroundStyle(Theme.muted)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(score)")
                    .font(.spec(38, .bold))
                    .foregroundStyle(meetsTarget ? Theme.solder : Theme.text)
                    .contentTransition(.numericText())
                Text("/ \(order.expectedScore)")
                    .font(.spec(17, .semibold))
                    .foregroundStyle(Theme.muted)
                if isComplete {
                    Image(systemName: meetsTarget
                          ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(meetsTarget ? Theme.solder : Theme.fault)
                        .font(.system(size: 17))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.raised)
                    Capsule()
                        .fill(meetsTarget ? Theme.solder : Theme.gold)
                        .frame(width: max(0, geo.size.width * fill))
                    Rectangle()
                        .fill(Theme.text.opacity(0.6))
                        .frame(width: 2)
                        .offset(x: geo.size.width * targetMark)
                }
            }
            .frame(height: 8)

            Text(hint)
                .font(.spec(10))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle().fill(Theme.line).frame(height: 1)

            HStack(spacing: 0) {
                figure("YOUR PARTS", cost.money, Theme.text)
                figure(order.isRepair ? "FEE" : "PAYS", order.budget.money, Theme.gold)
                figure("PROFIT",
                       (profit >= 0 ? "+" : "") + profit.money,
                       profit >= 0 ? Theme.solder : Theme.fault)
            }

            if scrap > 0 {
                Text("Includes \(scrap.money) scrap credit for the dead parts.")
                    .font(.spec(9))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .padding(.horizontal, 16)
    }

    private var hint: String {
        if !isComplete {
            return order.isRepair
                ? "Fit the dead slot and the machine comes back to life."
                : "Fill every slot to see whether this machine ships."
        }
        if !meetsTarget {
            return order.isRepair
                ? "Weaker than what died — \(shortName) will notice."
                : "Under target — \(shortName) won't be impressed."
        }
        if score - order.expectedScore > order.expectedScore / 3 {
            return "Well over target. They pay the same either way — that's margin you're giving away."
        }
        return "On target. That's the sweet spot."
    }

    private func figure(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.spec(9, .semibold)).tracking(1.1).foregroundStyle(Theme.muted)
            Text(value).font(.spec(15, .semibold)).foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Slot

private struct SlotRow: View {
    let category: PartCategory
    let state: SlotState
    let useCase: UseCase
    let isRepair: Bool
    let choose: () -> Void
    let clear: () -> Void

    private var locked: Bool {
        if case .theirs = state { return true }
        return false
    }

    var body: some View {
        Button(action: { if !locked { choose() } }) {
            HStack(spacing: 12) {
                Image(systemName: category.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconTint)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(category.displayName.uppercased())
                            .font(.spec(8, .semibold)).tracking(1.1)
                            .foregroundStyle(Theme.muted)
                        if locked {
                            Text("THEIRS")
                                .font(.spec(7, .semibold)).tracking(0.8)
                                .foregroundStyle(Theme.muted)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Theme.raised))
                        }
                    }
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(titleTint)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                trailing
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(locked)
    }

    private var title: String {
        switch state {
        case .theirs(let part):  return part.name
        case .yours(let item):   return item.part.name
        case .open:              return isRepair ? "Dead — tap to replace" : "Tap to choose"
        }
    }

    private var titleTint: Color {
        switch state {
        case .theirs:  return Theme.muted
        case .yours:   return Theme.text
        case .open:    return isRepair ? Theme.fault : Theme.muted
        }
    }

    private var iconTint: Color {
        switch state {
        case .theirs:  return Theme.muted.opacity(0.7)
        case .yours:   return category.tint
        case .open:    return isRepair ? Theme.fault : Theme.muted
        }
    }

    @ViewBuilder
    private var trailing: some View {
        switch state {
        case .theirs(let part):
            if let points = part.contribution(for: useCase) {
                Text("+\(points)")
                    .font(.spec(13, .semibold))
                    .foregroundStyle(Theme.muted)
            }
        case .yours(let item):
            HStack(spacing: 10) {
                if let points = item.part.contribution(for: useCase) {
                    Text("+\(points)")
                        .font(.spec(14, .semibold))
                        .foregroundStyle(category.tint)
                }
                Button(action: clear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
            }
        case .open:
            Image(systemName: isRepair ? "exclamationmark.triangle.fill" : "plus.circle")
                .font(.system(size: 15))
                .foregroundStyle(isRepair ? Theme.fault : Theme.muted)
        }
    }
}

// MARK: - Issues

private struct IssueList: View {
    let issues: [CompatibilityIssue]

    /// Empty slots are already obvious from the slot list above.
    /// Repeating them here would bury the problems that need explaining.
    private var realProblems: [CompatibilityIssue] {
        issues.filter {
            if case .missingPart = $0 { return false }
            return true
        }
    }

    var body: some View {
        if !realProblems.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(realProblems.enumerated()), id: \.offset) { _, issue in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.fault)
                        Text(issue.message)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.fault.opacity(0.12)))
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Deliver

private struct DeliverBar: View {
    let enabled: Bool
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.spec(15, .semibold))
                .foregroundStyle(enabled ? Theme.ink : Theme.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(enabled ? Theme.gold : Theme.raised)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Result

private struct DeliveryResult: View {
    let outcome: FulfillmentResult
    let done: () -> Void

    private var mood: (symbol: String, tint: Color, word: String) {
        switch outcome.satisfaction {
        case 80...:   return ("hand.thumbsup.fill", Theme.solder, "Delighted")
        case 40..<80: return ("hand.raised.fill", Theme.gold, "Satisfied")
        default:      return ("hand.thumbsdown.fill", Theme.fault, "Disappointed")
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            Capsule().fill(Theme.line).frame(width: 36, height: 4).padding(.top, 10)

            Image(systemName: mood.symbol)
                .font(.system(size: 32))
                .foregroundStyle(mood.tint)
                .padding(.top, 6)

            Text("\(outcome.customerName) — \(mood.word)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.text)

            if outcome.wasRepair {
                Text("Machine repaired and handed back.")
                    .font(.spec(11))
                    .foregroundStyle(Theme.muted)
            }

            HStack(spacing: 0) {
                figure("SATISFACTION", "\(outcome.satisfaction)%", mood.tint)
                Rectangle().fill(Theme.line).frame(width: 1, height: 34)
                figure("PROFIT",
                       (outcome.profit >= 0 ? "+" : "") + outcome.profit.money,
                       outcome.profit >= 0 ? Theme.solder : Theme.fault)
                Rectangle().fill(Theme.line).frame(width: 1, height: 34)
                figure("REPUTATION",
                       (outcome.reputationChange > 0 ? "+" : "")
                         + "\(outcome.reputationChange)",
                       outcome.reputationChange > 0 ? Theme.solder
                         : outcome.reputationChange < 0 ? Theme.fault : Theme.muted)
            }
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
            .padding(.horizontal, 18)

            if outcome.scrap > 0 {
                Text("\(outcome.scrap.money) scrap credit for the dead parts.")
                    .font(.spec(10))
                    .foregroundStyle(Theme.muted)
            }

            if let level = outcome.newLevel {
                VStack(spacing: 4) {
                    Text("LEVEL \(level)")
                        .font(.spec(13, .bold)).tracking(1.4)
                        .foregroundStyle(Theme.gold)
                    Text(unlockLine(level))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.gold.opacity(0.12)))
                .padding(.horizontal, 18)
            }

            Spacer(minLength: 0)

            Button(action: done) {
                Text("Back to the shop")
                    .font(.spec(14, .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.gold))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.ink)
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled()
    }

    private func unlockLine(_ level: Int) -> String {
        let arrivals = PartCatalog.newlyUnlocked(at: level)
        guard !arrivals.isEmpty else { return "Word is getting around." }
        let names = arrivals.prefix(2).map(\.name).joined(separator: ", ")
        let extra = arrivals.count > 2 ? " and \(arrivals.count - 2) more" : ""
        return "The supplier now carries \(names)\(extra)."
    }

    private func figure(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.spec(8, .semibold)).tracking(1).foregroundStyle(Theme.muted)
            Text(value).font(.spec(16, .semibold)).foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
    }
}
