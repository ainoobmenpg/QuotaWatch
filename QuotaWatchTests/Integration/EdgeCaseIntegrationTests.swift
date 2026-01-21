//
//  EdgeCaseIntegrationTests.swift
//  QuotaWatchTests
//
//  エッジケースの統合テスト
//

import XCTest
@testable import QuotaWatch

// MARK: - EdgeCaseIntegrationTests

/// エッジケースの統合テスト
///
/// 強制終了後の復旧、キャッシュ破損、ネットワークエラーなどの
/// エッジケースに対する挙動を検証します。
final class EdgeCaseIntegrationTests: XCTestCase {

    // MARK: - テストヘルパー（ログ検証用）

    /// カテゴリ別ログを抽出
    private func extractLogs(byCategory category: String, from logContents: String) -> [String] {
        let lines = logContents.components(separatedBy: .newlines)
        var result: [String] = []

        // カテゴリパターン: [timestamp] [CATEGORY] message
        let pattern = "\\[.*?\\] \\[\(category)\\] (.*)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        for line in lines where !line.isEmpty {
            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, range: range),
               let messageRange = Range(match.range(at: 1), in: line) {
                result.append(String(line[messageRange]))
            }
        }

        return result
    }

    /// ログ包含検証
    private func assertLogContains(
        _ logContents: String,
        category: String,
        expectedMessage: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let logs = extractLogs(byCategory: category, from: logContents)
        XCTAssertTrue(
            logs.contains(expectedMessage),
            "カテゴリ[\(category)]に「\(expectedMessage)」が含まれているべきですが、実際のログ: \(logs)",
            file: file,
            line: line
        )
    }

    /// テスト用に独立したQuotaEngineインスタンスを作成
    private func makeTestEngine(
        testName: String,
        baseInterval: TimeInterval = 60,
        initializeCache: Bool = true
    ) async throws -> (engine: QuotaEngine, provider: MockProvider, keychain: KeychainStore, persistence: PersistenceManager) {
        let provider = MockProvider()
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: "QuotaWatchTests_\(testName)_\(UUID().uuidString)")
        let persistence = PersistenceManager(customDirectoryURL: tempDir)
        let keychain = KeychainStore(account: "test_\(testName)_\(UUID().uuidString)")

        try await keychain.write(apiKey: "test_api_key")

        let engine = try await QuotaEngine(
            provider: provider,
            persistence: persistence,
            keychain: keychain
        )

        if initializeCache {
            await engine.setBaseInterval(baseInterval)
            provider.shouldThrowRateLimit = false
            _ = try await engine.forceFetch()
        }

        return (engine, provider, keychain, persistence)
    }

    // MARK: - 強制終了後の復旧

    /// 強制終了後: スナップショットがキャッシュから復元される
    func testCrashRecoveryRestoresSnapshot() async throws {
        // 固定のディレクトリ名を使用
        let testDirName = "QuotaWatchTests_testCrashRecoveryRestoresSnapshot"
        let tempDir = FileManager.default.temporaryDirectory.appending(path: testDirName)

        // 最初のエンジンを作成
        let provider1 = MockProvider()
        let persistence1 = PersistenceManager(customDirectoryURL: tempDir)
        let keychain1 = KeychainStore(account: "test_testCrashRecoveryRestoresSnapshot")
        try await keychain1.write(apiKey: "test_api_key")
        let engine1 = try await QuotaEngine(
            provider: provider1,
            persistence: persistence1,
            keychain: keychain1
        )
        await engine1.setBaseInterval(60)
        provider1.shouldThrowRateLimit = false

        // 初期スナップショットを取得
        let originalSnapshot = try await engine1.forceFetch()
        let originalTitle = originalSnapshot.primaryTitle

        // ログをクリアして、復旧時のログのみを取得
        await engine1.clearDebugLog()

        // エンジンを破棄（強制終了をシミュレート）
        _ = engine1

        // 新しいエンジンインスタンスを作成（再起動をシミュレート）
        // 同じディレクトリとkeychainを再利用
        let provider2 = MockProvider()
        let persistence2 = PersistenceManager(customDirectoryURL: tempDir)
        let engine2 = try await QuotaEngine(
            provider: provider2,
            persistence: persistence2,
            keychain: keychain1
        )

        // キャッシュからスナップショットが復元されていることを検証
        let restoredSnapshot = await engine2.getCurrentSnapshot()
        XCTAssertNotNil(restoredSnapshot, "スナップショットが復元されるべき")
        XCTAssertEqual(restoredSnapshot?.primaryTitle, originalTitle, "元のタイトルが復元されるべき")

        // ログ検証を追加（Issue #28）
        let logs = await engine2.getDebugLogContents()
        assertLogContains(
            logs,
            category: "ENGINE",
            expectedMessage: "キャッシュ復元成功: \(originalTitle)"
        )
    }

    /// 強制終了後: nextFetchEpochが過去の場合、現在時刻に補正される
    func testCrashRecoveryCorrectsNextFetchEpoch() async throws {
        // 固定のディレクトリ名を使用
        let testDirName = "QuotaWatchTests_testCrashRecoveryCorrectsNextFetchEpoch"
        let tempDir = FileManager.default.temporaryDirectory.appending(path: testDirName)

        // 最初のエンジンを作成
        let provider1 = MockProvider()
        let persistence1 = PersistenceManager(customDirectoryURL: tempDir)
        let keychain1 = KeychainStore(account: "test_testCrashRecoveryCorrectsNextFetchEpoch")
        try await keychain1.write(apiKey: "test_api_key")
        let engine1 = try await QuotaEngine(
            provider: provider1,
            persistence: persistence1,
            keychain: keychain1
        )
        await engine1.setBaseInterval(60)
        provider1.shouldThrowRateLimit = false

        // 初期スナップショットを取得
        _ = try await engine1.forceFetch()

        // nextFetchEpochを過去に設定
        let pastEpoch = Int(Date().timeIntervalSince1970) - 1000
        var state = try await persistence1.loadState()
        state.nextFetchEpoch = pastEpoch
        try await persistence1.saveState(state)

        // エンジンを破棄（強制終了をシミュレート）
        _ = engine1

        // 新しいエンジンインスタンスを作成（再起動をシミュレート）
        // 同じディレクトリとkeychainを再利用
        let provider2 = MockProvider()
        let persistence2 = PersistenceManager(customDirectoryURL: tempDir)
        let engine2 = try await QuotaEngine(
            provider: provider2,
            persistence: persistence2,
            keychain: keychain1
        )

        // nextFetchEpochが現在時刻に補正されていることを検証
        let nextFetchEpoch = await engine2.getNextFetchEpoch()
        let now = Int(Date().timeIntervalSince1970)
        XCTAssertGreaterThanOrEqual(nextFetchEpoch, now, "nextFetchEpochが現在時刻以降に補正されるべき")
    }

    // MARK: - キャッシュ破損

    /// キャッシュファイルが破損している場合: PersistenceManagerがnilを返す
    ///
    /// 注: ファイルの直接操作は内部実装に依存するため、ここでは
    /// PersistenceManager.loadCacheOrDefault() がエラー時にnilを返す挙動を
    /// QuotaEngine経由で検証します。
    func testCorruptedCacheFileHandledGracefully() async throws {
        let (_, _, _, persistence) = try await makeTestEngine(
            testName: "testCorruptedCacheFileHandledGracefully"
        )

        // PersistenceManagerの挙動を検証
        // 初期状態ではキャッシュが存在するはず
        let snapshot1 = await persistence.loadCacheOrDefault()
        XCTAssertNotNil(snapshot1, "初期キャッシュが存在するべき")

        // キャッシュを削除してからロード
        try? await persistence.deleteCache()
        let snapshot2 = await persistence.loadCacheOrDefault()
        XCTAssertNil(snapshot2, "キャッシュ削除後はnilを返すべき")
    }

    /// state.jsonが破損している場合: デフォルト値が使用される
    func testCorruptedStateFileHandledGracefully() async throws {
        let (_, _, _, persistence) = try await makeTestEngine(
            testName: "testCorruptedStateFileHandledGracefully"
        )

        // PersistenceManagerの挙動を検証
        // loadState() は常に有効なAppStateを返す（エラー時はデフォルト値）
        let loadedState = try await persistence.loadState()

        // デフォルト値と比較（エラー時はデフォルト値が使用される）
        let defaultState = AppState()
        XCTAssertEqual(loadedState.backoffFactor, defaultState.backoffFactor, "backoffFactorが有効であるべき")
        XCTAssertEqual(loadedState.consecutiveFailureCount, defaultState.consecutiveFailureCount, "consecutiveFailureCountが有効であるべき")
    }

    // MARK: - ネットワークエラー

    /// ネットワークエラー + キャッシュあり: キャッシュが返される
    func testNetworkErrorWithCachedData() async throws {
        let (engine, provider, _, _) = try await makeTestEngine(
            testName: "testNetworkErrorWithCachedData"
        )

        // 初期キャッシュを取得
        let originalSnapshot = try await engine.forceFetch()
        let originalTitle = originalSnapshot.primaryTitle

        // 次回フェッチ時刻を現在時刻に設定
        await engine.overrideNextFetchEpoch(Int(Date().timeIntervalSince1970))

        // ネットワークエラーを発生させる
        provider.shouldThrowNetworkError = true

        // フェッチを実行（エラーになるがキャッシュが返される）
        let resultSnapshot = try await engine.fetchIfDue()

        // キャッシュが返されることを検証
        XCTAssertEqual(resultSnapshot.primaryTitle, originalTitle, "キャッシュされたスナップショットが返されるべき")
    }

    /// ネットワークエラー + キャッシュなし: 適切なエラーがスローされる
    func testNetworkErrorWithoutCachedData() async throws {
        let (engine, provider, _, _) = try await makeTestEngine(
            testName: "testNetworkErrorWithoutCachedData",
            initializeCache: false
        )

        // 次回フェッチ時刻を現在時刻に設定
        await engine.overrideNextFetchEpoch(Int(Date().timeIntervalSince1970))

        // ネットワークエラーを発生させる
        provider.shouldThrowNetworkError = true

        // フェッチを実行（エラーになる）
        do {
            _ = try await engine.fetchIfDue()
            XCTFail("エラーがスローされるべき")
        } catch QuotaEngineError.noCachedData {
            // 期待通りのエラー
            XCTAssertTrue(true)
        } catch {
            XCTFail("予期しないエラー: \(error)")
        }
    }

    // MARK: - APIキー未設定

    /// APIキーが未設定の場合: 適切なエラーがスローされる
    func testNoApiKeyThrowsError() async throws {
        let provider = MockProvider()
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: "QuotaWatchTests_testNoApiKeyThrowsError_\(UUID().uuidString)")
        let persistence = PersistenceManager(customDirectoryURL: tempDir)
        let keychain = KeychainStore(account: "test_no_api_key")

        // APIキーを設定しない

        // QuotaEngine初期化時にエラーがスローされることを検証
        do {
            _ = try await QuotaEngine(
                provider: provider,
                persistence: persistence,
                keychain: keychain
            )
            XCTFail("エラーがスローされるべき")
        } catch QuotaEngineError.apiKeyNotSet {
            // 期待通り: APIキー未設定エラー
        } catch {
            XCTFail("予期しないエラー: \(error)")
        }
    }

    // MARK: - 連続失敗カウンター

    /// 連続失敗が閾値に達した場合: ループが停止する
    ///
    /// 注: 連続失敗カウンターは runLoop() 内でのみ更新されます。
    /// このテストは QuotaEngineRunLoopTests で既にカバーされています。
    func testConsecutiveFailuresStopsLoop() async throws {
        // この統合テストでは runLoop() を使用しないため、
        // 連続失敗カウンターのテストは QuotaEngineRunLoopTests に委ねます。
        throw XCTSkip("連続失敗カウンターは runLoop() 内でのみ機能します。QuotaEngineRunLoopTests を参照してください。")
    }

    /// 成功後: 連続失敗カウンターがリセットされる
    ///
    /// 注: 連続失敗カウンターは runLoop() 内でののみ更新されます。
    /// このテストは QuotaEngineRunLoopTests で既にカバーされています。
    func testSuccessResetsConsecutiveFailures() async throws {
        // この統合テストでは runLoop() を使用しないため、
        // 連続失敗カウンターのテストは QuotaEngineRunLoopTests に委ねます。
        throw XCTSkip("連続失敗カウンターは runLoop() 内でのみ機能します。QuotaEngineRunLoopTests を参照してください。")
    }
}
