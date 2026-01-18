//
//  ProviderError.swift
//  QuotaWatch
//
//  Providerレイヤーのエラー型定義
//

import Foundation

// MARK: - ProviderError

/// Providerが発生させるエラーの型
public enum ProviderError: Error, Sendable, LocalizedError {
    /// ネットワークエラー（接続失敗、タイムアウト等）
    case networkError(underlying: Error)

    /// HTTPエラー（ステータスコード付き）
    case httpError(statusCode: Int)

    /// レスポンスのデコードエラー
    case decodingError(underlying: Error)

    /// 無効なレスポンス形式
    case invalidResponse

    /// 認証失敗（APIキー無効等）
    case unauthorized

    /// クォータ情報が利用不可
    case quotaNotAvailable

    /// 未知のエラー
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTPエラー (ステータス: \(code))"
        case .decodingError:
            return "レスポンスのデコードに失敗"
        case .invalidResponse:
            return "無効なレスポンス"
        case .unauthorized:
            return "認証に失敗"
        case .quotaNotAvailable:
            return "クォータ情報が利用不可"
        case .unknown(let error):
            return "未知のエラー: \(error.localizedDescription)"
        }
    }
}
