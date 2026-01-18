//
//  AppSettingsTests.swift
//  QuotaWatchTests
//
//  AppSettingsのテスト
//

import XCTest
@testable import QuotaWatch

final class AppSettingsTests: XCTestCase {
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // テスト用のUserDefaultsを作成
        testDefaults = UserDefaults(suiteName: #file)!
        // 既存の設定をクリア
        testDefaults.removePersistentDomain(forName: #file)
    }

    override func tearDown() {
        // テスト後に設定をクリア
        testDefaults.removePersistentDomain(forName: #file)
        super.tearDown()
    }

    func testUpdateIntervalDefault() {
        let settings = AppSettings(defaults: testDefaults)
        XCTAssertEqual(settings.updateInterval, .fiveMinutes)
    }

    func testUpdateIntervalPersistence() {
        let settings = AppSettings(defaults: testDefaults)

        settings.updateInterval = .tenMinutes
        XCTAssertEqual(settings.updateInterval, .tenMinutes)

        let newSettings = AppSettings(defaults: testDefaults)
        XCTAssertEqual(newSettings.updateInterval, .tenMinutes)
    }

    func testNotificationsEnabledDefault() {
        let settings = AppSettings(defaults: testDefaults)
        XCTAssertTrue(settings.notificationsEnabled)
    }

    func testNotificationsDisabledPersistence() {
        let settings = AppSettings(defaults: testDefaults)

        settings.notificationsEnabled = false
        XCTAssertFalse(settings.notificationsEnabled)

        let newSettings = AppSettings(defaults: testDefaults)
        XCTAssertFalse(newSettings.notificationsEnabled)
    }

    func testLoginItemEnabledDefault() {
        let settings = AppSettings(defaults: testDefaults)
        XCTAssertFalse(settings.loginItemEnabled)
    }

    func testAllUpdateIntervals() {
        let settings = AppSettings(defaults: testDefaults)

        for interval in UpdateInterval.allCases {
            settings.updateInterval = interval
            XCTAssertEqual(settings.updateInterval, interval)
        }
    }
}
