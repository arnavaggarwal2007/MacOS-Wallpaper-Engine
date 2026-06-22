import XCTest
@testable import Personal_Wallpaper_Engine

final class CPUMetricsFormattingTests: XCTestCase {
    func testSystemWidePercentDividesByLogicalCoreCount() {
        let perCore = 12.0
        let expected = perCore / Double(max(1, CPUMetricsFormatting.logicalProcessorCount))
        XCTAssertEqual(
            CPUMetricsFormatting.systemWidePercent(fromPerCore: perCore),
            expected,
            accuracy: 0.0001
        )
    }

    func testPerCoreTextWhenNotReady() {
        XCTAssertEqual(CPUMetricsFormatting.perCoreText(5.0, ready: false), "Measuring…")
    }

    func testMenuBarCPUTextWhenReady() {
        XCTAssertEqual(CPUMetricsFormatting.menuBarCPUText(perCoreAverage: 12.5, ready: true), "CPU 12.5%")
    }
}
