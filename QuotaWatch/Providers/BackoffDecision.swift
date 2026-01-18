//
//  BackoffDecision.swift
//  QuotaWatch
//
//  バックオフ判定結果の型定義
//

import Foundation

// MARK: - BackoffDecision

/// エラーに対するバックオフ判定結果
public struct BackoffDecision: Sendable, Equatable {
    /// 実行アクション
    public enum Action: Sendable, Equatable {
        /// 通常リトライ（次回スケジュールで実行）
        case proceed

        /// バックオフ待機
        case backoff(wait: TimeInterval)

        /// 停止（再試行なし）
        case stop
    }

    /// 実行アクション
    public let action: Action

    /// 再試行可能かどうか
    public let isRetryable: Bool

    /// 判定の説明（ログ用）
    public let description: String

    public init(action: Action, isRetryable: Bool, description: String) {
        self.action = action
        self.isRetryable = isRetryable
        self.description = description
    }

    /// 通常リトライ判定を生成
    public static func proceed() -> Self {
        BackoffDecision(
            action: .proceed,
            isRetryable: true,
            description: "通常リトライ"
        )
    }

    /// バックオフ判定を生成
    ///
    /// - Parameters:
    ///   - factor: バックオフ係数（1, 2, 4, 8...）
    ///   - baseInterval: 基本間隔（秒）
    /// - Returns: バックオフ判定（最大15分 + ジッター）
    public static func backoff(factor: Int, baseInterval: TimeInterval) -> Self {
        let wait = baseInterval * Double(factor)
        let cappedWait = min(wait, 900)  // MAX_BACKOFF_SECONDS = 15分
        let jitter = Double.random(in: 0...15)
        let totalWait = cappedWait + jitter
        return BackoffDecision(
            action: .backoff(wait: totalWait),
            isRetryable: true,
            description: "バックオフ中 (factor=\(factor), wait=\(Int(totalWait))秒)"
        )
    }

    /// 即時実行判定を生成
    public static let immediate = BackoffDecision(
        action: .proceed,
        isRetryable: true,
        description: "即時実行"
    )
}
