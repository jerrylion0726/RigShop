//
//  PartCatalog.swift
//  RigShop
//
//  The master parts list. Everything the supplier could ever carry —
//  but only the parts at or below the shop's current level actually
//  show up on the shelf.
//
//  Sockets and memory-type support are real specs — they drive
//  compatibility, so they have to be correct.
//  Power figures are real *peak* draw, not nominal TDP.
//  Prices, scores and unlock levels are balance values.
//
//  Scoring covers all five categories:
//    CPU / GPU   raw compute, the two biggest levers
//    Memory      capacity first, generation second — 8GB hurts today
//    Motherboard chipset tier: power delivery, connectivity, headroom
//    PSU         wattage and build quality
//
//  Unlock ladder, roughly:
//    1–2   entry parts, the shop you start with
//    3–5   the mid range where most builds live
//    6–8   halo parts of the current generation
//    9–10  next generation: RTX 50, RX 9000, and Core Ultra, which
//          brings the LGA1851 socket with it — a whole new platform
//          rather than just a faster card.
//
//  Do NOT import SwiftUI in this file.
//

import Foundation

/// Namespace only — `enum` with no cases can never be instantiated.
enum PartCatalog {

    // MARK: - CPUs

    static let cpus: [Part] = [
        // ── Intel LGA1700 ──────────────────────────────────────────
        Part(id: "cpu-i3-12100f", name: "Intel Core i3-12100F", basePrice: 90, unlockLevel: 1,
             score: 32, spec: .cpu(socket: .lga1700, powerDraw: 89)),
        Part(id: "cpu-i5-12400f", name: "Intel Core i5-12400F", basePrice: 115, unlockLevel: 1,
             score: 42, spec: .cpu(socket: .lga1700, powerDraw: 117)),
        Part(id: "cpu-i3-13100f", name: "Intel Core i3-13100F", basePrice: 110, unlockLevel: 2,
             score: 36, spec: .cpu(socket: .lga1700, powerDraw: 89)),
        Part(id: "cpu-i5-13400f", name: "Intel Core i5-13400F", basePrice: 180, unlockLevel: 3,
             score: 52, spec: .cpu(socket: .lga1700, powerDraw: 148)),
        Part(id: "cpu-i5-12600k", name: "Intel Core i5-12600K", basePrice: 200, unlockLevel: 3,
             score: 56, spec: .cpu(socket: .lga1700, powerDraw: 150)),
        Part(id: "cpu-i7-12700f", name: "Intel Core i7-12700F", basePrice: 260, unlockLevel: 4,
             score: 65, spec: .cpu(socket: .lga1700, powerDraw: 180)),
        Part(id: "cpu-i5-13600kf", name: "Intel Core i5-13600KF", basePrice: 230, unlockLevel: 4,
             score: 66, spec: .cpu(socket: .lga1700, powerDraw: 181)),
        Part(id: "cpu-i5-14600kf", name: "Intel Core i5-14600KF", basePrice: 250, unlockLevel: 5,
             score: 68, spec: .cpu(socket: .lga1700, powerDraw: 181)),
        Part(id: "cpu-i7-13700kf", name: "Intel Core i7-13700KF", basePrice: 350, unlockLevel: 6,
             score: 78, spec: .cpu(socket: .lga1700, powerDraw: 253)),
        Part(id: "cpu-i7-14700k", name: "Intel Core i7-14700K", basePrice: 390, unlockLevel: 7,
             score: 84, spec: .cpu(socket: .lga1700, powerDraw: 253)),
        Part(id: "cpu-i9-13900k", name: "Intel Core i9-13900K", basePrice: 450, unlockLevel: 8,
             score: 90, spec: .cpu(socket: .lga1700, powerDraw: 253)),
        Part(id: "cpu-i9-14900k", name: "Intel Core i9-14900K", basePrice: 530, unlockLevel: 8,
             score: 92, spec: .cpu(socket: .lga1700, powerDraw: 253)),

        // ── Intel LGA1851 (Core Ultra) ─────────────────────────────
        Part(id: "cpu-ultra5-245k", name: "Intel Core Ultra 5 245K", basePrice: 310, unlockLevel: 9,
             score: 72, spec: .cpu(socket: .lga1851, powerDraw: 159)),
        Part(id: "cpu-ultra7-265k", name: "Intel Core Ultra 7 265K", basePrice: 420, unlockLevel: 9,
             score: 86, spec: .cpu(socket: .lga1851, powerDraw: 250)),
        Part(id: "cpu-ultra9-285k", name: "Intel Core Ultra 9 285K", basePrice: 620, unlockLevel: 10,
             score: 100, spec: .cpu(socket: .lga1851, powerDraw: 250)),

        // ── AMD AM4 ────────────────────────────────────────────────
        Part(id: "cpu-r5-4500", name: "AMD Ryzen 5 4500", basePrice: 75, unlockLevel: 1,
             score: 30, spec: .cpu(socket: .am4, powerDraw: 88)),
        Part(id: "cpu-r5-5500", name: "AMD Ryzen 5 5500", basePrice: 85, unlockLevel: 1,
             score: 36, spec: .cpu(socket: .am4, powerDraw: 88)),
        Part(id: "cpu-r5-5600", name: "AMD Ryzen 5 5600", basePrice: 110, unlockLevel: 1,
             score: 40, spec: .cpu(socket: .am4, powerDraw: 88)),
        Part(id: "cpu-r5-5600x", name: "AMD Ryzen 5 5600X", basePrice: 135, unlockLevel: 2,
             score: 43, spec: .cpu(socket: .am4, powerDraw: 88)),
        Part(id: "cpu-r7-5700x", name: "AMD Ryzen 7 5700X", basePrice: 165, unlockLevel: 2,
             score: 50, spec: .cpu(socket: .am4, powerDraw: 88)),
        Part(id: "cpu-r7-5800x", name: "AMD Ryzen 7 5800X", basePrice: 200, unlockLevel: 3,
             score: 55, spec: .cpu(socket: .am4, powerDraw: 142)),
        Part(id: "cpu-r7-5800x3d", name: "AMD Ryzen 7 5800X3D", basePrice: 300, unlockLevel: 4,
             score: 62, spec: .cpu(socket: .am4, powerDraw: 142)),
        Part(id: "cpu-r9-5900x", name: "AMD Ryzen 9 5900X", basePrice: 290, unlockLevel: 4,
             score: 68, spec: .cpu(socket: .am4, powerDraw: 142)),

        // ── AMD AM5 ────────────────────────────────────────────────
        Part(id: "cpu-r5-7600", name: "AMD Ryzen 5 7600", basePrice: 190, unlockLevel: 5,
             score: 58, spec: .cpu(socket: .am5, powerDraw: 88)),
        Part(id: "cpu-r5-7600x", name: "AMD Ryzen 5 7600X", basePrice: 210, unlockLevel: 5,
             score: 61, spec: .cpu(socket: .am5, powerDraw: 142)),
        Part(id: "cpu-r7-7700x", name: "AMD Ryzen 7 7700X", basePrice: 280, unlockLevel: 6,
             score: 70, spec: .cpu(socket: .am5, powerDraw: 142)),
        Part(id: "cpu-r7-7800x3d", name: "AMD Ryzen 7 7800X3D", basePrice: 350, unlockLevel: 7,
             score: 80, spec: .cpu(socket: .am5, powerDraw: 162)),
        Part(id: "cpu-r9-7900x", name: "AMD Ryzen 9 7900X", basePrice: 400, unlockLevel: 7,
             score: 85, spec: .cpu(socket: .am5, powerDraw: 230)),
        Part(id: "cpu-r9-7950x", name: "AMD Ryzen 9 7950X", basePrice: 550, unlockLevel: 8,
             score: 95, spec: .cpu(socket: .am5, powerDraw: 230)),
        Part(id: "cpu-r7-9700x", name: "AMD Ryzen 7 9700X", basePrice: 330, unlockLevel: 9,
             score: 76, spec: .cpu(socket: .am5, powerDraw: 88)),
        Part(id: "cpu-r9-9900x", name: "AMD Ryzen 9 9900X", basePrice: 480, unlockLevel: 9,
             score: 90, spec: .cpu(socket: .am5, powerDraw: 162)),
        Part(id: "cpu-r7-9800x3d", name: "AMD Ryzen 7 9800X3D", basePrice: 480, unlockLevel: 10,
             score: 94, spec: .cpu(socket: .am5, powerDraw: 162)),
        Part(id: "cpu-r9-9950x", name: "AMD Ryzen 9 9950X", basePrice: 680, unlockLevel: 10,
             score: 105, spec: .cpu(socket: .am5, powerDraw: 230)),
    ]

    // MARK: - Motherboards
    //
    // Scored by chipset tier: power delivery, connectivity and headroom.
    // A budget board throttles a big processor and gives you nowhere to
    // grow, which is exactly what the score is saying.
    //
    // The LGA1700 split is the trap worth learning: some boards take
    // DDR4, some take DDR5, same CPU either way.
    // AM4 is DDR4 only. AM5 and LGA1851 are DDR5 only. No exceptions.

    static let motherboards: [Part] = [
        // ── LGA1700 · DDR4 ─────────────────────────────────────────
        Part(id: "mb-b660m-hdv", name: "ASRock B660M-HDV", basePrice: 90, unlockLevel: 1,
             score: 25, spec: .motherboard(socket: .lga1700, memoryTypes: [.ddr4])),
        Part(id: "mb-b760m-p-ddr4", name: "MSI PRO B760M-P DDR4", basePrice: 120, unlockLevel: 1,
             score: 35, spec: .motherboard(socket: .lga1700, memoryTypes: [.ddr4])),
        Part(id: "mb-b760-gaming-x-ddr4", name: "Gigabyte B760 GAMING X DDR4", basePrice: 150, unlockLevel: 3,
             score: 45, spec: .motherboard(socket: .lga1700, memoryTypes: [.ddr4])),

        // ── LGA1700 · DDR5 ─────────────────────────────────────────
        Part(id: "mb-b760m-a-wifi", name: "MSI PRO B760M-A WIFI", basePrice: 150, unlockLevel: 3,
             score: 46, spec: .motherboard(socket: .lga1700, memoryTypes: [.ddr5])),
        Part(id: "mb-b760-aorus-elite", name: "Gigabyte B760 AORUS ELITE AX", basePrice: 190, unlockLevel: 4,
             score: 58, spec: .motherboard(socket: .lga1700, memoryTypes: [.ddr5])),
        Part(id: "mb-z790-plus", name: "ASUS TUF GAMING Z790-PLUS WIFI", basePrice: 240, unlockLevel: 6,
             score: 72, spec: .motherboard(socket: .lga1700, memoryTypes: [.ddr5])),
        Part(id: "mb-z790-carbon", name: "MSI MPG Z790 CARBON WIFI", basePrice: 400, unlockLevel: 8,
             score: 88, spec: .motherboard(socket: .lga1700, memoryTypes: [.ddr5])),

        // ── LGA1851 · DDR5 ─────────────────────────────────────────
        Part(id: "mb-b860m-pro", name: "MSI PRO B860M-A WIFI", basePrice: 200, unlockLevel: 9,
             score: 62, spec: .motherboard(socket: .lga1851, memoryTypes: [.ddr5])),
        Part(id: "mb-z890-plus", name: "ASUS TUF GAMING Z890-PLUS WIFI", basePrice: 330, unlockLevel: 9,
             score: 82, spec: .motherboard(socket: .lga1851, memoryTypes: [.ddr5])),
        Part(id: "mb-z890-carbon", name: "MSI MPG Z890 CARBON WIFI", basePrice: 480, unlockLevel: 10,
             score: 95, spec: .motherboard(socket: .lga1851, memoryTypes: [.ddr5])),

        // ── AM4 · DDR4 ─────────────────────────────────────────────
        Part(id: "mb-b450m-pro4", name: "ASRock B450M PRO4", basePrice: 75, unlockLevel: 1,
             score: 20, spec: .motherboard(socket: .am4, memoryTypes: [.ddr4])),
        Part(id: "mb-b550a-pro", name: "MSI B550-A PRO", basePrice: 110, unlockLevel: 1,
             score: 34, spec: .motherboard(socket: .am4, memoryTypes: [.ddr4])),
        Part(id: "mb-b550-aorus-elite", name: "Gigabyte B550 AORUS ELITE AX V2", basePrice: 150, unlockLevel: 3,
             score: 46, spec: .motherboard(socket: .am4, memoryTypes: [.ddr4])),
        Part(id: "mb-b550f", name: "ASUS ROG STRIX B550-F GAMING", basePrice: 170, unlockLevel: 4,
             score: 52, spec: .motherboard(socket: .am4, memoryTypes: [.ddr4])),
        Part(id: "mb-x570e", name: "ASUS ROG STRIX X570-E GAMING", basePrice: 270, unlockLevel: 5,
             score: 68, spec: .motherboard(socket: .am4, memoryTypes: [.ddr4])),

        // ── AM5 · DDR5 ─────────────────────────────────────────────
        Part(id: "mb-b650m-hdv", name: "ASRock B650M-HDV/M.2", basePrice: 130, unlockLevel: 5,
             score: 42, spec: .motherboard(socket: .am5, memoryTypes: [.ddr5])),
        Part(id: "mb-b650p-wifi", name: "MSI PRO B650-P WIFI", basePrice: 180, unlockLevel: 6,
             score: 55, spec: .motherboard(socket: .am5, memoryTypes: [.ddr5])),
        Part(id: "mb-b650-plus-wifi", name: "ASUS TUF GAMING B650-PLUS WIFI", basePrice: 210, unlockLevel: 7,
             score: 62, spec: .motherboard(socket: .am5, memoryTypes: [.ddr5])),
        Part(id: "mb-x670e-e", name: "ASUS ROG STRIX X670E-E GAMING", basePrice: 400, unlockLevel: 8,
             score: 85, spec: .motherboard(socket: .am5, memoryTypes: [.ddr5])),
        Part(id: "mb-x870e-hero", name: "ASUS ROG CROSSHAIR X870E HERO", basePrice: 620, unlockLevel: 10,
             score: 100, spec: .motherboard(socket: .am5, memoryTypes: [.ddr5])),
    ]

    // MARK: - Memory
    //
    // Capacity first, generation second. 8GB is genuinely painful now,
    // and this is where a machine most often falls down — a fast card
    // in front of starved memory still stutters.

    static let memories: [Part] = [
        // DDR4
        Part(id: "ram-crucial-8-ddr4", name: "Crucial 8GB DDR4-3200", basePrice: 22, unlockLevel: 1,
             score: 15, spec: .memory(type: .ddr4, capacityGB: 8)),
        Part(id: "ram-lpx-16-ddr4", name: "Corsair Vengeance LPX 16GB DDR4-3200", basePrice: 38, unlockLevel: 1,
             score: 40, spec: .memory(type: .ddr4, capacityGB: 16)),
        Part(id: "ram-tforce-16-ddr4", name: "TEAMGROUP T-Force 16GB DDR4-3600", basePrice: 45, unlockLevel: 2,
             score: 46, spec: .memory(type: .ddr4, capacityGB: 16)),
        Part(id: "ram-ripjaws-32-ddr4", name: "G.SKILL Ripjaws V 32GB DDR4-3600", basePrice: 65, unlockLevel: 3,
             score: 62, spec: .memory(type: .ddr4, capacityGB: 32)),
        Part(id: "ram-lpx-64-ddr4", name: "Corsair Vengeance LPX 64GB DDR4-3200", basePrice: 120, unlockLevel: 5,
             score: 74, spec: .memory(type: .ddr4, capacityGB: 64)),

        // DDR5
        Part(id: "ram-crucial-16-ddr5", name: "Crucial 16GB DDR5-4800", basePrice: 42, unlockLevel: 3,
             score: 52, spec: .memory(type: .ddr5, capacityGB: 16)),
        Part(id: "ram-veng-16-ddr5", name: "Corsair Vengeance 16GB DDR5-5600", basePrice: 52, unlockLevel: 4,
             score: 58, spec: .memory(type: .ddr5, capacityGB: 16)),
        Part(id: "ram-tridentz5-32-ddr5", name: "G.SKILL Trident Z5 RGB 32GB DDR5-6000", basePrice: 115, unlockLevel: 6,
             score: 78, spec: .memory(type: .ddr5, capacityGB: 32)),
        Part(id: "ram-fury-64-ddr5", name: "Kingston FURY Beast 64GB DDR5-5600", basePrice: 200, unlockLevel: 8,
             score: 92, spec: .memory(type: .ddr5, capacityGB: 64)),
        Part(id: "ram-tridentz5-32-8000", name: "G.SKILL Trident Z5 RGB 32GB DDR5-8000", basePrice: 260, unlockLevel: 9,
             score: 88, spec: .memory(type: .ddr5, capacityGB: 32)),
        Part(id: "ram-fury-96-ddr5", name: "Kingston FURY Renegade 96GB DDR5-6400", basePrice: 380, unlockLevel: 10,
             score: 105, spec: .memory(type: .ddr5, capacityGB: 96)),
    ]

    // MARK: - GPUs

    static let gpus: [Part] = [
        Part(id: "gpu-gtx1630", name: "NVIDIA GeForce GTX 1630", basePrice: 110, unlockLevel: 1,
             score: 12, spec: .gpu(powerDraw: 75)),
        Part(id: "gpu-gtx1650", name: "NVIDIA GeForce GTX 1650", basePrice: 150, unlockLevel: 1,
             score: 18, spec: .gpu(powerDraw: 75)),
        Part(id: "gpu-gtx1660s", name: "NVIDIA GeForce GTX 1660 SUPER", basePrice: 180, unlockLevel: 2,
             score: 26, spec: .gpu(powerDraw: 125)),
        Part(id: "gpu-rx6600", name: "AMD Radeon RX 6600", basePrice: 190, unlockLevel: 2,
             score: 35, spec: .gpu(powerDraw: 132)),
        Part(id: "gpu-rtx3050", name: "NVIDIA GeForce RTX 3050", basePrice: 200, unlockLevel: 3,
             score: 30, spec: .gpu(powerDraw: 130)),
        Part(id: "gpu-rx6650xt", name: "AMD Radeon RX 6650 XT", basePrice: 230, unlockLevel: 3,
             score: 39, spec: .gpu(powerDraw: 180)),
        Part(id: "gpu-rtx3060", name: "NVIDIA GeForce RTX 3060", basePrice: 250, unlockLevel: 3,
             score: 38, spec: .gpu(powerDraw: 170)),
        Part(id: "gpu-rx7600", name: "AMD Radeon RX 7600", basePrice: 250, unlockLevel: 4,
             score: 42, spec: .gpu(powerDraw: 165)),
        Part(id: "gpu-rtx4060", name: "NVIDIA GeForce RTX 4060", basePrice: 300, unlockLevel: 4,
             score: 45, spec: .gpu(powerDraw: 115)),
        Part(id: "gpu-rtx3060ti", name: "NVIDIA GeForce RTX 3060 Ti", basePrice: 320, unlockLevel: 5,
             score: 48, spec: .gpu(powerDraw: 200)),
        Part(id: "gpu-rtx4060ti", name: "NVIDIA GeForce RTX 4060 Ti", basePrice: 400, unlockLevel: 5,
             score: 55, spec: .gpu(powerDraw: 160)),
        Part(id: "gpu-rx7700xt", name: "AMD Radeon RX 7700 XT", basePrice: 420, unlockLevel: 6,
             score: 58, spec: .gpu(powerDraw: 245)),
        Part(id: "gpu-rtx4070", name: "NVIDIA GeForce RTX 4070", basePrice: 550, unlockLevel: 6,
             score: 68, spec: .gpu(powerDraw: 200)),
        Part(id: "gpu-rx7800xt", name: "AMD Radeon RX 7800 XT", basePrice: 500, unlockLevel: 7,
             score: 72, spec: .gpu(powerDraw: 263)),
        Part(id: "gpu-rtx4070tis", name: "NVIDIA GeForce RTX 4070 Ti SUPER", basePrice: 800, unlockLevel: 8,
             score: 85, spec: .gpu(powerDraw: 285)),
        Part(id: "gpu-rx7900xtx", name: "AMD Radeon RX 7900 XTX", basePrice: 950, unlockLevel: 8,
             score: 92, spec: .gpu(powerDraw: 355)),
        Part(id: "gpu-rtx4080s", name: "NVIDIA GeForce RTX 4080 SUPER", basePrice: 1000, unlockLevel: 8,
             score: 95, spec: .gpu(powerDraw: 320)),

        // ── Next generation ────────────────────────────────────────
        Part(id: "gpu-rtx5060", name: "NVIDIA GeForce RTX 5060", basePrice: 300, unlockLevel: 9,
             score: 52, spec: .gpu(powerDraw: 145)),
        Part(id: "gpu-rtx5060ti", name: "NVIDIA GeForce RTX 5060 Ti", basePrice: 430, unlockLevel: 9,
             score: 62, spec: .gpu(powerDraw: 180)),
        Part(id: "gpu-rtx5070", name: "NVIDIA GeForce RTX 5070", basePrice: 560, unlockLevel: 9,
             score: 75, spec: .gpu(powerDraw: 250)),
        Part(id: "gpu-rx9070", name: "AMD Radeon RX 9070", basePrice: 560, unlockLevel: 9,
             score: 78, spec: .gpu(powerDraw: 220)),
        Part(id: "gpu-rx9070xt", name: "AMD Radeon RX 9070 XT", basePrice: 620, unlockLevel: 10,
             score: 84, spec: .gpu(powerDraw: 304)),
        Part(id: "gpu-rtx5070ti", name: "NVIDIA GeForce RTX 5070 Ti", basePrice: 760, unlockLevel: 10,
             score: 88, spec: .gpu(powerDraw: 300)),
        Part(id: "gpu-rtx5080", name: "NVIDIA GeForce RTX 5080", basePrice: 1020, unlockLevel: 10,
             score: 105, spec: .gpu(powerDraw: 360)),
        Part(id: "gpu-rtx5090", name: "NVIDIA GeForce RTX 5090", basePrice: 2050, unlockLevel: 10,
             score: 140, spec: .gpu(powerDraw: 575)),
    ]

    // MARK: - Power supplies
    //
    // Wattage and build quality. A cheap unit runs a machine but runs it
    // hot and loud, and gives you no room to upgrade later.

    static let psus: [Part] = [
        Part(id: "psu-evga-500", name: "EVGA 500 W1", basePrice: 45, unlockLevel: 1,
             score: 18, spec: .psu(watts: 500)),
        Part(id: "psu-cv550", name: "Corsair CV550", basePrice: 55, unlockLevel: 1,
             score: 26, spec: .psu(watts: 550)),
        Part(id: "psu-tt-smart-600", name: "Thermaltake Smart 600W", basePrice: 60, unlockLevel: 2,
             score: 30, spec: .psu(watts: 600)),
        Part(id: "psu-cx650m", name: "Corsair CX650M", basePrice: 75, unlockLevel: 2,
             score: 40, spec: .psu(watts: 650)),
        Part(id: "psu-mag-a750bn", name: "MSI MAG A750BN", basePrice: 90, unlockLevel: 3,
             score: 48, spec: .psu(watts: 750)),
        Part(id: "psu-focus-750", name: "Seasonic FOCUS GX-750", basePrice: 115, unlockLevel: 4,
             score: 62, spec: .psu(watts: 750)),
        Part(id: "psu-rm850x", name: "Corsair RM850x", basePrice: 145, unlockLevel: 5,
             score: 74, spec: .psu(watts: 850)),
        Part(id: "psu-focus-1000", name: "Seasonic FOCUS GX-1000", basePrice: 180, unlockLevel: 7,
             score: 84, spec: .psu(watts: 1000)),
        Part(id: "psu-hx1000", name: "Corsair HX1000", basePrice: 200, unlockLevel: 8,
             score: 90, spec: .psu(watts: 1000)),
        Part(id: "psu-rm1200x", name: "Corsair RM1200x SHIFT", basePrice: 270, unlockLevel: 9,
             score: 96, spec: .psu(watts: 1200)),
        Part(id: "psu-ax1600i", name: "Corsair AX1600i", basePrice: 500, unlockLevel: 10,
             score: 110, spec: .psu(watts: 1600)),
    ]

    // MARK: - Lookup

    static let all: [Part] = cpus + motherboards + memories + gpus + psus

    /// Highest unlock level in the catalog. The ladder ends here.
    static let maxUnlockLevel: Int = all.map(\.unlockLevel).max() ?? 1

    static func parts(in category: PartCategory) -> [Part] {
        all.filter { $0.category == category }
    }

    static func part(id: String) -> Part? {
        all.first { $0.id == id }
    }

    // MARK: Level-aware lookup

    /// Everything the supplier will carry at this shop level.
    static func unlocked(at level: Int) -> [Part] {
        all.filter { $0.unlockLevel <= level }
    }

    static func parts(in category: PartCategory, unlockedAt level: Int) -> [Part] {
        all.filter { $0.category == category && $0.unlockLevel <= level }
    }

    /// Parts that become available on arriving at this exact level.
    /// Used for the "new stock in" announcement.
    static func newlyUnlocked(at level: Int) -> [Part] {
        all.filter { $0.unlockLevel == level }
    }
}
