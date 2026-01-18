//
//  MockProvider.swift
//  QuotaWatchTests
//
//  テスト用のモックプロバイダー
//

import Foundation
@testable import QuotaWatch

/// テスト用のモックプロバイダー
///
/// エラー挙動やフェッチ遅延を制御できる共通モック実装です。
public final class MockProvider: @unchecked Sendable, Provider {
    public let id = "mock"
    public let displayName = "Mock"
    public let dashboardURL: URL? = URL(string: "https://mock.example.com")
    public let keychainService = "mock_api_key"

    // MARK: - 挙動制御プロパティ

    /// エラー挙動を制御するプロパティ（@unchecked Sendableで安全性は呼び出し元が保証）
    public private(set) var fetchCount = 0
    public var shouldThrowRateLimit = false
    public var shouldThrowNetworkError = false
    public var fetchDelay: TimeInterval? = nil

    // MARK: - Providerプロトコル実装

    public func fetchUsage(apiKey: String) async throws -> UsageSnapshot {
        fetchCount += 1

        // フェッチ遅延をシミュレート
        if let delay = fetchDelay {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if shouldThrowRateLimit {
            throw ProviderError.httpError(statusCode: 429)
        }
        if shouldThrowNetworkError {
            throw ProviderError.networkError(underlying: NSError(domain: "test", code: -1))
        }

        // 成功時はダミーのスナップショットを返す
        return UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: Int(Date().timeIntervalSince1970),
            primaryTitle: "Mock Quota",
            primaryPct: 50,
            primaryUsed: 50.0,
            primaryTotal: 100.0,
            primaryRemaining: 50.0,
            resetEpoch: nil,
            secondary: [],
            rawDebugJson: nil
        )
    }

    public func classifyBackoff(error: ProviderError) -> BackoffDecision {
        switch error {
        case .httpError(let statusCode) where statusCode == 429:
            return .backoff()
        case .networkError:
            return .proceed()
        default:
            return .proceed()
        }
    }

    // MARK: - テストヘルパーメソッド

    /// レート制限エラーを発生させるかどうかを設定
    public func setShouldThrowRateLimit(_ value: Bool) {
        shouldThrowRateLimit = value
    }

    /// ネットワークエラーを発生させるかどうかを設定
    public func setShouldThrowNetworkError(_ value: Bool) {
        shouldThrowNetworkError = value
    }

    /// フェッチ遅延を設定（秒単位）
    public func setFetchDelay(_ seconds: TimeInterval?) {
        fetchDelay = seconds
    }

    /// フェッチカウンターをリセット
    public func resetFetchCount() {
        fetchCount = 0
    }
}
