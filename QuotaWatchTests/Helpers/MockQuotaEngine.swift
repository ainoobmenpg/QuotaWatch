//
//  MockQuotaEngine.swift
//  QuotaWatchTests
//
//  テスト用Mock QuotaEngine
//

import Foundation
@testable import QuotaWatch

/// テスト用のMock QuotaEngine（actor）
///
/// QuotaEngineProtocolに準拠し、テスト容易性を提供します。
///
/// ## Actorプロトコルメソッドのsync/async挙動について
///
/// Swift 6では、Actorに準拠するプロトコルのメソッドは、
/// プロトコル側で`async`が指定されていない場合でも、
/// actor隔離により呼び出し時に`await`が必要になります。
///
/// 例えば、QuotaEngineProtocolで以下のように定義されているメソッド:
/// ```swift
/// func getCurrentSnapshot() -> UsageSnapshot?
/// func getState() -> AppState
/// ```
///
/// これらは非同期メソッドとして定義されていませんが、
/// actor準拠のため呼び出し時には`await`が必要です:
/// ```swift
/// let snapshot = await mockEngine.getCurrentSnapshot()
/// let state = await mockEngine.getState()
/// ```
///
/// この挙動はSwift 6の同時実行性モデルによるもので、
/// actorのデータ保護を保証するために設計されています。
///
/// ## テストヘルパー
///
/// テスト容易性のため、以下のヘルパーメソッドを提供します:
/// - `setSnapshot(_:)` - スナップショットを設定し、イベントを送信
/// - `yieldEvent(_:)` - 任意のイベントを送信
/// - `setForceFetchError(_:)` - forceFetch時のエラーを設定
/// - `updateMockState(...)` - モック状態を更新
public actor MockQuotaEngine: QuotaEngineProtocol {
    // MARK: - テスト状態

    /// 返却するスナップショット
    public private(set) var mockSnapshot: UsageSnapshot?

    /// 返却するアプリ状態
    public private(set) var mockAppState: AppState

    /// forceFetchが呼ばれた回数
    public private(set) var forceFetchCallCount = 0

    /// forceFetchで投げるべきエラー（nilなら成功）
    public private(set) var forceFetchError: Error?

    /// runLoopが開始されたか
    public private(set) var isRunLoopStarted = false

    /// runLoopが停止されたか
    public private(set) var isRunLoopStopped = false

    /// 基本フェッチ間隔
    public private(set) var baseInterval: TimeInterval = 60.0

    /// イベントストリーム
    private let eventStream: AsyncStream<QuotaEngineEvent>

    /// イベントストリームの継続
    public private(set) var eventContinuation: AsyncStream<QuotaEngineEvent>.Continuation?

    /// デバッグログ内容
    public private(set) var debugLogContents: String = ""

    // MARK: - 初期化

    public init(
        mockSnapshot: UsageSnapshot? = nil,
        mockAppState: AppState = AppState()
    ) {
        self.mockSnapshot = mockSnapshot
        self.mockAppState = mockAppState

        // AsyncStreamを作成
        var stream: AsyncStream<QuotaEngineEvent>?
        var cont: AsyncStream<QuotaEngineEvent>.Continuation?
        stream = AsyncStream<QuotaEngineEvent> { continuation in
            cont = continuation
        }
        self.eventStream = stream!
        self.eventContinuation = cont
    }

    // MARK: - QuotaEngineProtocol準拠

    public func getCurrentSnapshot() -> UsageSnapshot? {
        return mockSnapshot
    }

    public func getEventStream() -> AsyncStream<QuotaEngineEvent> {
        return eventStream
    }

    public func getState() -> AppState {
        return mockAppState
    }

    public func getNextFetchEpoch() -> Int {
        return mockAppState.nextFetchEpoch
    }

    public func shouldFetch() -> Bool {
        let now = Date().epochSeconds
        return now >= mockAppState.nextFetchEpoch
    }

    public func fetchIfDue() async throws -> UsageSnapshot {
        if shouldFetch() {
            return try await performFetch()
        }
        guard let snapshot = mockSnapshot else {
            throw QuotaEngineError.noCachedData
        }
        return snapshot
    }

    public func forceFetch() async throws -> UsageSnapshot {
        forceFetchCallCount += 1
        if let error = forceFetchError {
            throw error
        }
        return try await performFetch()
    }

    public func setBaseInterval(_ interval: TimeInterval) {
        self.baseInterval = interval
    }

    public func startRunLoop() {
        isRunLoopStarted = true
    }

    public func stopRunLoop() async {
        isRunLoopStopped = true
    }

    public func handleWakeFromSleep() async {
        // モックでは何もしない
    }

    // MARK: - ヘルパー

    /// モック状態を更新
    public func updateMockState(
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

    /// スナップショットを設定し、イベントを送信
    public func setSnapshot(_ snapshot: UsageSnapshot) {
        self.mockSnapshot = snapshot
        eventContinuation?.yield(.snapshotUpdated(snapshot))
    }

    /// イベントを送信
    public func yieldEvent(_ event: QuotaEngineEvent) {
        eventContinuation?.yield(event)
    }

    /// forceFetchで投げるべきエラーを設定（テストヘルパー）
    public func setForceFetchError(_ error: Error?) {
        self.forceFetchError = error
    }

    /// フェッチを実行（内部ヘルパー）
    private func performFetch() async throws -> UsageSnapshot {
        if let error = forceFetchError {
            throw error
        }
        eventContinuation?.yield(.fetchSucceeded)
        guard let snapshot = mockSnapshot else {
            throw QuotaEngineError.noCachedData
        }
        return snapshot
    }
}

// MARK: - QuotaEngineDebugProtocol準拠（DEBUGビルドのみ）

#if DEBUG
extension MockQuotaEngine: QuotaEngineDebugProtocol {
    public func overrideNextFetchEpoch(_ epoch: Int) {
        mockAppState.nextFetchEpoch = epoch
    }

    public func getDebugLogContents() async -> String {
        return debugLogContents
    }

    public func clearDebugLog() async {
        debugLogContents = ""
    }
}
#endif
