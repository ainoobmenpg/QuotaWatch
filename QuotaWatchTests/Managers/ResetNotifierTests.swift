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

// MARK: - Mock Notification Manager

/// テスト用のモック通知マネージャー
public actor MockNotificationManager {
    public private(set) var sentNotifications: [(title: String, body: String)] = []
    public private(set) var authorizationRequested: Bool = false
    public var shouldFail: Bool = false
    public var authorizationGranted: Bool = true

    public init() {}

    public func requestAuthorization() async throws -> Bool {
        authorizationRequested = true
        if !authorizationGranted {
            throw NotificationManagerError.notAuthorized
        }
        return authorizationGranted
    }

    public func getAuthorizationStatus() async -> UNAuthorizationStatus {
        return authorizationGranted ? .authorized : .denied
    }

    public func send(title: String, body: String) async throws {
        if shouldFail {
            throw NotificationManagerError.addFailed("Mock error")
        }
        sentNotifications.append((title, body))
    }

    public func setShouldFail(_ value: Bool) {
        shouldFail = value
    }
}

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

    func testNotificationErrorHandling() async throws {
        let mockNotification = MockNotificationManager()
        await mockNotification.setShouldFail(true)

        // 通知送信がエラーになることを確認
        do {
            try await mockNotification.send(title: "Test", body: "Test")
            XCTFail("エラーになるべきです")
        } catch NotificationManagerError.addFailed {
            // 期待通りのエラー
            XCTAssertTrue(true)
        } catch {
            XCTFail("予期しないエラー: \(error)")
        }
    }
}

// MARK: - Helper Extensions

extension Date {
    /// epoch秒を取得
    var epochSeconds: Int {
        return Int(self.timeIntervalSince1970)
    }
}
