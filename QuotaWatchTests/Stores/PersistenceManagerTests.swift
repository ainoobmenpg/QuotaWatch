//
//  PersistenceManagerTests.swift
//  QuotaWatchTests
//
//  PersistenceManagerのテスト
//

import XCTest
@testable import QuotaWatch

final class PersistenceManagerTests: XCTestCase {
    var sut: PersistenceManager!
    var tempDirectory: URL!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appending(path: "QuotaWatchTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        sut = PersistenceManager(customDirectoryURL: tempDirectory)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // MARK: - usage_cache.json テスト

    func testSaveAndLoadCache() async throws {
        let snapshot = UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: 1737100800,
            primaryTitle: "GLM 5h",
            primaryPct: 42,
            primaryUsed: 4230,
            primaryTotal: 10000,
            primaryRemaining: 5770,
            resetEpoch: 1737100800,
            secondary: [],
            rawDebugJson: nil
        )

        // 保存
        try await sut.saveCache(snapshot)

        // 読み込み
        let loaded = try await sut.loadCache()

        XCTAssertEqual(loaded.providerId, "zai")
        XCTAssertEqual(loaded.primaryPct, 42)
        XCTAssertEqual(loaded.primaryUsed, 4230)
        XCTAssertEqual(loaded.primaryTotal, 10000)
    }

    func testLoadCacheOrDefaultReturnsNilWhenNotExists() async throws {
        let result = await sut.loadCacheOrDefault()
        XCTAssertNil(result)
    }

    func testLoadCacheOrDefaultReturnsSnapshotWhenExists() async throws {
        let snapshot = UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: 1737100800,
            primaryTitle: "GLM 5h",
            primaryPct: 42,
            primaryUsed: 4230,
            primaryTotal: 10000,
            primaryRemaining: 5770,
            resetEpoch: 1737100800,
            secondary: []
        )

        try await sut.saveCache(snapshot)
        let loaded = await sut.loadCacheOrDefault()

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.providerId, "zai")
    }

    func testDeleteCache() async throws {
        let snapshot = UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: 1737100800,
            primaryTitle: "GLM 5h",
            primaryPct: 42,
            primaryUsed: 4230,
            primaryTotal: 10000,
            primaryRemaining: 5770,
            resetEpoch: 1737100800,
            secondary: []
        )

        try await sut.saveCache(snapshot)
        try await sut.deleteCache()

        // 削除後はnilを返す
        let result = await sut.loadCacheOrDefault()
        XCTAssertNil(result)
    }

    // MARK: - state.json テスト

    func testSaveAndLoadState() async throws {
        var state = AppState()
        state.backoffFactor = 4
        state.lastError = "test error"
        state.lastKnownResetEpoch = 1737100800
        state.lastNotifiedResetEpoch = 1737100900

        // 保存
        try await sut.saveState(state)

        // 読み込み
        let loaded = try await sut.loadState()

        XCTAssertEqual(loaded.backoffFactor, 4)
        XCTAssertEqual(loaded.lastError, "test error")
        XCTAssertEqual(loaded.lastKnownResetEpoch, 1737100800)
        XCTAssertEqual(loaded.lastNotifiedResetEpoch, 1737100900)
    }

    func testLoadOrDefaultStateWhenFileNotExists() async throws {
        let state = await sut.loadOrDefaultState()
        XCTAssertEqual(state.backoffFactor, 1)
        XCTAssertEqual(state.lastError, "")
        XCTAssertEqual(state.lastKnownResetEpoch, 0)
        XCTAssertEqual(state.lastNotifiedResetEpoch, 0)
    }

    func testLoadOrDefaultStateReturnsSavedState() async throws {
        var state = AppState()
        state.backoffFactor = 8
        state.lastError = "network failure"

        try await sut.saveState(state)

        let loaded = await sut.loadOrDefaultState()
        XCTAssertEqual(loaded.backoffFactor, 8)
        XCTAssertEqual(loaded.lastError, "network failure")
    }

    func testDeleteState() async throws {
        var state = AppState()
        state.backoffFactor = 2

        try await sut.saveState(state)
        try await sut.deleteState()

        // 削除後はデフォルト値を返す
        let loaded = await sut.loadOrDefaultState()
        XCTAssertEqual(loaded.backoffFactor, 1)
    }

    // MARK: - コルーチン解除

    func testSaveAndLoadStateWithoutAsync() async throws {
        var state = AppState()
        state.backoffFactor = 3
        state.lastError = "async test"

        try await sut.saveState(state)
        let loaded = try await sut.loadState()

        XCTAssertEqual(loaded.backoffFactor, 3)
        XCTAssertEqual(loaded.lastError, "async test")
    }

    // MARK: - 破損データテスト

    func testLoadCacheHandlesCorruptedData() async throws {
        // 破損したJSONファイルを作成
        let fileURL = tempDirectory.appendingPathComponent("usage_cache.json")
        try "{invalid json}".data(using: .utf8)?.write(to: fileURL)

        // 破損データではloadCacheがエラーを投げる
        do {
            _ = try await sut.loadCache()
            XCTFail("期待通りエラーが投げられませんでした")
        } catch {
            // 成功 - エラーが投げられた
        }

        // loadCacheOrDefaultはnilを返す
        let result = await sut.loadCacheOrDefault()
        XCTAssertNil(result)
    }

    func testLoadStateHandlesCorruptedData() async throws {
        // 破損したJSONファイルを作成
        let fileURL = tempDirectory.appendingPathComponent("state.json")
        try "{invalid state}".data(using: .utf8)?.write(to: fileURL)

        // 破損データでもloadStateはデフォルト値を返す（実装の仕様）
        let loaded = try await sut.loadState()
        XCTAssertEqual(loaded.backoffFactor, 1)

        // loadOrDefaultStateもデフォルト値を返す
        let defaultLoaded = await sut.loadOrDefaultState()
        XCTAssertEqual(defaultLoaded.backoffFactor, 1)
    }

    // MARK: - Atomic Writeテスト

    func testAtomicWriteReplacesExistingFile() async throws {
        let snapshot1 = UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: 1000,
            primaryTitle: "Original",
            primaryPct: 10,
            primaryUsed: 100,
            primaryTotal: 1000,
            primaryRemaining: 900,
            resetEpoch: 2000,
            secondary: []
        )

        let snapshot2 = UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: 3000,
            primaryTitle: "Updated",
            primaryPct: 50,
            primaryUsed: 500,
            primaryTotal: 1000,
            primaryRemaining: 500,
            resetEpoch: 4000,
            secondary: []
        )

        // 最初の保存
        try await sut.saveCache(snapshot1)
        let loaded1 = try await sut.loadCache()
        XCTAssertEqual(loaded1.fetchedAtEpoch, 1000)
        XCTAssertEqual(loaded1.primaryTitle, "Original")

        // 上書き保存
        try await sut.saveCache(snapshot2)
        let loaded2 = try await sut.loadCache()
        XCTAssertEqual(loaded2.fetchedAtEpoch, 3000)
        XCTAssertEqual(loaded2.primaryTitle, "Updated")
    }
}
