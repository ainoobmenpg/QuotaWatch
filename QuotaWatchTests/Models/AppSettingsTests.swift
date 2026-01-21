//
//  AppSettingsTests.swift
//  QuotaWatchTests
//
//  AppSettingsのテスト
//

import XCTest
@testable import QuotaWatch

// MARK: - MockLoginItemService

/// テスト用のモックLoginItemService
@MainActor
final class MockLoginItemService: @preconcurrency LoginItemService {
    // MARK: - 挙動制御プロパティ

    private(set) var currentStatus: LoginItemStatus = .disabled
    private(set) var shouldThrowError: Bool = false
    private(set) var errorToThrow: Error = LoginItemError.unsupportedOS

    // MARK: - 呼び出し履歴

    private(set) var registerCallCount: Int = 0
    private(set) var unregisterCallCount: Int = 0

    // MARK: - LoginItemService

    var status: LoginItemStatus {
        return currentStatus
    }

    func register() throws {
        registerCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        currentStatus = .enabled
    }

    func unregister() throws {
        unregisterCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        currentStatus = .disabled
    }

    // MARK: - テストヘルパー

    func reset() {
        currentStatus = .disabled
        shouldThrowError = false
        errorToThrow = LoginItemError.unsupportedOS
        registerCallCount = 0
        unregisterCallCount = 0
    }
}

// MARK: - AppSettingsTests

@MainActor
final class AppSettingsTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var mockService: MockLoginItemService!

    override func setUp() async throws {
        try await super.setUp()
        // テスト用のUserDefaultsを作成
        testDefaults = UserDefaults(suiteName: #file)!
        // 既存の設定をクリア
        testDefaults.removePersistentDomain(forName: #file)
        // モックサービスを作成
        mockService = MockLoginItemService()
    }

    override func tearDown() async throws {
        // テスト後に設定をクリア
        testDefaults.removePersistentDomain(forName: #file)
        try await super.tearDown()
    }

    // MARK: - 既存テスト

    func testUpdateIntervalDefault() {
        let settings = AppSettings(defaults: testDefaults, loginItemService: mockService)
        XCTAssertEqual(settings.updateInterval, .fiveMinutes)
    }

    func testUpdateIntervalPersistence() {
        let settings = AppSettings(defaults: testDefaults, loginItemService: mockService)

        settings.updateInterval = .tenMinutes
        XCTAssertEqual(settings.updateInterval, .tenMinutes)

        let newSettings = AppSettings(defaults: testDefaults, loginItemService: mockService)
        XCTAssertEqual(newSettings.updateInterval, .tenMinutes)
    }

    func testNotificationsEnabledDefault() {
        let settings = AppSettings(defaults: testDefaults, loginItemService: mockService)
        XCTAssertTrue(settings.notificationsEnabled)
    }

    func testNotificationsDisabledPersistence() {
        let settings = AppSettings(defaults: testDefaults, loginItemService: mockService)

        settings.notificationsEnabled = false
        XCTAssertFalse(settings.notificationsEnabled)

        let newSettings = AppSettings(defaults: testDefaults, loginItemService: mockService)
        XCTAssertFalse(newSettings.notificationsEnabled)
    }

    func testLoginItemEnabledDefault() {
        let settings = AppSettings(defaults: testDefaults, loginItemService: mockService)
        XCTAssertFalse(settings.loginItemEnabled)
    }

    func testAllUpdateIntervals() {
        let settings = AppSettings(defaults: testDefaults, loginItemService: mockService)

        for interval in UpdateInterval.allCases {
            settings.updateInterval = interval
            XCTAssertEqual(settings.updateInterval, interval)
        }
    }

    // MARK: - Login Item テスト

    /// テスト用AppSettingsを作成するヘルパーメソッド
    @discardableResult
    private func setupAppSettings(
        initialStatus: LoginItemStatus = .disabled,
        shouldThrow: Bool = false
    ) -> AppSettings {
        mockService.reset()
        mockService.setCurrentStatus(initialStatus)
        mockService.setShouldThrowError(shouldThrow)
        return AppSettings(defaults: testDefaults, loginItemService: mockService)
    }

    /// Login Itemの登録成功テスト
    func testLoginItemRegisterSuccess() async {
        let settings = setupAppSettings(initialStatus: .disabled)

        // Login Itemを有効化
        settings.loginItemEnabled = true

        // 非同期処理完了を待機（デバウンシング50ms + 余裕100ms）
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15秒

        // registerが呼ばれたことを確認
        XCTAssertEqual(mockService.registerCallCount, 1, "registerが1回呼ばれるべき")

        // ステータスが有効になったことを確認
        XCTAssertEqual(mockService.status, .enabled)
    }

    /// Login Itemの解除成功テスト
    func testLoginItemUnregisterSuccess() async {
        let settings = setupAppSettings(initialStatus: .enabled)

        // Login Itemを無効化
        settings.loginItemEnabled = false

        // 非同期処理完了を待機（デバウンシング50ms + 余裕100ms）
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15秒

        // unregisterが呼ばれたことを確認
        XCTAssertEqual(mockService.unregisterCallCount, 1, "unregisterが1回呼ばれるべき")

        // ステータスが無効になったことを確認
        XCTAssertEqual(mockService.status, .disabled)
    }

    /// 既に有効な状態での登録試行テスト（スキップされる）
    func testLoginItemAlreadyEnabledSkip() async {
        let settings = setupAppSettings(initialStatus: .enabled)

        // Login Itemを有効化（既に有効なのでスキップされる）
        settings.loginItemEnabled = true

        // 非同期処理完了を待機（デバウンシング50ms + 余裕100ms）
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15秒

        // registerが呼ばれていないことを確認
        XCTAssertEqual(mockService.registerCallCount, 0, "registerは呼ばれないべき（既に有効）")
    }

    /// 既に無効な状態での解除試行テスト（スキップされる）
    func testLoginItemAlreadyDisabledSkip() async {
        let settings = setupAppSettings(initialStatus: .disabled)

        // Login Itemを無効化（既に無効なのでスキップされる）
        settings.loginItemEnabled = false

        // 非同期処理完了を待機（デバウンシング50ms + 余裕100ms）
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15秒

        // unregisterが呼ばれていないことを確認
        XCTAssertEqual(mockService.unregisterCallCount, 0, "unregisterは呼ばれるべき（既に無効）")
    }

    /// エラー時の動作テスト
    func testLoginItemErrorHandling() async {
        let settings = setupAppSettings(initialStatus: .disabled, shouldThrow: true)

        // エラーが投げられてもクラッシュしないことを確認
        settings.loginItemEnabled = true

        // 非同期処理完了を待機（デバウンシング50ms + 余裕100ms）
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15秒

        // registerが呼ばれたことを確認（エラーで失敗）
        XCTAssertEqual(mockService.registerCallCount, 1, "registerは呼ばれるがエラーで失敗")
    }
}

// MARK: - MockLoginItemService Extension

extension MockLoginItemService {
    func setCurrentStatus(_ status: LoginItemStatus) {
        currentStatus = status
    }

    func setShouldThrowError(_ shouldThrow: Bool) {
        shouldThrowError = shouldThrow
    }

    func setErrorToThrow(_ error: Error) {
        errorToThrow = error
    }
}
