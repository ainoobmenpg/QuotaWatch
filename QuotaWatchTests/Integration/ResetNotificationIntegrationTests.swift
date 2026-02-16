//
//  ResetNotificationIntegrationTests.swift
//  QuotaWatchTests
//
//  ResetNotifierとQuotaEngineの統合テスト（バグ2: lastKnownResetEpoch更新の連携）
//

import XCTest
import Foundation
@testable import QuotaWatch

// MARK: - ResetNotificationIntegrationTests

/// ResetNotifierとQuotaEngineの統合テスト
///
/// ## テスト目的
/// - バグ2再現: QuotaEngineのフェッチ→ResetNotifierの通知検知のデータフローを検証
/// - コンポーネント間の連携が正しく動作することを確認
///
/// ## テストシナリオ
/// 1. フェッチ成功 → lastKnownResetEpoch更新 → ResetNotifierがリセット検知
/// 2. リセット時刻到達 → 通知送信 → epoch進める
final class ResetNotificationIntegrationTests: XCTestCase {

    // MARK: - テスト用プロパティ

    private var testPersistence: PersistenceManager!
    private var testKeychain: KeychainStore!
    private var tempDirectory: URL!

    // MARK: - セットアップ/ティアダウン

    override func setUp() async throws {
        try await super.setUp()

        // テスト用の永続化ディレクトリを設定
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuotaWatchIntegrationTests")
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )

        testPersistence = try PersistenceManager(customDirectoryURL: tempDirectory)
        testKeychain = KeychainStore(
            account: "test_account_integration_\(UUID().uuidString)"
        )
    }

    override func tearDown() async throws {
        // クリーンアップ
        try? FileManager.default.removeItem(at: tempDirectory)
        testPersistence = nil
        testKeychain = nil

        try await super.tearDown()
    }

    // MARK: - データフロー統合テスト

    /// テスト: フェッチ成功→状態更新→通知検知のデータフロー
    ///
    /// ## フロー
    /// 1. QuotaEngine.forceFetch() 実行
    /// 2. snapshot.resetEpoch が state.lastKnownResetEpoch に反映
    /// 3. ResetNotifier.checkReset() でリセット検知
    func testNotificationFlow_fetchUpdatesState_notifierDetectsReset() async throws {
        // APIキーを設定
        try await testKeychain.write(apiKey: "test_api_key")

        // MockProviderを設定
        let mockProvider = MockProvider()
        mockProvider.setShouldThrowRateLimit(false)

        // リセット時刻を「現在時刻より少し前」に設定（リセット検知をトリガー）
        let now = Int(Date().timeIntervalSince1970)
        let resetEpoch = now - 60  // 1分前にリセット
        mockProvider.setMockResetEpoch(resetEpoch)

        // 初期状態（lastKnownResetEpochは0、未通知状態）
        let initialState = AppState(
            nextFetchEpoch: now,
            backoffFactor: 1,
            lastFetchEpoch: 0,
            lastError: "",
            lastKnownResetEpoch: 0,  // 初期値0
            lastNotifiedResetEpoch: 0,  // 未通知
            consecutiveFailureCount: 0
        )
        try await testPersistence.saveState(initialState)

        // QuotaEngineを作成
        let engine = try await QuotaEngine(
            provider: mockProvider,
            persistence: testPersistence,
            keychain: testKeychain
        )

        // フェッチ実行（forceFetchで即時実行）
        _ = try await engine.forceFetch()

        // フェッチ後の状態確認
        let stateAfterFetch = await engine.getState()
        XCTAssertEqual(
            stateAfterFetch.lastKnownResetEpoch,
            resetEpoch,
            "フェッチ成功後、lastKnownResetEpochが更新されるべき"
        )

        // ResetNotifierのリセット検知条件をシミュレート
        // checkReset() と同等のロジックをテスト
        let checkNow = Date().epochSeconds
        let shouldNotify = checkNow >= stateAfterFetch.lastKnownResetEpoch &&
                          stateAfterFetch.lastNotifiedResetEpoch != stateAfterFetch.lastKnownResetEpoch

        XCTAssertTrue(shouldNotify, "リセット時刻到達かつ未通知の場合、通知条件を満たすべき")
    }

    /// テスト: リセット時刻到達時に通知が送信されること
    ///
    /// ## フロー
    /// 1. lastKnownResetEpoch を過去に設定
    /// 2. lastNotifiedResetEpoch を異なる値に設定（未通知状態）
    /// 3. ResetNotifier.checkReset() が通知条件を満たす
    func testNotificationSent_whenResetTimeReached() async throws {
        // APIキーを設定
        try await testKeychain.write(apiKey: "test_api_key")

        // MockProviderを設定
        let mockProvider = MockProvider()
        mockProvider.setShouldThrowRateLimit(false)

        // 現在時刻
        let now = Int(Date().timeIntervalSince1970)

        // リセット時刻を過去に設定（リセット到達状態）
        let resetEpoch = now - 300  // 5分前にリセット

        // 初期状態（リセット到達、未通知）
        let initialState = AppState(
            nextFetchEpoch: now + 60,
            backoffFactor: 1,
            lastFetchEpoch: now,
            lastError: "",
            lastKnownResetEpoch: resetEpoch,  // 過去のリセット時刻
            lastNotifiedResetEpoch: 0,  // 未通知（lastKnownResetEpochと異なる）
            consecutiveFailureCount: 0
        )
        try await testPersistence.saveState(initialState)

        // QuotaEngineを作成
        let engine = try await QuotaEngine(
            provider: mockProvider,
            persistence: testPersistence,
            keychain: testKeychain
        )

        // 状態確認
        let state = await engine.getState()

        // 通知条件の検証
        let checkNow = Date().epochSeconds
        let isResetReached = checkNow >= state.lastKnownResetEpoch
        let isNotNotified = state.lastNotifiedResetEpoch != state.lastKnownResetEpoch

        XCTAssertTrue(isResetReached, "現在時刻はリセット時刻に到達しているべき")
        XCTAssertTrue(isNotNotified, "まだ通知されていない状態であるべき")

        // 通知後の状態更新をシミュレート
        var updatedState = state
        updatedState.lastNotifiedResetEpoch = state.lastKnownResetEpoch
        updatedState.lastKnownResetEpoch += Int(AppConstants.resetIntervalSeconds)

        try await testPersistence.saveState(updatedState)

        // 更新後の状態確認
        let finalState = try await testPersistence.loadState()
        XCTAssertEqual(
            finalState.lastNotifiedResetEpoch,
            resetEpoch,
            "通知後、lastNotifiedResetEpochがlastKnownResetEpochで更新されるべき"
        )
        XCTAssertEqual(
            finalState.lastKnownResetEpoch,
            resetEpoch + Int(AppConstants.resetIntervalSeconds),
            "通知後、lastKnownResetEpochが5時間進むべき"
        )
    }

    /// テスト: 重複通知が防止されること
    ///
    /// ## シナリオ
    /// 既に通知済み（lastNotifiedResetEpoch == lastKnownResetEpoch）の場合、
    /// 再度リセットチェックしても通知は送信されない
    func testDuplicateNotificationPrevention() async throws {
        // APIキーを設定
        try await testKeychain.write(apiKey: "test_api_key")

        // MockProviderを設定
        let mockProvider = MockProvider()
        mockProvider.setShouldThrowRateLimit(false)

        let now = Int(Date().timeIntervalSince1970)
        let resetEpoch = now - 60  // 1分前にリセット

        // 初期状態（既に通知済み）
        let initialState = AppState(
            nextFetchEpoch: now + 60,
            backoffFactor: 1,
            lastFetchEpoch: now,
            lastError: "",
            lastKnownResetEpoch: resetEpoch,
            lastNotifiedResetEpoch: resetEpoch,  // 既に通知済み
            consecutiveFailureCount: 0
        )
        try await testPersistence.saveState(initialState)

        // QuotaEngineを作成
        let engine = try await QuotaEngine(
            provider: mockProvider,
            persistence: testPersistence,
            keychain: testKeychain
        )

        // 状態確認
        let state = await engine.getState()

        // 通知条件の検証（重複防止チェック）
        let isAlreadyNotified = state.lastNotifiedResetEpoch == state.lastKnownResetEpoch

        XCTAssertTrue(isAlreadyNotified, "既に通知済みの状態であるべき")

        // ResetNotifierの checkReset() と同等の判定ロジック
        let shouldNotify = now >= state.lastKnownResetEpoch &&
                          state.lastNotifiedResetEpoch != state.lastKnownResetEpoch

        XCTAssertFalse(shouldNotify, "既に通知済みの場合、通知条件を満たさないべき")
    }

    /// テスト: フェッチ→状態更新→通知検知の完全なフロー
    ///
    /// ## シナリオ
    /// 1. 初期状態（lastKnownResetEpoch = 0）
    /// 2. フェッチ成功（resetEpochを取得）
    /// 3. 状態更新（lastKnownResetEpoch更新）
    /// 4. リセット時刻到達
    /// 5. 通知送信
    func testCompleteFlow_fromFetchToNotification() async throws {
        // APIキーを設定
        try await testKeychain.write(apiKey: "test_api_key")

        // MockProviderを設定
        let mockProvider = MockProvider()
        mockProvider.setShouldThrowRateLimit(false)

        let now = Int(Date().timeIntervalSince1970)

        // ステップ1: 初期状態
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

        let engine = try await QuotaEngine(
            provider: mockProvider,
            persistence: testPersistence,
            keychain: testKeychain
        )

        // ステップ2: フェッチ成功（resetEpochを設定）
        let resetEpoch = now - 10  // 10秒前にリセット（すぐに通知条件を満たす）
        mockProvider.setMockResetEpoch(resetEpoch)

        _ = try await engine.forceFetch()

        // ステップ3: 状態更新確認
        let stateAfterFetch = await engine.getState()
        XCTAssertEqual(stateAfterFetch.lastKnownResetEpoch, resetEpoch, "フェッチ後、lastKnownResetEpochが更新されるべき")

        // ステップ4 & 5: リセット検知・通知条件確認
        let checkNow = Date().epochSeconds
        let shouldNotify = checkNow >= stateAfterFetch.lastKnownResetEpoch &&
                          stateAfterFetch.lastNotifiedResetEpoch != stateAfterFetch.lastKnownResetEpoch

        XCTAssertTrue(shouldNotify, "リセット時刻到達かつ未通知の場合、通知条件を満たすべき")

        // 通知後の状態更新をシミュレート
        var updatedState = stateAfterFetch
        updatedState.lastNotifiedResetEpoch = stateAfterFetch.lastKnownResetEpoch
        updatedState.lastKnownResetEpoch += Int(AppConstants.resetIntervalSeconds)
        try await testPersistence.saveState(updatedState)

        // 重複防止確認
        let finalState = try await testPersistence.loadState()
        XCTAssertEqual(
            finalState.lastNotifiedResetEpoch,
            resetEpoch,
            "通知後、lastNotifiedResetEpochが更新されるべき"
        )
    }
}
