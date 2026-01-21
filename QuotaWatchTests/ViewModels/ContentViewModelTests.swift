//
//  ContentViewModelTests.swift
//  QuotaWatchTests
//
//  ContentViewModelの単体テスト
//

import XCTest
@testable import QuotaWatch

// MARK: - Test Helper

/// AsyncStreamのイベントを待機するヘルパー
@MainActor
func awaitCondition(
    timeout: TimeInterval = 1.0,
    _ condition: @escaping () async -> Bool,
    file: StaticString = #filePath,
    line: UInt = #line
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    let pollingInterval: TimeInterval = 0.001

    while Date() < deadline {
        if await condition() {
            return
        }
        try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
    }

    XCTFail("条件を満たしませんでした: タイムアウト \(timeout)秒", file: file, line: line)
}

/// ContentViewModelの単体テスト
@MainActor
final class ContentViewModelTests: XCTestCase {
    var mockEngine: MockQuotaEngine!
    var mockProvider: MockProvider!
    var viewModel: ContentViewModel!

    override func setUp() async throws {
        mockEngine = MockQuotaEngine()
        mockProvider = MockProvider()
        viewModel = ContentViewModel(engine: mockEngine, provider: mockProvider)
    }

    // MARK: - 初期化テスト

    func testInitialization() async throws {
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel.isLoadingInitialData)
        XCTAssertNil(viewModel.snapshot)
        XCTAssertNil(viewModel.engineState)
    }

    // MARK: - loadInitialDataテスト

    func testLoadInitialData_PopulatesSnapshot() async throws {
        let testSnapshot = UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: Int(Date().timeIntervalSince1970),
            primaryTitle: "Test",
            primaryPct: 75,
            primaryUsed: 75.0,
            primaryTotal: 100.0,
            primaryRemaining: 25.0,
            resetEpoch: nil,
            secondary: [],
            rawDebugJson: nil
        )
        await mockEngine.setSnapshot(testSnapshot)

        await viewModel.loadInitialData()

        XCTAssertEqual(viewModel.snapshot?.primaryTitle, "Test")
        XCTAssertFalse(viewModel.isLoadingInitialData)
    }

    func testLoadInitialData_PopulatesEngineState() async throws {
        let testState = AppState(
            nextFetchEpoch: 12345,
            backoffFactor: 2,
            lastFetchEpoch: 10000,
            lastError: "",
            lastKnownResetEpoch: 0,
            lastNotifiedResetEpoch: 0,
            consecutiveFailureCount: 0
        )
        await mockEngine.updateMockState(nextFetchEpoch: 12345, backoffFactor: 2, lastFetchEpoch: 10000)

        await viewModel.loadInitialData()

        XCTAssertEqual(viewModel.engineState?.nextFetchEpoch, 12345)
        XCTAssertEqual(viewModel.engineState?.backoffFactor, 2)
        XCTAssertFalse(viewModel.isLoadingInitialData)
    }

    // MARK: - updateStateテスト

    func testUpdateState_RefreshesFromEngine() async throws {
        let testSnapshot = UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: Int(Date().timeIntervalSince1970),
            primaryTitle: "Updated",
            primaryPct: 80,
            primaryUsed: 80.0,
            primaryTotal: 100.0,
            primaryRemaining: 20.0,
            resetEpoch: nil,
            secondary: [],
            rawDebugJson: nil
        )
        await mockEngine.setSnapshot(testSnapshot)

        await viewModel.updateState()

        XCTAssertEqual(viewModel.snapshot?.primaryTitle, "Updated")
    }

    // MARK: - forceFetchテスト

    func testForceFetch_Success() async throws {
        let testSnapshot = UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: Int(Date().timeIntervalSince1970),
            primaryTitle: "Fetched",
            primaryPct: 90,
            primaryUsed: 90.0,
            primaryTotal: 100.0,
            primaryRemaining: 10.0,
            resetEpoch: nil,
            secondary: [],
            rawDebugJson: nil
        )
        await mockEngine.setSnapshot(testSnapshot)

        await viewModel.forceFetch()

        let callCount = await mockEngine.forceFetchCallCount
        XCTAssertEqual(callCount, 1)
        XCTAssertFalse(viewModel.isFetching)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testForceFetch_Error() async throws {
        await mockEngine.setForceFetchError(QuotaEngineError.apiKeyNotSet)

        await viewModel.forceFetch()

        let callCount = await mockEngine.forceFetchCallCount
        XCTAssertEqual(callCount, 1)
        XCTAssertFalse(viewModel.isFetching)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - メニューバータイトルテスト

    func testMenuBarTitle_WithSnapshot() async throws {
        let testSnapshot = UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: Int(Date().timeIntervalSince1970),
            primaryTitle: "GLM 5h",
            primaryPct: 42,
            primaryUsed: 42.0,
            primaryTotal: 100.0,
            primaryRemaining: 58.0,
            resetEpoch: Int(Date().timeIntervalSince1970) + 7200,
            secondary: [],
            rawDebugJson: nil
        )
        await mockEngine.setSnapshot(testSnapshot)

        await viewModel.loadInitialData()

        // AsyncStreamイベントを待機
        try await awaitCondition(timeout: 0.5) {
            self.viewModel.menuBarTitle.contains("GLM 5h") && self.viewModel.menuBarTitle.contains("42%")
        }

        XCTAssertFalse(viewModel.menuBarTitle.isEmpty)
        XCTAssertTrue(viewModel.menuBarTitle.contains("GLM 5h"))
        XCTAssertTrue(viewModel.menuBarTitle.contains("42%"))
    }

    func testMenuBarTitle_UpdatesOnEvent() async throws {
        // 初期状態ではロード中
        XCTAssertTrue(viewModel.isLoadingInitialData)
        XCTAssertEqual(viewModel.menuBarTitle, "...")

        // スナップショットを設定
        let testSnapshot = UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: Int(Date().timeIntervalSince1970),
            primaryTitle: "Updated",
            primaryPct: 85,
            primaryUsed: 85.0,
            primaryTotal: 100.0,
            primaryRemaining: 15.0,
            resetEpoch: nil,
            secondary: [],
            rawDebugJson: nil
        )
        await mockEngine.setSnapshot(testSnapshot)

        await viewModel.loadInitialData()

        // タイトルが更新されることを待機
        try await awaitCondition(timeout: 0.5) {
            self.viewModel.menuBarTitle.contains("Updated")
        }

        XCTAssertEqual(viewModel.snapshot?.primaryTitle, "Updated")
    }
}
