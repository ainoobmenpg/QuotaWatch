//
//  Provider.swift
//  QuotaWatch
//
//  Providerプロトコルの定義
//

import Foundation

// MARK: - Provider Protocol

/// クォータ情報を提供するProviderの抽象プロトコル
public protocol Provider: Sendable {
    /// プロバイダ識別子（例: "zai"）
    var id: String { get }

    /// 表示名（例: "Z.ai"）
    var displayName: String { get }

    /// ダッシュボードURL（任意）
    var dashboardURL: URL? { get }

    /// Keychainサービス名
    var keychainService: String { get }

    /// クォータ情報をフェッチ
    ///
    /// - Parameter apiKey: APIキー
    /// - Returns: 正規化された使用状況スナップショット
    /// - Throws: ProviderError
    func fetchUsage(apiKey: String) async throws -> UsageSnapshot

    /// エラーをバックオフ判定に分類
    ///
    /// - Parameter error: 発生したエラー
    /// - Returns: バックオフ判定結果
    func classifyBackoff(error: ProviderError) -> BackoffDecision
}

// MARK: - Provider Factory

/// Provider生成工厂
public enum ProviderFactory {
    /// ProviderIdに基づいてProviderを生成
    ///
    /// - Parameter providerId: プロバイダーID
    /// - Returns: Providerインスタンス
    public static func create(providerId: ProviderId) -> any Provider {
        switch providerId {
        case .zai:
            return ZaiProvider()
        case .minimax:
            return MiniMaxProvider()
        }
    }
}
