//
//  MockQuotaEngine.swift
//  QuotaWatchTests
//
//  テスト用Mock QuotaEngine
//

import Foundation
@testable import QuotaWatch

/// テスト用のMock QuotaEngine（actor）
actor MockQuotaEngine: QuotaEngineProtocol {
    // MARK: - テスト状態

    /// 返却するスナップショット
    var mockSnapshot: UsageSnapshot?

    /// 返却するアプリ状態
    var mockAppState: AppState

    /// forceFetchが呼ばれた回数
    var forceFetchCallCount = 0

    /// forceFetchで投げるべきエラー（nilなら成功）
    var forceFetchError: Error?

    /// runLoopが開始されたか
    var isRunLoopStarted = false

    // MARK: - 初期化

    init(
        mockSnapshot: UsageSnapshot? = nil,
        mockAppState: AppState = AppState()
    ) {
        self.mockSnapshot = mockSnapshot
        self.mockAppState = mockAppState
    }

    // MARK: - QuotaEngineProtocol準拠

    func getCurrentSnapshot() async -> UsageSnapshot? {
        return mockSnapshot
    }

    func getState() async -> AppState {
        return mockAppState
    }

    func forceFetch() async throws -> UsageSnapshot {
        forceFetchCallCount += 1
        if let error = forceFetchError {
            throw error
        }
        return mockSnapshot ?? createMockSnapshot()
    }

    func startRunLoop() async {
        isRunLoopStarted = true
    }

    // MARK: - ヘルパー

    /// モック用スナップショットを作成
    private func createMockSnapshot() -> UsageSnapshot {
        return UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: Date().epochSeconds,
            primaryTitle: "Test Quota",
            primaryPct: 50,
            primaryUsed: 500.0,
            primaryTotal: 1000.0,
            primaryRemaining: 500.0,
            resetEpoch: Date().epochSeconds + 3600,
            secondary: [],
            rawDebugJson: nil
        )
    }

    /// モック状態を更新
    func updateMockState(
        nextFetchEpoch: Int? = nil,
        backoffFactor: Int? = nil,
        lastFetchEpoch: Int? = nil,
        consecutiveFailureCount: Int? = nil,
        lastError: String = "",
        lastKnownResetEpoch: Int? = nil,
        lastNotifiedResetEpoch: Int? = nil
    ) {
        if let nextFetch = nextFetchEpoch {
            mockAppState.nextFetchEpoch = nextFetch
        }
        if let backoff = backoffFactor {
            mockAppState.backoffFactor = backoff
        }
        if let lastFetch = lastFetchEpoch {
            mockAppState.lastFetchEpoch = lastFetch
        }
        if let failures = consecutiveFailureCount {
            mockAppState.consecutiveFailureCount = failures
        }
        if let lastKnown = lastKnownResetEpoch {
            mockAppState.lastKnownResetEpoch = lastKnown
        }
        if let lastNotified = lastNotifiedResetEpoch {
            mockAppState.lastNotifiedResetEpoch = lastNotified
        }
        mockAppState.lastError = lastError
    }
}

// MARK: - QuotaEngineProtocol

/// QuotaEngineのプロトコル（テスト用）
protocol QuotaEngineProtocol {
    func getCurrentSnapshot() async -> UsageSnapshot?
    func getState() async -> AppState
    func forceFetch() async throws -> UsageSnapshot
    func startRunLoop() async
}
