//
//  AppState.swift
//  QuotaWatch
//
//  アプリケーション実行状態（永続化対象）
//

import Foundation

// MARK: - FetchState

/// フェッチ関連の状態
public struct FetchState: Codable, Sendable, Equatable {
    /// 次回フェッチ時刻（epoch秒）
    public var nextFetchEpoch: Int

    /// バックオフ係数（最小1）
    public var backoffFactor: Int

    /// 最終フェッチ時刻（epoch秒）
    public var lastFetchEpoch: Int

    /// 最終エラーメッセージ
    public var lastError: String

    /// 連続失敗カウンター
    public var consecutiveFailureCount: Int

    /// デフォルト値で初期化
    public init() {
        let now = Date().epochSeconds
        self.nextFetchEpoch = now
        self.backoffFactor = 1
        self.lastFetchEpoch = 0
        self.lastError = ""
        self.consecutiveFailureCount = 0
    }

    /// 値を指定して初期化（テスト用）
    public init(
        nextFetchEpoch: Int,
        backoffFactor: Int,
        lastFetchEpoch: Int,
        lastError: String,
        consecutiveFailureCount: Int
    ) {
        self.nextFetchEpoch = nextFetchEpoch
        self.backoffFactor = backoffFactor
        self.lastFetchEpoch = lastFetchEpoch
        self.lastError = lastError
        self.consecutiveFailureCount = consecutiveFailureCount
    }
}

// MARK: - NotificationState

/// 通知関連の状態
public struct NotificationState: Codable, Sendable, Equatable {
    /// 最終リセット時刻（検知済み、epoch秒）
    public var lastKnownResetEpoch: Int

    /// 最終通知時刻（epoch秒）
    public var lastNotifiedResetEpoch: Int

    /// デフォルト値で初期化
    public init() {
        self.lastKnownResetEpoch = 0
        self.lastNotifiedResetEpoch = 0
    }

    /// 値を指定して初期化（テスト用）
    public init(
        lastKnownResetEpoch: Int,
        lastNotifiedResetEpoch: Int
    ) {
        self.lastKnownResetEpoch = lastKnownResetEpoch
        self.lastNotifiedResetEpoch = lastNotifiedResetEpoch
    }
}

// MARK: - AppState

/// アプリケーション実行状態（永続化対象）
///
/// 機能別に分割された状態を統合します。
public struct AppState: Codable, Sendable, Equatable {
    /// フェッチ関連の状態
    public var fetch: FetchState

    /// 通知関連の状態
    public var notification: NotificationState

    /// デフォルト値で初期化
    public init() {
        self.fetch = FetchState()
        self.notification = NotificationState()
    }

    /// 値を指定して初期化（テスト用）
    public init(
        fetch: FetchState,
        notification: NotificationState
    ) {
        self.fetch = fetch
        self.notification = notification
    }

    /// 互換性イニシャライザ（既存コード用）
    public init(
        nextFetchEpoch: Int,
        backoffFactor: Int,
        lastFetchEpoch: Int,
        lastError: String,
        lastKnownResetEpoch: Int,
        lastNotifiedResetEpoch: Int,
        consecutiveFailureCount: Int
    ) {
        self.fetch = FetchState(
            nextFetchEpoch: nextFetchEpoch,
            backoffFactor: backoffFactor,
            lastFetchEpoch: lastFetchEpoch,
            lastError: lastError,
            consecutiveFailureCount: consecutiveFailureCount
        )
        self.notification = NotificationState(
            lastKnownResetEpoch: lastKnownResetEpoch,
            lastNotifiedResetEpoch: lastNotifiedResetEpoch
        )
    }

    // MARK: - 互換性プロパティ（移行期間用）

    /// 次回フェッチ時刻（epoch秒）[互換性]
    public var nextFetchEpoch: Int {
        get { fetch.nextFetchEpoch }
        set { fetch.nextFetchEpoch = newValue }
    }

    /// バックオフ係数（最小1）[互換性]
    public var backoffFactor: Int {
        get { fetch.backoffFactor }
        set { fetch.backoffFactor = newValue }
    }

    /// 最終フェッチ時刻（epoch秒）[互換性]
    public var lastFetchEpoch: Int {
        get { fetch.lastFetchEpoch }
        set { fetch.lastFetchEpoch = newValue }
    }

    /// 最終エラーメッセージ [互換性]
    public var lastError: String {
        get { fetch.lastError }
        set { fetch.lastError = newValue }
    }

    /// 最終リセット時刻（検知済み、epoch秒）[互換性]
    public var lastKnownResetEpoch: Int {
        get { notification.lastKnownResetEpoch }
        set { notification.lastKnownResetEpoch = newValue }
    }

    /// 最終通知時刻（epoch秒）[互換性]
    public var lastNotifiedResetEpoch: Int {
        get { notification.lastNotifiedResetEpoch }
        set { notification.lastNotifiedResetEpoch = newValue }
    }

    /// 連続失敗カウンター [互換性]
    public var consecutiveFailureCount: Int {
        get { fetch.consecutiveFailureCount }
        set { fetch.consecutiveFailureCount = newValue }
    }
}
