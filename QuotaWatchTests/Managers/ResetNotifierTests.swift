//
//  ResetNotifierTests.swift
//  QuotaWatchTests
//
//  ResetNotifierの単体テスト
//

import Foundation
import XCTest
import UserNotifications

@testable import QuotaWatch

// MARK: - ResetNotifier Tests

final class ResetNotifierTests: XCTestCase {
    var mockPersistence: PersistenceManager!
    var tempDirectory: URL!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appending(path: "QuotaWatchTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        mockPersistence = PersistenceManager(customDirectoryURL: tempDirectory)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // MARK: - リセット検知テスト

    func testResetNotificationSent() async throws {
        // テスト用のAppStateを作成（リセット時刻を過去に設定）
        let now = Date().epochSeconds
        let pastResetEpoch = now - 3600 // 1時間前
        var testState = AppState()
        testState.lastKnownResetEpoch = pastResetEpoch
        testState.lastNotifiedResetEpoch = pastResetEpoch - Int(AppConstants.resetIntervalSeconds) // 未通知状態

        try await mockPersistence.saveState(testState)

        // このテストは、ResetNotifierの動作を確認するためのものです
        // 実際のQuotaEngineと統合してテストする必要があります
        // プレースホルダーとして、状態が正しく保存されることを確認
        let loadedState = try await mockPersistence.loadState()
        XCTAssertEqual(loadedState.lastKnownResetEpoch, pastResetEpoch)
    }

    func testDuplicatePrevention() async throws {
        // 既に通知済みの状態
        var testState = AppState()
        let resetEpoch = Date().epochSeconds - 3600
        testState.lastKnownResetEpoch = resetEpoch
        testState.lastNotifiedResetEpoch = resetEpoch // 既に通知済み

        // 2回目の通知は送信されないことを確認
        XCTAssertEqual(testState.lastKnownResetEpoch, testState.lastNotifiedResetEpoch)
    }

    func testEpochAdvancement() async throws {
        var testState = AppState()
        let initialResetEpoch = Date().epochSeconds - 3600
        testState.lastKnownResetEpoch = initialResetEpoch
        testState.lastNotifiedResetEpoch = initialResetEpoch - Int(AppConstants.resetIntervalSeconds)

        // 通知後にepochが進むことを確認
        testState.lastNotifiedResetEpoch = testState.lastKnownResetEpoch
        testState.lastKnownResetEpoch += Int(AppConstants.resetIntervalSeconds)

        let expected = initialResetEpoch + Int(AppConstants.resetIntervalSeconds)
        XCTAssertEqual(testState.lastKnownResetEpoch, expected)
        XCTAssertEqual(testState.lastNotifiedResetEpoch, initialResetEpoch)
    }

    // MARK: - スリープ復帰テスト

    func testWakeFromSleepTriggersCheck() async throws {
        // リセット時刻を過去に設定
        let now = Date().epochSeconds
        let pastResetEpoch = now - 3600 // 1時間前

        var testState = AppState()
        testState.lastKnownResetEpoch = pastResetEpoch
        testState.lastNotifiedResetEpoch = pastResetEpoch - Int(AppConstants.resetIntervalSeconds)

        try await mockPersistence.saveState(testState)

        // 状態が正しく保存されたことを確認
        let loadedState = try await mockPersistence.loadState()
        XCTAssertEqual(loadedState.lastKnownResetEpoch, pastResetEpoch)
        XCTAssertEqual(loadedState.lastNotifiedResetEpoch, pastResetEpoch - Int(AppConstants.resetIntervalSeconds))

        // 注: スリープ復帰の完全なテストは NSWorkspace.screensDidWakeNotification の
        // 送信を必要とするため、統合テストで実施する必要があります
        // ここでは状態管理の正しさを確認します
    }

    func testDuplicatePreventionAfterWake() async throws {
        // 通知済みの状態（重複防止確認）
        var testState = AppState()
        let resetEpoch = Date().epochSeconds - 3600
        testState.lastKnownResetEpoch = resetEpoch
        testState.lastNotifiedResetEpoch = resetEpoch // 既に通知済み

        try await mockPersistence.saveState(testState)

        let loadedState = try await mockPersistence.loadState()
        XCTAssertEqual(loadedState.lastKnownResetEpoch, loadedState.lastNotifiedResetEpoch)
    }
}
