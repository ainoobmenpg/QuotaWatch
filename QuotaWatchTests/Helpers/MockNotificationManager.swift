//
//  MockNotificationManager.swift
//  QuotaWatchTests
//
//  テスト用のモックNotificationManager
//

import Foundation
@testable import QuotaWatch

/// テスト用のモックNotificationManager
///
/// 通知の送信をトラッキングし、テストで検証できるようにします。
@MainActor
public final class MockNotificationManager {
    // MARK: - テスト状態

    /// 通知が送信された回数
    public private(set) var sendCallCount = 0

    /// 最後に送信された通知のタイトル
    public private(set) var lastSentTitle: String?

    /// 最後に送信された通知の本文
    public private(set) var lastSentBody: String?

    /// 次に投げるべきエラー（nilなら成功）
    public var nextError: NotificationManagerError?

    /// 送信された通知の履歴
    public private(set) var sentNotifications: [(title: String, body: String)] = []

    // MARK: - 初期化

    public init() {}

    // MARK: - モックメソッド

    /// 通知を送信（モック実装）
    public func send(title: String, body: String) async throws {
        sendCallCount += 1
        lastSentTitle = title
        lastSentBody = body
        sentNotifications.append((title: title, body: body))

        if let error = nextError {
            throw error
        }
    }

    // MARK: - テストヘルパー

    /// 通知履歴をリセット
    public func reset() {
        sendCallCount = 0
        lastSentTitle = nil
        lastSentBody = nil
        sentNotifications = []
        nextError = nil
    }

    /// 次の通知でエラーを投げるように設定
    public func setNextError(_ error: NotificationManagerError?) {
        nextError = error
    }
}
