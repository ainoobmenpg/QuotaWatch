//
//  QuotaEngineEvent.swift
//  QuotaWatch
//
//  QuotaEngineからViewModelへの通知イベント
//

import Foundation

// MARK: - QuotaEngineEvent

/// QuotaEngineからViewModelへの通知イベント
///
/// AsyncStreamを通じてContentViewModelに配信され、
/// UIの自動更新をトリガーします。
public enum QuotaEngineEvent: Sendable {
    /// スナップショットが更新された
    case snapshotUpdated(UsageSnapshot)

    /// フェッチを開始した
    case fetchStarted

    /// フェッチが成功した
    case fetchSucceeded

    /// フェッチが失敗した
    case fetchFailed(String)
}
