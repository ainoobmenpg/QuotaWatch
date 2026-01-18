//
//  AppState.swift
//  QuotaWatch
//
//  アプリケーション実行状態（永続化対象）
//

import Foundation

/// アプリケーション実行状態（永続化対象）
public struct AppState: Codable, Sendable, Equatable {
    /// 次回フェッチ時刻（epoch秒）
    public var nextFetchEpoch: Int

    /// バックオフ係数（最小1）
    public var backoffFactor: Int

    /// 最終フェッチ時刻（epoch秒）
    public var lastFetchEpoch: Int

    /// 最終エラーメッセージ
    public var lastError: String

    /// 最終リセット時刻（検知済み、epoch秒）
    public var lastKnownResetEpoch: Int

    /// 最終通知時刻（epoch秒）
    public var lastNotifiedResetEpoch: Int

    /// デフォルト値で初期化
    public init() {
        let now = Date().epochSeconds
        self.nextFetchEpoch = now
        self.backoffFactor = 1
        self.lastFetchEpoch = 0
        self.lastError = ""
        self.lastKnownResetEpoch = 0
        self.lastNotifiedResetEpoch = 0
    }
}
