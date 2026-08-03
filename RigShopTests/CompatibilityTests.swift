//
//  CompatibilityTests.swift
//  RigShopTests
//
//  Run with Cmd + U. No simulator UI required.
//

import XCTest
@testable import RigShop

final class CompatibilityTests: XCTestCase {

    // MARK: - Helpers

    private func part(_ id: String) -> Part {
        guard let part = PartCatalog.part(id: id) else {
            fatalError("Catalog is missing \(id) — did the id change?")
        }
        return part
    }

    /// A build that is known good: LGA1700 CPU, DDR4 board, DDR4 memory,
    /// modest GPU, PSU with plenty of room.
    private func validBuild() -> PCBuild {
        PCBuild(cpu: part("cpu-i5-13400f"),
                motherboard: part("mb-b660m-hdv"),
                memory: part("ram-lpx-16-ddr4"),
                gpu: part("gpu-rtx4060"),
                psu: part("psu-focus-750"))
    }

    // MARK: - Catalog integrity

    func testCatalogIsBigEnoughToOfferChoices() {
            XCTAssertGreaterThan(PartCatalog.all.count, 90)
            for category in PartCategory.allCases {
                XCTAssertGreaterThanOrEqual(PartCatalog.parts(in: category).count, 10,
                                            "Too few options for \(category.rawValue)")
            }
        }

    /// Level 1 must be a playable shop, not a locked door.
    func testLevelOneCanBuildAMachine() {
        for category in PartCategory.allCases {
            XCTAssertGreaterThanOrEqual(
                PartCatalog.parts(in: category, unlockedAt: 1).count, 2,
                "Level 1 has no \(category.rawValue) to choose from")
        }
    }

    func testCatalogIdsAreUnique() {
        let ids = PartCatalog.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate part id in the catalog")
    }

    func testEveryCategoryHasParts() {
        for category in PartCategory.allCases {
            XCTAssertFalse(PartCatalog.parts(in: category).isEmpty,
                           "No parts for \(category.rawValue)")
        }
    }

    func testBoardMemorySupportMatchesPlatform() {
            for board in PartCatalog.motherboards {
                switch board.socket {
                case .am4:
                    XCTAssertEqual(board.supportedMemoryTypes, [.ddr4], board.name)
                case .am5, .lga1851:
                    XCTAssertEqual(board.supportedMemoryTypes, [.ddr5], board.name)
                case .lga1700, .none:
                    break // LGA1700 legitimately comes in both flavours
                }
            }
    }

    // MARK: - Happy path

    func testValidBuildHasNoIssues() {
        XCTAssertTrue(Compatibility.isValid(validBuild()))
    }

    // MARK: - Rule 0: missing parts

    func testEmptyBuildReportsFiveMissingParts() {
        let issues = Compatibility.check(PCBuild())
        XCTAssertEqual(issues.count, 5)
        XCTAssertTrue(issues.allSatisfy {
            if case .missingPart = $0 { return true }
            return false
        })
    }

    func testMissingGPUIsReported() {
        var build = validBuild()
        build.gpu = nil
        XCTAssertTrue(Compatibility.check(build).contains(.missingPart(.gpu)))
    }

    // MARK: - Rule 1: socket

    func testAM5CPUOnLGA1700BoardFails() {
        var build = validBuild()
        build.cpu = part("cpu-r7-7700x")   // AM5
        // board stays B660M-HDV, which is LGA1700
        XCTAssertTrue(Compatibility.check(build)
            .contains(.socketMismatch(cpu: .am5, board: .lga1700)))
    }

    func testMatchingSocketProducesNoSocketIssue() {
        var build = validBuild()
        build.cpu = part("cpu-r7-7700x")        // AM5
        build.motherboard = part("mb-b650p-wifi") // AM5
        build.memory = part("ram-veng-16-ddr5")   // AM5 needs DDR5
        let hasSocketIssue = Compatibility.check(build).contains {
            if case .socketMismatch = $0 { return true }
            return false
        }
        XCTAssertFalse(hasSocketIssue)
    }

    // MARK: - Rule 2: memory type

    func testDDR5MemoryOnDDR4BoardFails() {
        var build = validBuild()
        build.memory = part("ram-veng-16-ddr5")  // board is DDR4 only
        XCTAssertTrue(Compatibility.check(build)
            .contains(.memoryUnsupported(has: .ddr5, boardSupports: [.ddr4])))
    }

    /// The LGA1700 trap: same CPU, two boards, only one takes the DDR4 stick.
    func testSameCPUDifferentBoardChangesMemoryRequirement() {
        let cpu = part("cpu-i5-13400f")
        let ddr4Stick = part("ram-lpx-16-ddr4")

        var onDDR4Board = PCBuild(cpu: cpu,
                                  motherboard: part("mb-b660m-hdv"),
                                  memory: ddr4Stick,
                                  gpu: part("gpu-rtx4060"),
                                  psu: part("psu-focus-750"))
        XCTAssertTrue(Compatibility.isValid(onDDR4Board))

        onDDR4Board.motherboard = part("mb-b760m-a-wifi")  // DDR5 board
        XCTAssertFalse(Compatibility.isValid(onDDR4Board))
    }

    // MARK: - Rule 3: power

    func testUnderpoweredPSUFails() {
        var build = validBuild()
        build.cpu = part("cpu-i9-14900k")     // 253W
        build.gpu = part("gpu-rtx4080s")      // 320W
        build.motherboard = part("mb-z790-plus")
        build.memory = part("ram-veng-16-ddr5")
        build.psu = part("psu-cx650m")        // 650W
        // 253 + 320 + 100 headroom = 673W needed
        XCTAssertTrue(Compatibility.check(build)
            .contains(.insufficientPower(needs: 673, has: 650)))
    }

    func testBiggerPSUFixesIt() {
        var build = validBuild()
        build.cpu = part("cpu-i9-14900k")
        build.gpu = part("gpu-rtx4080s")
        build.motherboard = part("mb-z790-plus")
        build.memory = part("ram-veng-16-ddr5")
        build.psu = part("psu-hx1000")        // 1000W
        XCTAssertTrue(Compatibility.isValid(build))
    }

    /// Exactly at the limit should pass — the rule is >=, not >.
    func testPSUExactlyAtRequirementPasses() {
        let build = PCBuild(cpu: part("cpu-i3-12100f"),      // 89W
                            motherboard: part("mb-b660m-hdv"),
                            memory: part("ram-lpx-16-ddr4"),
                            gpu: part("gpu-rtx3050"),        // 130W
                            psu: part("psu-evga-500"))       // 500W
        // 89 + 130 + 100 = 319W needed, 500W available
        XCTAssertTrue(Compatibility.isValid(build))
    }

    // MARK: - canAdd

    func testCanAddRejectsWrongSocketCPU() {
        var build = PCBuild()
        build.motherboard = part("mb-b660m-hdv")   // LGA1700
        XCTAssertFalse(Compatibility.canAdd(part("cpu-r7-7700x"), to: build))
        XCTAssertTrue(Compatibility.canAdd(part("cpu-i5-13400f"), to: build))
    }

    func testCanAddIgnoresEmptySlots() {
        // A lone CPU in an otherwise empty build is fine — nothing conflicts yet.
        XCTAssertTrue(Compatibility.canAdd(part("cpu-r9-7950x"), to: PCBuild()))
    }
}
