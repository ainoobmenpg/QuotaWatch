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

        /// バックオフ待機（詳細はQuotaEngineで計算）
        case backoff

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
    /// バックオフ計算はQuotaEngineの責務とし、Providerはエラー分類のみを行います。
    ///
    /// - Returns: バックオフ判定（QuotaEngineで間隔を計算）
    public static func backoff() -> Self {
        return BackoffDecision(
            action: .backoff,
            isRetryable: true,
            description: "バックオフ中"
        )
    }

    /// 即時実行判定を生成
    public static let immediate = BackoffDecision(
        action: .proceed,
        isRetryable: true,
        description: "即時実行"
    )
}
