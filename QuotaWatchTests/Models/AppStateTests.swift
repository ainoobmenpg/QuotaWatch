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
        XCTAssertLessThanOrEqual(state.fetch.nextFetchEpoch, Date().epochSeconds)
        XCTAssertEqual(state.fetch.backoffFactor, 1)
        XCTAssertEqual(state.fetch.lastFetchEpoch, 0)
        XCTAssertEqual(state.fetch.lastError, "")
        XCTAssertEqual(state.notification.lastKnownResetEpoch, 0)
        XCTAssertEqual(state.notification.lastNotifiedResetEpoch, 0)
    }

    func testFetchStateDefaultInitialization() {
        let state = FetchState()
        XCTAssertLessThanOrEqual(state.nextFetchEpoch, Date().epochSeconds)
        XCTAssertEqual(state.backoffFactor, 1)
        XCTAssertEqual(state.lastFetchEpoch, 0)
        XCTAssertEqual(state.lastError, "")
        XCTAssertEqual(state.consecutiveFailureCount, 0)
    }

    func testNotificationStateDefaultInitialization() {
        let state = NotificationState()
        XCTAssertEqual(state.lastKnownResetEpoch, 0)
        XCTAssertEqual(state.lastNotifiedResetEpoch, 0)
    }

    func testCodable() throws {
        var state = AppState()
        state.fetch.backoffFactor = 2
        state.fetch.lastError = "test error"

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(state)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppState.self, from: data)

        XCTAssertEqual(decoded.fetch.backoffFactor, 2)
        XCTAssertEqual(decoded.fetch.lastError, "test error")
    }

    func testFetchStateCodable() throws {
        var state = FetchState()
        state.backoffFactor = 3
        state.lastError = "fetch error"

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(state)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FetchState.self, from: data)

        XCTAssertEqual(decoded.backoffFactor, 3)
        XCTAssertEqual(decoded.lastError, "fetch error")
    }

    func testNotificationStateCodable() throws {
        var state = NotificationState()
        state.lastKnownResetEpoch = 1737100800
        state.lastNotifiedResetEpoch = 1737100900

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(state)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NotificationState.self, from: data)

        XCTAssertEqual(decoded.lastKnownResetEpoch, 1737100800)
        XCTAssertEqual(decoded.lastNotifiedResetEpoch, 1737100900)
    }

    func testEquatable() {
        var state1 = AppState()
        var state2 = AppState()

        XCTAssertEqual(state1, state2)

        state1.fetch.backoffFactor = 3
        XCTAssertNotEqual(state1, state2)
    }

    func testFetchStateEquatable() {
        var state1 = FetchState()
        var state2 = FetchState()

        XCTAssertEqual(state1, state2)

        state1.backoffFactor = 3
        XCTAssertNotEqual(state1, state2)
    }

    func testNotificationStateEquatable() {
        var state1 = NotificationState()
        var state2 = NotificationState()

        XCTAssertEqual(state1, state2)

        state1.lastKnownResetEpoch = 123
        XCTAssertNotEqual(state1, state2)
    }

    func testMutability() {
        var state = AppState()
        let originalNextFetch = state.fetch.nextFetchEpoch

        state.fetch.backoffFactor = 4
        state.fetch.lastError = "network error"
        state.notification.lastKnownResetEpoch = 1737100800
        state.notification.lastNotifiedResetEpoch = 1737100900
        state.fetch.nextFetchEpoch = originalNextFetch + 3600
        state.fetch.lastFetchEpoch = originalNextFetch

        XCTAssertEqual(state.fetch.backoffFactor, 4)
        XCTAssertEqual(state.fetch.lastError, "network error")
        XCTAssertEqual(state.notification.lastKnownResetEpoch, 1737100800)
        XCTAssertEqual(state.notification.lastNotifiedResetEpoch, 1737100900)
        XCTAssertEqual(state.fetch.nextFetchEpoch, originalNextFetch + 3600)
        XCTAssertEqual(state.fetch.lastFetchEpoch, originalNextFetch)
    }

    func testFetchStateMutability() {
        var state = FetchState()
        let originalNextFetch = state.nextFetchEpoch

        state.backoffFactor = 5
        state.lastError = "error"
        state.nextFetchEpoch = originalNextFetch + 1000
        state.lastFetchEpoch = originalNextFetch
        state.consecutiveFailureCount = 3

        XCTAssertEqual(state.backoffFactor, 5)
        XCTAssertEqual(state.lastError, "error")
        XCTAssertEqual(state.nextFetchEpoch, originalNextFetch + 1000)
        XCTAssertEqual(state.lastFetchEpoch, originalNextFetch)
        XCTAssertEqual(state.consecutiveFailureCount, 3)
    }

    func testNotificationStateMutability() {
        var state = NotificationState()

        state.lastKnownResetEpoch = 100
        state.lastNotifiedResetEpoch = 200

        XCTAssertEqual(state.lastKnownResetEpoch, 100)
        XCTAssertEqual(state.lastNotifiedResetEpoch, 200)
    }

    // MARK: - 互換性プロパティのテスト

    func testCompatibilityProperties() {
        var state = AppState()
        let originalNextFetch = state.fetch.nextFetchEpoch

        // 互換性プロパティ経由でアクセス
        state.backoffFactor = 4
        state.lastError = "network error"
        state.lastKnownResetEpoch = 1737100800
        state.lastNotifiedResetEpoch = 1737100900
        state.nextFetchEpoch = originalNextFetch + 3600
        state.lastFetchEpoch = originalNextFetch
        state.consecutiveFailureCount = 2

        // 内部構造と整合性が取れていることを確認
        XCTAssertEqual(state.fetch.backoffFactor, 4)
        XCTAssertEqual(state.fetch.lastError, "network error")
        XCTAssertEqual(state.notification.lastKnownResetEpoch, 1737100800)
        XCTAssertEqual(state.notification.lastNotifiedResetEpoch, 1737100900)
        XCTAssertEqual(state.fetch.nextFetchEpoch, originalNextFetch + 3600)
        XCTAssertEqual(state.fetch.lastFetchEpoch, originalNextFetch)
        XCTAssertEqual(state.fetch.consecutiveFailureCount, 2)
    }
}
