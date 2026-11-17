import XCTest
@testable import Strand

final class PersonalConnectionPresentationTests: XCTestCase {
    func testStandardHeartRateDoesNotRequireHeavyLiveFeed() {
        XCTAssertEqual(PersonalConnectionPresentation.heartRate(connected: true, bpm: 72), 72)
        XCTAssertNil(PersonalConnectionPresentation.heartRate(connected: false, bpm: 72))
        XCTAssertNil(PersonalConnectionPresentation.heartRate(connected: true, bpm: nil))
        XCTAssertNil(PersonalConnectionPresentation.heartRate(connected: true, bpm: 0))
    }

    func testHealthStreamYieldsToHistoryAndLifecycle() {
        for visible in [false, true] {
            for active in [false, true] {
                for connected in [false, true] {
                    for backfilling in [false, true] {
                        let result = PersonalConnectionPresentation.wantsLive(visible: visible, active: active,
                            connected: connected, backfilling: backfilling)
                        XCTAssertEqual(result, visible && active && connected && !backfilling)
                    }
                }
            }
        }
    }

    func testBluetoothLinkDoesNotClaimHistoryReady() {
        XCTAssertEqual(PersonalConnectionPresentation.title(connected: true, historyReady: false,
            backfilling: false, experimental: false, hasError: false), "LIGADA · HISTÓRICO INDISPONÍVEL")
        XCTAssertEqual(PersonalConnectionPresentation.title(connected: true, historyReady: true,
            backfilling: false, experimental: true, hasError: false), "LIGADA · SEM HISTÓRICO RECEBIDO")
        XCTAssertEqual(PersonalConnectionPresentation.title(connected: true, historyReady: true,
            backfilling: false, experimental: false, hasError: true), "SINCRONIZAÇÃO INTERROMPIDA")
    }
}
