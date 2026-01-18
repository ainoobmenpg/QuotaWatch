//
//  EngineStateTests.swift
//  QuotaWatchTests
//
//  EngineStateの単体テスト
//

import XCTest
@testable import QuotaWatch

/// EngineStateの単体テスト
final class EngineStateTests: XCTestCase {
    // MARK: - 初期化テスト

    func testInitialization() {
        let state = EngineState(
            nextFetchEpoch: 1234567890,
            backoffFactor: 2,
            lastFetchEpoch: 1234567500,
            consecutiveFailureCount: 3
        )

        XCTAssertEqual(state.nextFetchEpoch, 1234567890)
        XCTAssertEqual(state.backoffFactor, 2)
        XCTAssertEqual(state.lastFetchEpoch, 1234567500)
        XCTAssertEqual(state.consecutiveFailureCount, 3)
    }

    func testInitializationFromAppState() {
        let appState = AppState(
            nextFetchEpoch: 1234567890,
            backoffFactor: 4,
            lastFetchEpoch: 1234567500,
            lastError: "Test error",
            lastKnownResetEpoch: 0,
            lastNotifiedResetEpoch: 0,
            consecutiveFailureCount: 5
        )

        let state = EngineState(from: appState)

        XCTAssertEqual(state.nextFetchEpoch, 1234567890)
        XCTAssertEqual(state.backoffFactor, 4)
        XCTAssertEqual(state.lastFetchEpoch, 1234567500)
        XCTAssertEqual(state.consecutiveFailureCount, 5)
    }

    // MARK: - 計算プロパティテスト

    func testSecondsUntilNextFetch_Future() {
        let now = Date().epochSeconds
        let futureTime = now + 300 // 5分後

        let state = EngineState(
            nextFetchEpoch: futureTime,
            backoffFactor: 1,
            lastFetchEpoch: now - 100,
            consecutiveFailureCount: 0
        )

        // 300秒前後（テスト実行中の時間経過を許容）
        XCTAssertEqual(state.secondsUntilNextFetch, 300)
    }

    func testSecondsUntilNextFetch_Past() {
        let now = Date().epochSeconds
        let pastTime = now - 100 // 100秒前

        let state = EngineState(
            nextFetchEpoch: pastTime,
            backoffFactor: 1,
            lastFetchEpoch: pastTime - 100,
            consecutiveFailureCount: 0
        )

        // 過去の時刻は0を返す
        XCTAssertEqual(state.secondsUntilNextFetch, 0)
    }

    func testSecondsUntilNextFetch_Now() {
        let now = Date().epochSeconds

        let state = EngineState(
            nextFetchEpoch: now,
            backoffFactor: 1,
            lastFetchEpoch: now - 100,
            consecutiveFailureCount: 0
        )

        // 現在時刻は0を返す
        XCTAssertEqual(state.secondsUntilNextFetch, 0)
    }

    func testIsBackingOff_NoBackoff() {
        let state = EngineState(
            nextFetchEpoch: 0,
            backoffFactor: 1,
            lastFetchEpoch: 0,
            consecutiveFailureCount: 0
        )

        XCTAssertFalse(state.isBackingOff, "backoffFactor=1はバックオフ中ではない")
    }

    func testIsBackingOff_WithBackoff() {
        let state = EngineState(
            nextFetchEpoch: 0,
            backoffFactor: 2,
            lastFetchEpoch: 0,
            consecutiveFailureCount: 1
        )

        XCTAssertTrue(state.isBackingOff, "backoffFactor>1はバックオフ中")
    }

    func testIsBackingOff_MaxBackoff() {
        let state = EngineState(
            nextFetchEpoch: 0,
            backoffFactor: 16,
            lastFetchEpoch: 0,
            consecutiveFailureCount: 15
        )

        XCTAssertTrue(state.isBackingOff, "backoffFactor=16はバックオフ中")
    }

    // MARK: - Equatableテスト

    func testEquatable_SameValues() {
        let state1 = EngineState(
            nextFetchEpoch: 1234567890,
            backoffFactor: 2,
            lastFetchEpoch: 1234567500,
            consecutiveFailureCount: 3
        )

        let state2 = EngineState(
            nextFetchEpoch: 1234567890,
            backoffFactor: 2,
            lastFetchEpoch: 1234567500,
            consecutiveFailureCount: 3
        )

        XCTAssertEqual(state1, state2)
    }

    func testEquatable_DifferentNextFetchEpoch() {
        let state1 = EngineState(
            nextFetchEpoch: 1234567890,
            backoffFactor: 1,
            lastFetchEpoch: 1234567500,
            consecutiveFailureCount: 0
        )

        let state2 = EngineState(
            nextFetchEpoch: 1234567999,
            backoffFactor: 1,
            lastFetchEpoch: 1234567500,
            consecutiveFailureCount: 0
        )

        XCTAssertNotEqual(state1, state2)
    }

    func testEquatable_DifferentBackoffFactor() {
        let state1 = EngineState(
            nextFetchEpoch: 1234567890,
            backoffFactor: 1,
            lastFetchEpoch: 1234567500,
            consecutiveFailureCount: 0
        )

        let state2 = EngineState(
            nextFetchEpoch: 1234567890,
            backoffFactor: 2,
            lastFetchEpoch: 1234567500,
            consecutiveFailureCount: 0
        )

        XCTAssertNotEqual(state1, state2)
    }
}
