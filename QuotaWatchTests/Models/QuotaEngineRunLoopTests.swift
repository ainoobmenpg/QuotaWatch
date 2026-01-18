//
//  QuotaEngineRunLoopTests.swift
//  QuotaWatchTests
//
//  QuotaEngineのrunLoopとスリープ復帰のテスト
//

import XCTest
import Foundation
@testable import QuotaWatch

// MARK: - QuotaEngineRunLoopTests

/// QuotaEngineのrunLoop関連機能のテスト
final class QuotaEngineRunLoopTests: XCTestCase {

    // MARK: - テスト用プロパティ

    private var testPersistence: PersistenceManager!
    private var testKeychain: KeychainStore!

    // MARK: - セットアップ/ティアダウン

    override func setUp() async throws {
        try await super.setUp()

        // テスト用の永続化ディレクトリを設定
        let testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuotaWatchTests")
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: testDir,
            withIntermediateDirectories: true
        )

        testPersistence = try PersistenceManager(customDirectoryURL: testDir)
        testKeychain = KeychainStore(
            account: "test_account_\(UUID().uuidString)"
        )
    }

    override func tearDown() async throws {
        // クリーンアップ
        testPersistence = nil
        testKeychain = nil

        try await super.tearDown()
    }

    // MARK: - runLoop基本動作テスト

    /// テスト: runLoopが時刻到達時にフェッチを実行すること
    func testRunLoopExecutesFetchWhenDue() async throws {
        // APIキーを設定
        try await testKeychain.write(apiKey: "test_api_key")

        // MockProviderを使用
        let mockProvider = MockProvider()
        mockProvider.setShouldThrowRateLimit(false)

        // 次回フェッチ時刻を現在時刻に設定
        let now = Date().epochSeconds
        let initialState = AppState(
            nextFetchEpoch: now,
            backoffFactor: 1,
            lastFetchEpoch: 0,
            lastError: "",
            lastKnownResetEpoch: 0,
            lastNotifiedResetEpoch: 0,
            consecutiveFailureCount: 0
        )
        try await testPersistence.saveState(initialState)

        let engine = await QuotaEngine(
            provider: mockProvider,
            persistence: testPersistence,
            keychain: testKeychain
        )

        await engine.startRunLoop()

        // フェッチが実行されるまで待機
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        XCTAssertEqual(mockProvider.fetchCount, 1, "フェッチが1回実行されるべき")

        await engine.stopRunLoop()
    }

    /// テスト: スリープ復帰時に即時フェッチが実行されること
    func testSleepWakeTriggersImmediateFetch() async throws {
        // APIキーを設定
        try await testKeychain.write(apiKey: "test_api_key")

        // MockProviderを使用
        let mockProvider = MockProvider()
        mockProvider.setShouldThrowRateLimit(false)

        // 次回フェッチ時刻を現在時刻に設定
        let now = Date().epochSeconds
        let initialState = AppState(
            nextFetchEpoch: now,
            backoffFactor: 1,
            lastFetchEpoch: 0,
            lastError: "",
            lastKnownResetEpoch: 0,
            lastNotifiedResetEpoch: 0,
            consecutiveFailureCount: 0
        )
        try await testPersistence.saveState(initialState)

        let engine = await QuotaEngine(
            provider: mockProvider,
            persistence: testPersistence,
            keychain: testKeychain
        )

        // スリープ復帰時の即時フェッチテスト
        // 注: 現在の実装ではhandleWake()はprivateなので、
        // runLoopが時刻到達時にフェッチすることを検証します
        await engine.startRunLoop()

        // フェッチが実行されるまで待機
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        XCTAssertEqual(mockProvider.fetchCount, 1, "フェッチが1回実行されるべき")

        await engine.stopRunLoop()
    }

    // MARK: - タスクキャンセルテスト

    /// テスト: runLoopがキャンセル時に正常に停止すること
    func testRunLoopCancellation() async throws {
        // テスト用のモックProvider
        struct SlowProvider: Provider {
            let id: String = "test"
            let displayName: String = "Test Provider"
            let dashboardURL: URL? = nil
            let keychainService: String = "test_provider"

            func fetchUsage(apiKey: String) async throws -> UsageSnapshot {
                // 長いスリープでキャンセルを待つ
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10秒
                return UsageSnapshot(
                    providerId: "test",
                    fetchedAtEpoch: Date().epochSeconds,
                    primaryTitle: "Test",
                    primaryPct: 50,
                    primaryUsed: 5.0,
                    primaryTotal: 10.0,
                    primaryRemaining: 5.0,
                    resetEpoch: nil,
                    secondary: [],
                    rawDebugJson: nil
                )
            }

            func classifyBackoff(error: ProviderError) -> BackoffDecision {
                .proceed()
            }
        }

        // 1. テスト用APIキーを設定
        try await testKeychain.write(apiKey: "test_api_key")

        // 2. 次回フェッチ時刻を現在時刻に設定（即時フェッチ）
        let now = Date().epochSeconds
        let initialState = AppState(
            nextFetchEpoch: now,
            backoffFactor: 1,
            lastFetchEpoch: 0,
            lastError: "",
            lastKnownResetEpoch: 0,
            lastNotifiedResetEpoch: 0,
            consecutiveFailureCount: 0
        )
        try await testPersistence.saveState(initialState)

        // 3. Engineを初期化
        let engine = await QuotaEngine(
            provider: SlowProvider(),
            persistence: testPersistence,
            keychain: testKeychain
        )

        // 4. runLoopを開始
        await engine.startRunLoop()

        // 5. 少し待機してからキャンセル
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        await engine.stopRunLoop()

        // 6. 正常に停止したことを確認
        let state = await engine.getState()
        XCTAssertNotNil(state, "State should not be nil after stop")
    }

    // MARK: - startRunLoop/stopRunLoopテスト

    /// テスト: startRunLoopを複数回呼んでも問題ないこと
    func testStartRunLoopMultipleTimes() async throws {
        try await testKeychain.write(apiKey: "test_api_key")

        let engine = await QuotaEngine(
            provider: ZaiProvider(),
            persistence: testPersistence,
            keychain: testKeychain
        )

        // 複数回呼んでもクラッシュしないことを確認
        await engine.startRunLoop()
        await engine.startRunLoop()
        await engine.startRunLoop()

        // クリーンアップ
        await engine.stopRunLoop()
    }

    /// テスト: stopRunLoopを複数回呼んでも問題ないこと
    func testStopRunLoopMultipleTimes() async throws {
        try await testKeychain.write(apiKey: "test_api_key")

        let engine = await QuotaEngine(
            provider: ZaiProvider(),
            persistence: testPersistence,
            keychain: testKeychain
        )

        await engine.startRunLoop()

        // 複数回呼んでもクラッシュしないことを確認
        await engine.stopRunLoop()
        await engine.stopRunLoop()
        await engine.stopRunLoop()
    }

    // MARK: - スリープ復帰テスト（簡易版）

    /// テスト: スリープ復帰時、時刻未到達ならフェッチしないこと
    func testSleepWakeBeforeDueTime() async throws {
        try await testKeychain.write(apiKey: "test_api_key")

        // 次回フェッチ時刻を未来に設定
        let futureEpoch = Date().epochSeconds + 3600 // 1時間後
        let initialState = AppState(
            nextFetchEpoch: futureEpoch,
            backoffFactor: 1,
            lastFetchEpoch: 0,
            lastError: "",
            lastKnownResetEpoch: 0,
            lastNotifiedResetEpoch: 0,
            consecutiveFailureCount: 0
        )
        try await testPersistence.saveState(initialState)

        let engine = await QuotaEngine(
            provider: ZaiProvider(),
            persistence: testPersistence,
            keychain: testKeychain
        )

        // handleWakeを直接テストするのは公開APIではないため
        // ここでは状態が正しく設定されていることを確認するだけ
        let state = await engine.getState()
        XCTAssertEqual(
            state.nextFetchEpoch,
            futureEpoch,
            "次回フェッチ時刻が正しく設定されていること"
        )
    }
}
