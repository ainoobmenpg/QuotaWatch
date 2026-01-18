//
//  ZaiProvider.swift
//  QuotaWatch
//
//  Z.ai API Provider実装
//

import Foundation
import OSLog

// MARK: - ZaiProvider

/// Z.ai APIのProvider実装
public struct ZaiProvider: Provider {
    private static let logger = Logger(
        subsystem: "com.quotawatch.provider",
        category: "ZaiProvider"
    )

    // MARK: - Provider Conformance

    public let id = "zai"
    public let displayName = "Z.ai"
    public let dashboardURL = URL(string: "https://z.ai")
    public let keychainService = "zai_api_key"

    // MARK: - Configuration

    private static let baseURL = "https://api.z.ai"
    private static let endpoint = "/api/monitor/usage/quota/limit"
    private static let timeout: TimeInterval = 10.0

    /// レート制限エラーコード
    private static let rateLimitErrorCodes: Set<Int> = [1302, 1303, 1305]

    public init() {}

    // MARK: - Provider Protocol

    public func fetchUsage(apiKey: String) async throws -> UsageSnapshot {
        guard let url = URL(string: Self.baseURL + Self.endpoint) else {
            Self.logger.error("無効なURL")
            throw ProviderError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = Self.timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        Self.logger.debug("フェッチ開始: \(url)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                Self.logger.error("無効なレスポンス")
                throw ProviderError.invalidResponse
            }

            Self.logger.debug("HTTPステータス: \(httpResponse.statusCode)")

            // HTTPステータスコードチェック
            if httpResponse.statusCode != 200 {
                if httpResponse.statusCode == 429 {
                    Self.logger.error("レート制限検出: HTTP 429")
                    throw ProviderError.httpError(statusCode: 429)
                }
                Self.logger.error("HTTPエラー: \(httpResponse.statusCode)")
                throw ProviderError.httpError(statusCode: httpResponse.statusCode)
            }

            // JSONデコード
            let quotaResponse = try JSONDecoder().decode(QuotaResponse.self, from: data)

            // 業務エラーチェック
            if let error = quotaResponse.error {
                Self.logger.error("業務エラー: code=\(error.code ?? 0)")
                if let code = error.code, Self.rateLimitErrorCodes.contains(code) {
                    throw ProviderError.httpError(statusCode: 429)
                }
                throw ProviderError.unauthorized
            }

            guard let quotaData = quotaResponse.data else {
                Self.logger.error("レスポンスデータがない")
                throw ProviderError.quotaNotAvailable
            }

            // デバッグ: 受信したlimitsのタイプをログ出力
            let limitTypes = quotaData.limits.map { $0.type }
            Self.logger.debug("受信したクォータタイプ: \(limitTypes)")

            // UsageSnapshotへ正規化
            guard let snapshot = UsageSnapshot(from: quotaData) else {
                Self.logger.error("プライマリクォータが見つからない。受信したタイプ: \(limitTypes)")
                throw ProviderError.quotaNotAvailable
            }

            Self.logger.log("フェッチ成功: \(snapshot.primaryTitle)")
            return snapshot

        } catch let error as ProviderError {
            throw error
        } catch let error as DecodingError {
            Self.logger.error("デコードエラー: \(error)")
            throw ProviderError.decodingError(underlying: error)
        } catch {
            Self.logger.error("ネットワークエラー: \(error)")
            throw ProviderError.networkError(underlying: error)
        }
    }

    public func classifyBackoff(error: ProviderError) -> BackoffDecision {
        switch error {
        case .httpError(let statusCode) where statusCode == 429:
            Self.logger.warning("レート制限判定: HTTP 429")
            return .backoff()

        case .networkError, .decodingError:
            Self.logger.debug("非レートエラー: 通常リトライ")
            return .proceed()

        case .unauthorized, .quotaNotAvailable, .invalidResponse:
            Self.logger.error("致命的エラー: \(error)")
            return BackoffDecision(
                action: .stop,
                isRetryable: false,
                description: error.localizedDescription
            )

        case .unknown:
            return .proceed()

        default:
            return .proceed()
        }
    }
}
