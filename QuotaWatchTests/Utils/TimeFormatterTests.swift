//
//  TimeFormatterTests.swift
//  QuotaWatchTests
//
//  TimeFormatterの単体テスト
//

import XCTest
@testable import QuotaWatch

/// TimeFormatterの単体テスト
final class TimeFormatterTests: XCTestCase {
    // MARK: - 境界値テスト

    func testFormatTimeRemaining_ZeroSeconds() {
        // 現在時刻と同じ場合
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now)
        XCTAssertEqual(result, "0s", "0秒は '0s' と表示されるべき")
    }

    func testFormatTimeRemaining_OneSecond() {
        // 1秒後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + 1)
        XCTAssertEqual(result, "1s", "1秒は '1s' と表示されるべき")
    }

    func testFormatTimeRemaining_FiftyNineSeconds() {
        // 59秒後（1分未満の境界値）
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + 59)
        XCTAssertEqual(result, "59s", "59秒は '59s' と表示されるべき")
    }

    func testFormatTimeRemaining_OneMinute() {
        // 1分後（60秒）
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + 60)
        XCTAssertEqual(result, "1m", "60秒は '1m' と表示されるべき")
    }

    func testFormatTimeRemaining_OneMinuteOneSecond() {
        // 1分1秒後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + 61)
        XCTAssertEqual(result, "1m", "61秒は '1m' と表示されるべき（分単位に丸められる）")
    }

    func testFormatTimeRemaining_FiftyNineMinutes() {
        // 59分後（1時間未満の境界値）
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (59 * 60))
        XCTAssertEqual(result, "59m", "59分は '59m' と表示されるべき")
    }

    func testFormatTimeRemaining_OneHour() {
        // 1時間後（60分）
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (60 * 60))
        XCTAssertEqual(result, "1h", "60分は '1h' と表示されるべき")
    }

    func testFormatTimeRemaining_OneHourOneMinute() {
        // 1時間1分後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (60 * 60) + 60)
        XCTAssertEqual(result, "1h1m", "1時間1分は '1h1m' と表示されるべき")
    }

    func testFormatTimeRemaining_OneHourThirtyMinutes() {
        // 1時間30分後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (60 * 60) + (30 * 60))
        XCTAssertEqual(result, "1h30m", "1時間30分は '1h30m' と表示されるべき")
    }

    func testFormatTimeRemaining_TwoHours() {
        // 2時間後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (2 * 60 * 60))
        XCTAssertEqual(result, "2h", "2時間は '2h' と表示されるべき")
    }

    func testFormatTimeRemaining_TwoHoursFifteenMinutes() {
        // 2時間15分後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (2 * 60 * 60) + (15 * 60))
        XCTAssertEqual(result, "2h15m", "2時間15分は '2h15m' と表示されるべき")
    }

    // MARK: - 負数処理テスト

    func testFormatTimeRemaining_PastTime() {
        // 過去の時刻（リセット時刻が現在より前）
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now - 100)
        XCTAssertEqual(result, "0s", "過去の時刻は '0s' と表示されるべき")
    }
}
