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
    // MARK: - 境界値テスト（00h00m形式）

    func testFormatTimeRemaining_ZeroSeconds() {
        // 現在時刻と同じ場合
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now)
        XCTAssertEqual(result, "00h00m", "0秒は '00h00m' と表示されるべき")
    }

    func testFormatTimeRemaining_OneSecond() {
        // 1秒後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + 1)
        XCTAssertEqual(result, "00h00m", "1秒は '00h00m' と表示されるべき")
    }

    func testFormatTimeRemaining_FiftyNineSeconds() {
        // 59秒後（1分未満の境界値）
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + 59)
        XCTAssertEqual(result, "00h00m", "59秒は '00h00m' と表示されるべき")
    }

    func testFormatTimeRemaining_OneMinute() {
        // 1分後（60秒）
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + 60)
        XCTAssertEqual(result, "00h01m", "60秒は '00h01m' と表示されるべき")
    }

    func testFormatTimeRemaining_OneMinuteOneSecond() {
        // 1分1秒後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + 61)
        XCTAssertEqual(result, "00h01m", "61秒は '00h01m' と表示されるべき")
    }

    func testFormatTimeRemaining_FourMinutesThirtySeconds() {
        // 4分30秒後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (4 * 60) + 30)
        XCTAssertEqual(result, "00h04m", "4分30秒は '00h04m' と表示されるべき")
    }

    func testFormatTimeRemaining_FiftyNineMinutes() {
        // 59分後（1時間未満の境界値）
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (59 * 60))
        XCTAssertEqual(result, "00h59m", "59分は '00h59m' と表示されるべき")
    }

    func testFormatTimeRemaining_OneHour() {
        // 1時間後（60分）
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (60 * 60))
        XCTAssertEqual(result, "01h00m", "60分は '01h00m' と表示されるべき")
    }

    func testFormatTimeRemaining_OneHourOneMinute() {
        // 1時間1分後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (60 * 60) + 60)
        XCTAssertEqual(result, "01h01m", "1時間1分は '01h01m' と表示されるべき")
    }

    func testFormatTimeRemaining_OneHourThirtyMinutes() {
        // 1時間30分後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (60 * 60) + (30 * 60))
        XCTAssertEqual(result, "01h30m", "1時間30分は '01h30m' と表示されるべき")
    }

    func testFormatTimeRemaining_TwoHours() {
        // 2時間後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (2 * 60 * 60))
        XCTAssertEqual(result, "02h00m", "2時間は '02h00m' と表示されるべき")
    }

    func testFormatTimeRemaining_TwoHoursFifteenMinutes() {
        // 2時間15分後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (2 * 60 * 60) + (15 * 60))
        XCTAssertEqual(result, "02h15m", "2時間15分は '02h15m' と表示されるべき")
    }

    func testFormatTimeRemaining_FourHoursThirtyMinutes() {
        // 4時間30分後
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now + (4 * 60 * 60) + (30 * 60))
        XCTAssertEqual(result, "04h30m", "4時間30分は '04h30m' と表示されるべき")
    }

    // MARK: - 負数処理テスト

    func testFormatTimeRemaining_PastTime() {
        // 過去の時刻（リセット時刻が現在より前）
        let now = Date().epochSeconds
        let result = TimeFormatter.formatTimeRemaining(resetEpoch: now - 100)
        XCTAssertEqual(result, "00h00m", "過去の時刻は '00h00m' と表示されるべき")
    }
}
