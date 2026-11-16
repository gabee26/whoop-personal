import XCTest
@testable import StrandDesign

final class PersonalAthleteRecordsTests: XCTestCase {
    func testOnlyCompletedRatedSessionsContributeLoad() {
        var session = PersonalAthleteSession(minutes: 90, completed: false, exertion: 8)
        XCTAssertNil(session.perceivedLoad)
        session.completed = true
        XCTAssertEqual(session.perceivedLoad, 720)
        session.exertion = nil
        XCTAssertNil(session.perceivedLoad)
        session.exertion = 11
        XCTAssertNil(session.perceivedLoad)
        session.exertion = 8
        session.minutes = -10
        XCTAssertNil(session.perceivedLoad)
    }

    func testMissingNightsAndSurplusAreNotDebt() {
        XCTAssertNil(PersonalAthleteSummary.sleepGap(hours: [], target: 8))
        XCTAssertNil(PersonalAthleteSummary.sleepGap(hours: [0, .nan, 25], target: 8))
        XCTAssertEqual(PersonalAthleteSummary.sleepGap(hours: [6, 9, 7, 0, .nan], target: 8), 3)
        XCTAssertNil(PersonalAthleteSummary.sleepGap(hours: [6], target: .infinity))
    }

    func testBaselineNeedsEnoughActualReadings() {
        XCTAssertNil(PersonalAthleteSummary.referenceMean([60, 62, 0, .nan]))
        XCTAssertEqual(PersonalAthleteSummary.referenceMean([60, 62, 64, 66, 68, 70, 72, 0, .nan]), 66)
        XCTAssertNil(PersonalAthleteSummary.referenceMean([], minimumCount: 0))
    }

    func testBedtimeIncludesBufferAcrossMidnight() {
        let wake = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(PersonalAthleteSummary.bedtime(wake: wake, sleepHours: 9, bufferMinutes: 20), wake.addingTimeInterval(-33600))
        XCTAssertNil(PersonalAthleteSummary.bedtime(wake: wake, sleepHours: .nan, bufferMinutes: 20))
        XCTAssertNil(PersonalAthleteSummary.bedtime(wake: wake, sleepHours: 9, bufferMinutes: -1))
    }

    func testArchiveRoundTripAndValidation() throws {
        var archive = PersonalAthleteArchive()
        archive.checkIns = [PersonalAthleteCheckIn(day: "2026-11-16", soreness: ["Ombro": 4])]
        archive.sessions = [PersonalAthleteSession(minutes: 70, completed: true, exertion: 6)]
        let decoded = try JSONDecoder().decode(PersonalAthleteArchive.self, from: JSONEncoder().encode(archive))
        try decoded.validate()
        XCTAssertEqual(decoded.sessions.first?.perceivedLoad, 420)
        XCTAssertEqual(decoded.checkIns.first?.soreness["Ombro"], 4)
        archive.checkIns.append(archive.checkIns[0])
        XCTAssertThrowsError(try archive.validate())
    }

    func testCorruptArchiveCannotPassValidation() {
        var archive = PersonalAthleteArchive()
        archive.version = 2
        XCTAssertThrowsError(try archive.validate())
        archive.version = 1
        archive.checkIns = [PersonalAthleteCheckIn(day: "2026-02-30")]
        XCTAssertThrowsError(try archive.validate())
        archive.checkIns = [PersonalAthleteCheckIn(day: "2026-11-16", fatigue: 6)]
        XCTAssertThrowsError(try archive.validate())
        archive.checkIns = [PersonalAthleteCheckIn(day: "2026-11-16", soreness: ["Ombro": 11])]
        XCTAssertThrowsError(try archive.validate())
    }
}
