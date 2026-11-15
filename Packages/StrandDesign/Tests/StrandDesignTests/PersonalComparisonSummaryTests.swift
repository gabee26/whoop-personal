import XCTest
@testable import StrandDesign

final class PersonalComparisonSummaryTests: XCTestCase {
    func testOppositeDifferencesDoNotCancelAbsoluteDifference() throws {
        let result = PersonalComparisonSummary(reference: ["2026-01-01": 60, "2026-01-02": 60],
                                               local: ["2026-01-01": 50, "2026-01-02": 70])
        XCTAssertEqual(try XCTUnwrap(result.meanAbsoluteDifference), 10)
        XCTAssertEqual(try XCTUnwrap(result.meanDifference), 0)
        XCTAssertEqual(result.pairs.map(\.difference), [-10, 10])
    }

    func testMissingDaysAreNotFilledOrPairedByPosition() {
        let result = PersonalComparisonSummary(reference: ["2026-01-01": 0, "2026-01-03": 80],
                                               local: ["2026-01-01": 0, "2026-01-02": 80])
        XCTAssertEqual(result.pairs.count, 1)
        XCTAssertEqual(result.pairs.first?.day, "2026-01-01")
        XCTAssertEqual(result.referenceOnly, 1)
        XCTAssertEqual(result.localOnly, 1)
        XCTAssertEqual(result.meanAbsoluteDifference, 0)
    }

    func testNoOverlapAndInvalidReadingsHaveNoAccuracyClaim() {
        let result = PersonalComparisonSummary(reference: ["a": .nan, "b": 10],
                                               local: ["a": 20, "b": .infinity])
        XCTAssertTrue(result.pairs.isEmpty)
        XCTAssertNil(result.meanAbsoluteDifference)
        XCTAssertNil(result.meanDifference)
    }
}
