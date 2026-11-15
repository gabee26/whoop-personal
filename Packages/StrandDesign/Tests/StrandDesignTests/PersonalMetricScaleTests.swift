import XCTest
@testable import StrandDesign

final class PersonalMetricScaleTests: XCTestCase {
    func testEffortAxisAnchors() throws {
        for (stored, displayed) in [(0.0, 0.0), (25, 5.25), (50, 10.5), (75, 15.75), (100, 21)] {
            XCTAssertEqual(try XCTUnwrap(PersonalMetricScale.effort(stored)), displayed, accuracy: 1e-12)
        }
    }

    func testImportedWhoopStrainRoundTrip() throws {
        // Matches the importer's documented 21 -> 100 rescale; cover the full axis.
        for tenth in 0...210 {
            let original = Double(tenth) / 10
            let stored = original * (100.0 / 21.0)
            XCTAssertEqual(try XCTUnwrap(PersonalMetricScale.effort(stored)), original, accuracy: 1e-12)
        }
    }

    func testMissingAndInvalidValuesStayMissing() {
        let invalid: [Double?] = [nil, .nan, .infinity, -.infinity, -1, 101]
        for value in invalid {
            XCTAssertNil(PersonalMetricScale.effort(value))
            XCTAssertNil(PersonalMetricScale.percentage(value))
        }
        XCTAssertEqual(PersonalMetricScale.percentage(0), 0)
        XCTAssertEqual(PersonalMetricScale.percentage(100), 100)
    }
}
