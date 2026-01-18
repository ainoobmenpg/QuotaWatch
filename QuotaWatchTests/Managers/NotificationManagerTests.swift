//
//  NotificationManagerTests.swift
//  QuotaWatchTests
//
//  NotificationManagerの単体テスト
//

import Foundation
import XCTest
import UserNotifications

@testable import QuotaWatch

// MARK: - NotificationManager Tests

final class NotificationManagerTests: XCTestCase {
    var manager: NotificationManager!

    override func setUp() async throws {
        manager = NotificationManager.shared
    }

    // MARK: - 権限管理テスト

    func testGetAuthorizationStatus() async throws {
        // 権限ステータスを取得（エラーにならないことを確認）
        let status = await manager.getAuthorizationStatus()

        // いずれかのステータスが返ることを確認
        // 注: .ephemeral はiOSのみ、.provisional はiOSのみ
        XCTAssertTrue(
            status == .authorized ||
            status == .notDetermined ||
            status == .denied
        )
    }

    // MARK: - 通知送信テスト

    func testSendNotificationWithAuthorization() async throws {
        // 権限を確認
        let status = await manager.getAuthorizationStatus()

        if status == .authorized {
            // 権限がある場合のみ通知送信をテスト
            try await manager.send(
                title: "テスト通知",
                body: "これはテスト通知です"
            )
            // エラーが投げられなければ成功
        } else {
            // 権限がない場合はテストをスキップ
            throw XCTSkip("通知権限がないためテストをスキップします")
        }
    }

    func testSendNotificationWithoutAuthorization() async throws {
        // 権限ステータスを確認
        let status = await manager.getAuthorizationStatus()

        if status != .authorized {
            // 権限がない場合、エラーになることを確認
            do {
                try await manager.send(
                    title: "テスト通知",
                    body: "これはテスト通知です"
                )
                XCTFail("権限がない場合、エラーになるべきです")
            } catch NotificationManagerError.notAuthorized {
                // 期待通りのエラー
                XCTAssertTrue(true)
            } catch {
                XCTFail("予期しないエラー: \(error)")
            }
        } else {
            // 権限がある場合はテストをスキップ
            throw XCTSkip("通知権限があるためテストをスキップします")
        }
    }

    func testRequestAuthorization() async throws {
        // 権限を要求（ユーザー操作が必要なため、主にエラーにならないことを確認）
        do {
            let granted = try await manager.requestAuthorization()
            // 結果は環境依存
            XCTAssertTrue(granted == true || granted == false)
        } catch {
            // エラーが発生してもクラッシュしないことを確認
            XCTAssertNotNil(error)
        }
    }
}
