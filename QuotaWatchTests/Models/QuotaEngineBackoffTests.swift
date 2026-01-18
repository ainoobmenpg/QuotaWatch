//
//  QuotaEngineBackoffTests.swift
//  QuotaWatchTests
//
//  QuotaEngineのバックオフ計算ロジックの単体テスト
//

import XCTest
@testable import QuotaWatch

// MARK: - QuotaEngineBackoffTests

/// QuotaEngineのバックオフ計算ロジックをテストするクラス
final class QuotaEngineBackoffTests: XCTestCase {
    // MARK: - テストヘルパー

    /// テスト用に独立したQuotaEngineインスタンスを作成
    ///
    /// - Parameters:
    ///   - testName: テスト名（一意のKeychainアカウント名を作成するため）
    ///   - baseInterval: 基本フェッチ間隔（秒）
    ///   - initializeCache: 初期キャッシュを取得するかどうか（デフォルトはtrue）
    /// - Returns: 初期化済みのQuotaEngineインスタンスと関連オブジェクト
    private func makeTestEngine(
        testName: String,
        baseInterval: TimeInterval = 60,
        initializeCache: Bool = true
    ) async throws -> (engine: QuotaEngine, provider: MockProvider, keychain: KeychainStore) {
        let provider = MockProvider()

        // 一時ディレクトリを作成して、各テストケースで独立したPersistenceManagerを使用
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: "QuotaWatchTests_\(testName)_\(UUID().uuidString)")
        let persistence = PersistenceManager(customDirectoryURL: tempDir)

        let keychain = KeychainStore(account: "test_\(testName)_\(UUID().uuidString)")

        // APIキーを設定
        try await keychain.write(apiKey: "test_api_key")

        // Engineを初期化
        let engine = await QuotaEngine(
            provider: provider,
            persistence: persistence,
            keychain: keychain
        )

        // 初期キャッシュを取得する場合
        if initializeCache {
            // 基本間隔を先に設定
            await engine.setBaseInterval(baseInterval)

            // 初期キャッシュを設定するため、最初に成功したフェッチを実行
            provider.shouldThrowRateLimit = false
            _ = try await engine.forceFetch()
        }

        return (engine, provider, keychain)
    }

    // MARK: - バックオフ計算テスト

    /// 成功時は基本間隔が使用される
    func testSuccessfulFetch_UsesBaseInterval() async throws {
        let (engine, provider, _) = try await makeTestEngine(
            testName: "testSuccessfulFetch",
            initializeCache: false  // 初期キャッシュをスキップ
        )

        // 基本間隔を設定して初期キャッシュを取得
        await engine.setBaseInterval(120)
        provider.shouldThrowRateLimit = false
        _ = try await engine.forceFetch()

        // 次回フェッチ時刻を現在時刻に設定（テストヘルパーを使用）
        await engine.overrideNextFetchEpoch(Int(Date().timeIntervalSince1970))

        // フェッチを実行
        _ = try await engine.fetchIfDue()

        // 次回フェッチ時刻を確認
        let nextFetchEpoch = await engine.getNextFetchEpoch()
        let now = Int(Date().timeIntervalSince1970)
        let interval = nextFetchEpoch - now

        // 120秒前後であることを確認（誤差5秒許容）
        XCTAssertEqual(interval, 120, accuracy: 5)
    }

    /// 最初のバックオフで係数が2倍になる
    func testRateLimit_FirstBackoff() async throws {
        let (engine, provider, _) = try await makeTestEngine(
            testName: "testFirstBackoff",
            initializeCache: false  // 初期キャッシュをスキップ
        )

        // 基本間隔を60秒に設定して初期キャッシュを取得
        await engine.setBaseInterval(60)
        provider.shouldThrowRateLimit = false
        _ = try await engine.forceFetch()

        // 次回フェッチ時刻を現在時刻に設定（テストヘルパーを使用）
        await engine.overrideNextFetchEpoch(Int(Date().timeIntervalSince1970))

        // レート制限を発生させる
        provider.shouldThrowRateLimit = true

        // フェッチを実行（レート制限エラー）
        _ = try await engine.fetchIfDue()

        // バックオフ係数が2になっていることを確認
        let state = await engine.getState()
        XCTAssertEqual(state.backoffFactor, 2)

        // 次回フェッチ時刻が120秒＋ジッター後であることを確認
        let nextFetchEpoch = await engine.getNextFetchEpoch()
        let now = Int(Date().timeIntervalSince1970)
        let interval = nextFetchEpoch - now

        // 120-135秒の範囲内であることを確認（60*2=120 + ジッター0-15）
        XCTAssertGreaterThanOrEqual(interval, 120)
        XCTAssertLessThanOrEqual(interval, 135)
    }

    /// 成功時は係数が1にリセットされる
    func testBackoffReset_OnSuccess() async throws {
        let (engine, provider, _) = try await makeTestEngine(
            testName: "testBackoffReset",
            initializeCache: false  // 初期キャッシュをスキップ
        )

        // 基本間隔を60秒に設定して初期キャッシュを取得
        await engine.setBaseInterval(60)
        provider.shouldThrowRateLimit = false
        _ = try await engine.forceFetch()

        // 次回フェッチ時刻を現在時刻に設定（テストヘルパーを使用）
        await engine.overrideNextFetchEpoch(Int(Date().timeIntervalSince1970))

        // 最初にレート制限を発生させてバックオフ状態にする
        provider.shouldThrowRateLimit = true
        _ = try await engine.fetchIfDue()

        var state = await engine.getState()
        XCTAssertEqual(state.backoffFactor, 2)

        // 成功させる（forceFetchを使用して待機を回避）
        provider.shouldThrowRateLimit = false
        _ = try await engine.forceFetch()

        // バックオフ係数が1にリセットされていることを確認
        state = await engine.getState()
        XCTAssertEqual(state.backoffFactor, 1)
    }

    /// 非レートエラーではバックオフされない
    func testNonRateLimit_NoBackoff() async throws {
        let (engine, provider, _) = try await makeTestEngine(
            testName: "testNonRateLimit",
            initializeCache: false  // 初期キャッシュをスキップ
        )

        // 基本間隔を60秒に設定して初期キャッシュを取得
        await engine.setBaseInterval(60)
        provider.shouldThrowRateLimit = false
        _ = try await engine.forceFetch()

        // 次回フェッチ時刻を現在時刻に設定（テストヘルパーを使用）
        await engine.overrideNextFetchEpoch(Int(Date().timeIntervalSince1970))

        // ネットワークエラーを発生させる
        provider.shouldThrowNetworkError = true
        _ = try await engine.fetchIfDue()

        // バックオフ係数が1のままであることを確認
        let state = await engine.getState()
        XCTAssertEqual(state.backoffFactor, 1)
    }

    /// ジッターが正しく付与される
    func testJitter_IsApplied() async throws {
        let (engine, provider, _) = try await makeTestEngine(
            testName: "testJitter",
            initializeCache: false  // 初期キャッシュをスキップ
        )

        // 基本間隔を60秒に設定して初期キャッシュを取得
        await engine.setBaseInterval(60)
        provider.shouldThrowRateLimit = false
        _ = try await engine.forceFetch()

        // レート制限を3回発生させてジッターが適用されていることを確認
        provider.shouldThrowRateLimit = true

        var intervals: Set<Int> = []

        for _ in 1...3 {
            // 次回フェッチ時刻を現在時刻に設定（テストヘルパーを使用）
            await engine.overrideNextFetchEpoch(Int(Date().timeIntervalSince1970))

            _ = try await engine.fetchIfDue()

            let nextFetchEpoch = await engine.getNextFetchEpoch()
            let now = Int(Date().timeIntervalSince1970)
            let interval = nextFetchEpoch - now
            intervals.insert(interval)
        }

        // ジッターにより間隔が分散されていることを確認
        // 少なくとも2種類以上の異なる間隔が存在するはず
        XCTAssertGreaterThan(intervals.count, 1, "ジッターにより間隔が分散されているべき")
    }

    /// 最小60秒が尊重される
    func testMinBaseInterval_Respected() async throws {
        // 基本間隔1秒を指定（最小間隔60秒でクリップされる）
        let (engine, provider, _) = try await makeTestEngine(
            testName: "testMinBaseInterval",
            initializeCache: false  // 初期キャッシュをスキップ
        )

        // 基本間隔1秒を設定（実際は60秒にクリップされる）
        await engine.setBaseInterval(1)

        // 初期キャッシュを取得
        provider.shouldThrowRateLimit = false
        _ = try await engine.forceFetch()

        // 次回フェッチ時刻を確認
        let nextFetchEpoch = await engine.getNextFetchEpoch()
        let now = Int(Date().timeIntervalSince1970)
        let interval = nextFetchEpoch - now

        // 60秒前後であることを確認（基本間隔は60にクリップされる）
        XCTAssertEqual(interval, 60, accuracy: 5)
    }

    // MARK: - Issue #38: 後回しにしたテスト

    /// 以下のテストはIssue #38で本格実装予定
    /// https://github.com/mo9mo9-uwu-mo9mo9/QuotaWatch/issues/38
    ///
    /// TODO: 指数関数的バックオフ（testRateLimit_ExponentialBackoff）
    /// - 2回目、3回目のバックオフで係数が4, 8になることを確認
    /// - 時間管理の抽象化またはモック導入が必要
    ///
    /// TODO: 最大バックオフクリップ（testRateLimit_MaxBackoffCap）
    /// - 5回連続のレート制限で、バックオフ係数が15に達した後、間隔が915秒以下にクリップされることを確認
    /// - テスト時間を短縮する工夫が必要
}
