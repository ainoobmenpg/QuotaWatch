//
//  NotificationManager.swift
//  QuotaWatch
//
//  通知管理を行うアクター
//

import Foundation
import OSLog
import UserNotifications

// MARK: - NotificationManagerError

/// NotificationManagerが発生させるエラーの型
public enum NotificationManagerError: Error, Sendable, LocalizedError {
    /// 通知権限が付与されていない
    case notAuthorized

    /// 通知の追加に失敗
    case addFailed(String)

    /// その他のエラー
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "通知権限が付与されていません"
        case .addFailed(let message):
            return "通知の追加に失敗: \(message)"
        case .unknown(let message):
            return "通知エラー: \(message)"
        }
    }
}

// MARK: - NotificationManager

/// 通知管理を行うアクター
public actor NotificationManager {
    /// シングルトンインスタンス
    public static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.quotawatch.notifications", category: "NotificationManager")

    private init() {}

    // MARK: - 公開API - 権限管理

    /// 通知権限を要求
    ///
    /// - Returns: 権限が付与された場合はtrue
    /// - Throws: NotificationManagerError
    public func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound]
        let granted = try await center.requestAuthorization(options: options)
        logger.log("通知権限要求結果: \(granted)")

        if !granted {
            throw NotificationManagerError.notAuthorized
        }

        return granted
    }

    /// 通知権限の状態を確認
    ///
    /// - Returns: 現在の認証ステータス
    public func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - 公開API - 通知送信

    /// 即時通知を送信
    ///
    /// - Parameters:
    ///   - title: 通知タイトル
    ///   - body: 通知本文
    /// - Throws: NotificationManagerError
    public func send(title: String, body: String) async throws {
        // 権限チェック
        let status = await getAuthorizationStatus()
        if status != .authorized {
            logger.error("通知権限がありません: \(status.rawValue)")
            throw NotificationManagerError.notAuthorized
        }

        // コンテンツ作成
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // iOS 15+ / macOS 12+ のみ対応
        if #available(macOS 12.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        // リクエスト作成
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 即時
        )

        // 通知追加
        do {
            try await center.add(request)
            logger.log("通知を送信: \(title)")
        } catch {
            logger.error("通知送信エラー: \(error.localizedDescription)")
            throw NotificationManagerError.addFailed(error.localizedDescription)
        }
    }

    // MARK: - テストヘルパー（DEBUGビルドのみ）

    #if DEBUG
    /// 通知権限を強制的に設定（テスト用）
    ///
    /// 注: 実際の権限は変更されません。テストダブル用です。
    public func setMockAuthorizationStatus(_ status: UNAuthorizationStatus) {
        logger.debug("モック権限ステータスを設定: \(status.rawValue)")
        // 実際には何もしない（テスト時はモックを使用）
    }
    #endif
}
