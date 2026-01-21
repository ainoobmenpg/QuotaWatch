//
//  AppStateTests.swift
//  QuotaWatchTests
//
//  AppStateのテスト
//

import XCTest
@testable import QuotaWatch

final class AppStateTests: XCTestCase {
    func testDefaultInitialization() {
        let state = AppState()
        XCTAssertLessThanOrEqual(state.nextFetchEpoch, Date().epochSeconds)
        XCTAssertEqual(state.backoffFactor, 1)
        XCTAssertEqual(state.lastFetchEpoch, 0)
        XCTAssertEqual(state.lastError, "")
        XCTAssertEqual(state.lastKnownResetEpoch, 0)
        XCTAssertEqual(state.lastNotifiedResetEpoch, 0)
    }

    func testCodable() throws {
        var state = AppState()
        state.backoffFactor = 2
        state.lastError = "test error"

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(state)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppState.self, from: data)

        XCTAssertEqual(decoded.backoffFactor, 2)
        XCTAssertEqual(decoded.lastError, "test error")
    }

    func testEquatable() {
        var state1 = AppState()
        var state2 = AppState()

        XCTAssertEqual(state1, state2)

        state1.backoffFactor = 3
        XCTAssertNotEqual(state1, state2)
    }

    func testMutability() {
        var state = AppState()
        let originalNextFetch = state.nextFetchEpoch

        state.backoffFactor = 4
        state.lastError = "network error"
        state.lastKnownResetEpoch = 1737100800
        state.lastNotifiedResetEpoch = 1737100900
        state.nextFetchEpoch = originalNextFetch + 3600
        state.lastFetchEpoch = originalNextFetch

        XCTAssertEqual(state.backoffFactor, 4)
        XCTAssertEqual(state.lastError, "network error")
        XCTAssertEqual(state.lastKnownResetEpoch, 1737100800)
        XCTAssertEqual(state.lastNotifiedResetEpoch, 1737100900)
        XCTAssertEqual(state.nextFetchEpoch, originalNextFetch + 3600)
        XCTAssertEqual(state.lastFetchEpoch, originalNextFetch)
    }
}
