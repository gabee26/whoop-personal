import XCTest
import WhoopStore
@testable import Strand

final class PersonalStressSummaryTests: XCTestCase {
    private func day(_ date: String, rhr: Int? = nil) -> DailyMetric {
        DailyMetric(day: date, totalSleepMin: nil, efficiency: nil, deepMin: nil, remMin: nil,
                    lightMin: nil, disturbances: nil, restingHr: rhr, avgHrv: nil,
                    recovery: nil, strain: nil, exerciseCount: nil)
    }

    func testMissingSelectedDayDoesNotCarryOlderScore() {
        let days = [day("2026-11-14", rhr: 55), day("2026-11-15", rhr: 58), day("2026-11-16")]
        XCTAssertNotNil(StressModel(days: days, stored: [])?.score)
        XCTAssertNil(PersonalStressSummary.value(day: "2026-11-16", days: days, stored: []))
    }

    func testStoredSelectedDayWorksWithoutDailyRowAndPreservesZero() {
        XCTAssertEqual(PersonalStressSummary.value(day: "2026-11-16", days: [],
                       stored: [("2026-11-16", 0)]), 0)
    }

    func testInvalidAndOtherDayValuesStayMissing() {
        for value in [Double.nan, .infinity, -1, 3.1] {
            XCTAssertNil(PersonalStressSummary.value(day: "2026-11-16", days: [],
                         stored: [("2026-11-16", value)]))
        }
        XCTAssertNil(PersonalStressSummary.value(day: "2026-11-16", days: [],
                     stored: [("2026-11-15", 2), ("2026-11-17", 1)]))
    }

    func testHistoricalScoreDoesNotUseFutureBaseline() {
        let past = [day("2026-11-14", rhr: 55), day("2026-11-15", rhr: 60)]
        let expected = StressModel(days: past, stored: [])?.score
        XCTAssertNotNil(expected)
        XCTAssertEqual(PersonalStressSummary.value(day: "2026-11-15",
                       days: past + [day("2026-11-16", rhr: 120)], stored: []), expected)
    }
}
