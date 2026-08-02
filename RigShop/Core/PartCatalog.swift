//
//  PartCatalog.swift
//  RigShop
//
//  The master parts list. Everything the supplier can ever offer.
//
//  Sockets and memory-type support are real specs — they drive
//  compatibility, so they have to be correct.
//  Power figures are real *peak* draw, not nominal TDP.
//  Prices and scores are balance values, not market quotes.
//
//  Do NOT import SwiftUI in this file.
//

import Foundation

/// Namespace only — `enum` with no cases can never be instantiated.
enum PartCatalog {

    // MARK: - CPUs

    static let cpus: [Part] = [
        Part(id: "cpu-i3-12100f", name: "Intel Core i3-12100F", basePrice: 90,
             spec: .cpu(socket: .lga1700, powerDraw: 89, score: 32)),
        Part(id: "cpu-i5-12400f", name: "Intel Core i5-12400F", basePrice: 115,
             spec: .cpu(socket: .lga1700, powerDraw: 117, score: 42)),
        Part(id: "cpu-i5-13400f", name: "Intel Core i5-13400F", basePrice: 180,
             spec: .cpu(socket: .lga1700, powerDraw: 148, score: 52)),
        Part(id: "cpu-i5-14600kf", name: "Intel Core i5-14600KF", basePrice: 250,
             spec: .cpu(socket: .lga1700, powerDraw: 181, score: 68)),
        Part(id: "cpu-i7-13700kf", name: "Intel Core i7-13700KF", basePrice: 350,
             spec: .cpu(socket: .lga1700, powerDraw: 253, score: 78)),
        Part(id: "cpu-i9-14900k", name: "Intel Core i9-14900K", basePrice: 530,
             spec: .cpu(socket: .lga1700, powerDraw: 253, score: 92)),

        Part(id: "cpu-r5-5600", name: "AMD Ryzen 5 5600", basePrice: 110,
             spec: .cpu(socket: .am4, powerDraw: 88, score: 40)),
        Part(id: "cpu-r5-5600x", name: "AMD Ryzen 5 5600X", basePrice: 135,
             spec: .cpu(socket: .am4, powerDraw: 88, score: 43)),
        Part(id: "cpu-r7-5700x", name: "AMD Ryzen 7 5700X", basePrice: 165,
             spec: .cpu(socket: .am4, powerDraw: 88, score: 50)),
        Part(id: "cpu-r7-5800x3d", name: "AMD Ryzen 7 5800X3D", basePrice: 300,
             spec: .cpu(socket: .am4, powerDraw: 142, score: 62)),

        Part(id: "cpu-r5-7600", name: "AMD Ryzen 5 7600", basePrice: 190,
             spec: .cpu(socket: .am5, powerDraw: 88, score: 58)),
        Part(id: "cpu-r7-7700x", name: "AMD Ryzen 7 7700X", basePrice: 280,
             spec: .cpu(socket: .am5, powerDraw: 142, score: 70)),
        Part(id: "cpu-r7-7800x3d", name: "AMD Ryzen 7 7800X3D", basePrice: 350,
             spec: .cpu(socket: .am5, powerDraw: 162, score: 80)),
        Part(id: "cpu-r9-7950x", name: "AMD Ryzen 9 7950X", basePrice: 550,
             spec: .cpu(socket: .am5, powerDraw: 230, score: 95)),
    ]

    // MARK: - Motherboards
    //
    // Note the LGA1700 split: some boards take DDR4, some take DDR5.
    // Same CPU, different board, and the memory no longer fits.
    // AM4 is DDR4 only. AM5 is DDR5 only. No exceptions.

    static let motherboards: [Part] = [
        Part(id: "mb-b660m-hdv", name: "ASRock B660M-HDV", basePrice: 90,
             spec: .motherboard(socket: .lga1700, memoryTypes: [.ddr4])),
        Part(id: "mb-b760m-p-ddr4", name: "MSI PRO B760M-P DDR4", basePrice: 120,
             spec: .motherboard(socket: .lga1700, memoryTypes: [.ddr4])),
        Part(id: "mb-b760m-a-wifi", name: "MSI PRO B760M-A WIFI", basePrice: 150,
             spec: .motherboard(socket: .lga1700, memoryTypes: [.ddr5])),
        Part(id: "mb-z790-plus", name: "ASUS TUF GAMING Z790-PLUS WIFI", basePrice: 240,
             spec: .motherboard(socket: .lga1700, memoryTypes: [.ddr5])),

        Part(id: "mb-b550a-pro", name: "MSI B550-A PRO", basePrice: 110,
             spec: .motherboard(socket: .am4, memoryTypes: [.ddr4])),
        Part(id: "mb-b550f", name: "ASUS ROG STRIX B550-F GAMING", basePrice: 170,
             spec: .motherboard(socket: .am4, memoryTypes: [.ddr4])),

        Part(id: "mb-b650p-wifi", name: "MSI PRO B650-P WIFI", basePrice: 180,
             spec: .motherboard(socket: .am5, memoryTypes: [.ddr5])),
        Part(id: "mb-x670e-e", name: "ASUS ROG STRIX X670E-E GAMING", basePrice: 400,
             spec: .motherboard(socket: .am5, memoryTypes: [.ddr5])),
    ]

    // MARK: - Memory

    static let memories: [Part] = [
        Part(id: "ram-lpx-16-ddr4", name: "Corsair Vengeance LPX 16GB DDR4-3200", basePrice: 38,
             spec: .memory(type: .ddr4, capacityGB: 16)),
        Part(id: "ram-ripjaws-32-ddr4", name: "G.SKILL Ripjaws V 32GB DDR4-3600", basePrice: 65,
             spec: .memory(type: .ddr4, capacityGB: 32)),
        Part(id: "ram-veng-16-ddr5", name: "Corsair Vengeance 16GB DDR5-5600", basePrice: 52,
             spec: .memory(type: .ddr5, capacityGB: 16)),
        Part(id: "ram-tridentz5-32-ddr5", name: "G.SKILL Trident Z5 RGB 32GB DDR5-6000", basePrice: 115,
             spec: .memory(type: .ddr5, capacityGB: 32)),
        Part(id: "ram-fury-64-ddr5", name: "Kingston FURY Beast 64GB DDR5-5600", basePrice: 200,
             spec: .memory(type: .ddr5, capacityGB: 64)),
    ]

    // MARK: - GPUs

    static let gpus: [Part] = [
        Part(id: "gpu-gtx1650", name: "NVIDIA GeForce GTX 1650", basePrice: 150,
             spec: .gpu(powerDraw: 75, score: 18)),
        Part(id: "gpu-rtx3050", name: "NVIDIA GeForce RTX 3050", basePrice: 200,
             spec: .gpu(powerDraw: 130, score: 30)),
        Part(id: "gpu-rx6600", name: "AMD Radeon RX 6600", basePrice: 190,
             spec: .gpu(powerDraw: 132, score: 35)),
        Part(id: "gpu-rx7600", name: "AMD Radeon RX 7600", basePrice: 250,
             spec: .gpu(powerDraw: 165, score: 42)),
        Part(id: "gpu-rtx4060", name: "NVIDIA GeForce RTX 4060", basePrice: 300,
             spec: .gpu(powerDraw: 115, score: 45)),
        Part(id: "gpu-rtx4060ti", name: "NVIDIA GeForce RTX 4060 Ti", basePrice: 400,
             spec: .gpu(powerDraw: 160, score: 55)),
        Part(id: "gpu-rtx4070", name: "NVIDIA GeForce RTX 4070", basePrice: 550,
             spec: .gpu(powerDraw: 200, score: 68)),
        Part(id: "gpu-rx7800xt", name: "AMD Radeon RX 7800 XT", basePrice: 500,
             spec: .gpu(powerDraw: 263, score: 72)),
        Part(id: "gpu-rtx4070tis", name: "NVIDIA GeForce RTX 4070 Ti SUPER", basePrice: 800,
             spec: .gpu(powerDraw: 285, score: 85)),
        Part(id: "gpu-rtx4080s", name: "NVIDIA GeForce RTX 4080 SUPER", basePrice: 1000,
             spec: .gpu(powerDraw: 320, score: 95)),
    ]

    // MARK: - Power supplies

    static let psus: [Part] = [
        Part(id: "psu-evga-500", name: "EVGA 500 W1", basePrice: 45,
             spec: .psu(watts: 500)),
        Part(id: "psu-cx650m", name: "Corsair CX650M", basePrice: 75,
             spec: .psu(watts: 650)),
        Part(id: "psu-focus-750", name: "Seasonic FOCUS GX-750", basePrice: 115,
             spec: .psu(watts: 750)),
        Part(id: "psu-rm850x", name: "Corsair RM850x", basePrice: 145,
             spec: .psu(watts: 850)),
        Part(id: "psu-hx1000", name: "Corsair HX1000", basePrice: 200,
             spec: .psu(watts: 1000)),
    ]

    // MARK: - Lookup

    static let all: [Part] = cpus + motherboards + memories + gpus + psus

    static func parts(in category: PartCategory) -> [Part] {
        all.filter { $0.category == category }
    }

    static func part(id: String) -> Part? {
        all.first { $0.id == id }
    }
}
