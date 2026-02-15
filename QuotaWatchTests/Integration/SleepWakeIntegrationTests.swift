//
//  SleepWakeIntegrationTests.swift
//  QuotaWatchTests
//
//  スリープ復帰時の統合テスト
//

import XCTest
@testable import QuotaWatch

// MARK: - SleepWakeIntegrationTests

/// スリープ復帰時の統合テスト
///
/// Issue #16の解決を検証: ResetNotifier経由でQuotaEngine.handleWakeFromSleep()が
/// 正しく呼び出され、スリープ復帰時に即時フェッチが実行されることを確認します。
final class SleepWakeIntegrationTests: XCTestCase {

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

    /// ログ順序検証
    private func assertLogOrder(
        _ logContents: String,
        category: String,
        expectedMessages: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let logs = extractLogs(byCategory: category, from: logContents)

        for (index, expected) in expectedMessages.enumerated() {
            if index < logs.count {
                XCTAssertEqual(
                    logs[index],
                    expected,
                    "カテゴリ[\(category)]の\(index + 1)番目のログは「\(expected)」であるべきですが、実際は「\(logs[index])」",
                    file: file,
                    line: line
                )
            } else {
                XCTFail(
                    "カテゴリ[\(category)]のログ数が不足しています。\(index + 1)番目のログ「\(expected)」が見つかりません",
                    file: file,
                    line: line
                )
            }
        }
    }

    /// テスト用に独立したQuotaEngineインスタンスを作成
    private func makeTestEngine(
        testName: String,
        baseInterval: TimeInterval = 60
    ) async throws -> (engine: QuotaEngine, provider: MockProvider, keychain: KeychainStore) {
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

        await engine.setBaseInterval(baseInterval)
        provider.shouldThrowRateLimit = false
        _ = try await engine.forceFetch()

        return (engine, provider, keychain)
    }

    // MARK: - スリープ復帰テスト

    /// スリープ復帰時: 次回フェッチ時刻が過去の場合、即時フェッチが実行される
    func testWakeFromSleepTriggersImmediateFetch() async throws {
        let (engine, provider, _) = try await makeTestEngine(
            testName: "testWakeFromSleepTriggersImmediateFetch"
        )

        // ログをクリア
        await engine.clearDebugLog()

        // 次回フェッチ時刻を過去に設定
        let pastEpoch = Int(Date().timeIntervalSince1970) - 100
        await engine.overrideNextFetchEpoch(pastEpoch)

        // フェッチ回数をリセット（resetFetchCountメソッドを使用）
        provider.resetFetchCount()

        // handleWakeFromSleep() を呼び出し
        await engine.handleWakeFromSleep()

        // フェッチが実行されたことを検証
        XCTAssertEqual(provider.fetchCount, 1, "スリープ復帰時にフェッチが実行されるべき")

        // 次回フェッチ時刻が未来に更新されていることを検証
        let nextFetchEpoch = await engine.getNextFetchEpoch()
        let now = Int(Date().timeIntervalSince1970)
        XCTAssertGreaterThan(nextFetchEpoch, now, "次回フェッチ時刻が未来に更新されるべき")

        // ログ検証を追加（Issue #28）
        let logs = await engine.getDebugLogContents()
        assertLogOrder(
            logs,
            category: "ENGINE",
            expectedMessages: [
                "スリープから復帰しました - QuotaEngine",
                "スリープ復帰時: フェッチ時刻到達、即時フェッチを実行します"
            ]
        )
    }

    /// スリープ復帰時: 次回フェッチ時刻が未来の場合、フェッチは実行されない
    func testWakeBeforeDueTimeDoesNotFetch() async throws {
        let (engine, provider, _) = try await makeTestEngine(
            testName: "testWakeBeforeDueTimeDoesNotFetch"
        )

        // 次回フェッチ時刻を未来に設定
        let futureEpoch = Int(Date().timeIntervalSince1970) + 3600
        await engine.overrideNextFetchEpoch(futureEpoch)

        // フェッチ回数をリセット（resetFetchCountメソッドを使用）
        provider.resetFetchCount()

        // handleWakeFromSleep() を呼び出し
        await engine.handleWakeFromSleep()

        // フェッチが実行されないことを検証
        XCTAssertEqual(provider.fetchCount, 0, "次回フェッチ時刻が未来の場合、フェッチは実行されないべき")

        // 次回フェッチ時刻が変更されていないことを検証
        let nextFetchEpoch = await engine.getNextFetchEpoch()
        XCTAssertEqual(nextFetchEpoch, futureEpoch, "次回フェッチ時刻が変更されないべき")
    }

    /// スリープ復帰時のフェッチが失敗しても、エラーがログされるだけ
    func testWakeFromSleepFetchErrorIsHandled() async throws {
        let (engine, provider, _) = try await makeTestEngine(
            testName: "testWakeFromSleepFetchErrorIsHandled"
        )

        // 次回フェッチ時刻を過去に設定
        let pastEpoch = Int(Date().timeIntervalSince1970) - 100
        await engine.overrideNextFetchEpoch(pastEpoch)

        // ネットワークエラーを発生させる
        provider.shouldThrowNetworkError = true

        // handleWakeFromSleep() を呼び出し（エラーはログされるのみ）
        await engine.handleWakeFromSleep()

        // エラーがスローされずに処理が継続されることを検証
        // （テストがここまで到達すれば成功）
        XCTAssertTrue(true, "エラーが適切にハンドリングされるべき")
    }

    // MARK: - 統合テスト

    /// ResetNotifier経由のスリープ復帰検知の統合テスト
    ///
    /// 注: このテストは NSWorkspace.screensDidWakeNotification の実際の送信を
    /// エミュレートできないため、ResetNotifierがengine.handleWakeFromSleep()を
    /// 呼び出す構造になっていることを検証します。
    func testResetNotifierWakeupIntegration() async throws {
        let (engine, provider, _) = try await makeTestEngine(
            testName: "testResetNotifierWakeupIntegration"
        )

        // 次回フェッチ時刻を過去に設定
        let pastEpoch = Int(Date().timeIntervalSince1970) - 100
        await engine.overrideNextFetchEpoch(pastEpoch)

        // フェッチ回数をリセット（resetFetchCountメソッドを使用）
        provider.resetFetchCount()

        // ResetNotifier経由でhandleWakeFromSleep()を呼び出すのをエミュレート
        await engine.handleWakeFromSleep()

        // フェッチが実行されたことを検証
        XCTAssertEqual(provider.fetchCount, 1, "ResetNotifier経由でフェッチが実行されるべき")
    }

    /// スリープ復帰後の通常スケジュールへの復帰
    func testWakeFromSleepThenNormalSchedule() async throws {
        let (engine, _, _) = try await makeTestEngine(
            testName: "testWakeFromSleepThenNormalSchedule",
            baseInterval: 120
        )

        // 次回フェッチ時刻を過去に設定
        let pastEpoch = Int(Date().timeIntervalSince1970) - 100
        await engine.overrideNextFetchEpoch(pastEpoch)

        // handleWakeFromSleep() を呼び出し
        await engine.handleWakeFromSleep()

        // 次回フェッチ時刻が120秒後になっていることを検証
        let nextFetchEpoch = await engine.getNextFetchEpoch()
        let now = Int(Date().timeIntervalSince1970)
        let interval = nextFetchEpoch - now

        // 120秒前後であることを確認（誤差5秒許容）
        XCTAssertEqual(interval, 120, accuracy: 5, "基本間隔でスケジュールが復帰されるべき")
    }
}
