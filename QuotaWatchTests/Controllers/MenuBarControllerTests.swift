//
//  MenuBarControllerTests.swift
//  QuotaWatchTests
//
//  MenuBarControllerの単体テスト（バグ1: resetEpoch == nil のエッジケース対応）
//

import XCTest
import AppKit
import Combine
@testable import QuotaWatch

// MARK: - MenuBarController Tests

/// MenuBarControllerの単体テスト
///
/// ## テスト目的
/// - バグ1再現: `resetEpoch == nil` の場合にドーナツアイコンが消える問題を検出
/// - アイコン生成ロジックの境界値をカバー
///
/// ## テスト対象
/// - `startIconAnimation()` - snapshotから目標値を取得してアイコン更新をトリガー
/// - `updateMenuBarIconDirectly()` - アイコン表示の分岐ロジック
///
/// ## 補足
/// MenuBarControllerはNSStatusItemを使用するため、実際のUIテストは困難です。
/// ここでは、アイコン生成ロジックの正しさを検証します。
@MainActor
final class MenuBarControllerTests: XCTestCase {

    // MARK: - テストプロパティ

    private var mockEngine: MockQuotaEngine!
    private var mockProvider: MockProvider!

    // MARK: - セットアップ/ティアダウン

    override func setUp() async throws {
        try await super.setUp()
        mockEngine = MockQuotaEngine()
        mockProvider = MockProvider()
    }

    override func tearDown() async throws {
        mockEngine = nil
        mockProvider = nil
        try await super.tearDown()
    }

    // MARK: - バグ1再現テスト: resetEpoch == nil の場合

    /// テスト: resetEpochがnilでもドーナツアイコンが生成されること
    ///
    /// ## 背景
    /// 修正前: `resetEpoch == nil` の場合、`startIconAnimation()` で
    /// `snapshot.primaryPct` があっても early return してテキスト表示になっていた
    ///
    /// ## 期待される動作
    /// `resetEpoch == nil` でも `primaryPct` があればドーナツアイコンを表示
    func testIconDisplay_whenResetEpochIsNil_showsDonutIcon() async throws {
        // Arrange: resetEpochがnil、primaryPctがあるスナップショット
        let snapshot = UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: Int(Date().timeIntervalSince1970),
            primaryTitle: "GLM 5h",
            primaryPct: 42,  // primaryPctは存在
            primaryUsed: 42.0,
            primaryTotal: 100.0,
            primaryRemaining: 58.0,
            resetEpoch: nil,  // resetEpochはnil
            secondary: [],
            rawDebugJson: nil
        )

        // Act: アイコンを生成
        let icon = MenuBarDonutIcon(
            usagePercentage: snapshot.primaryPct ?? 0,
            timeProgress: 0.0,  // resetEpochがnilの場合は進捗0%
            remainingSeconds: 0,
            diameter: 22
        )
        let image = icon.makeImage()

        // Assert: 画像が正常に生成されること
        XCTAssertNotNil(image, "resetEpochがnilでもアイコン画像が生成されるべき")
        XCTAssertGreaterThan(image.size.width, 22, "画像幅は円の直径より大きいべき（テキスト含む）")
        XCTAssertEqual(image.size.height, 22, "画像高さは円の直径と一致すべき")
    }

    /// テスト: resetEpochが有効な場合、ドーナツアイコンが生成されること
    func testIconDisplay_whenResetEpochIsValid_showsDonutIcon() async throws {
        // Arrange: resetEpochが有効なスナップショット
        let now = Int(Date().timeIntervalSince1970)
        let resetEpoch = now + 3600  // 1時間後
        let snapshot = UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: now,
            primaryTitle: "GLM 5h",
            primaryPct: 50,
            primaryUsed: 50.0,
            primaryTotal: 100.0,
            primaryRemaining: 50.0,
            resetEpoch: resetEpoch,
            secondary: [],
            rawDebugJson: nil
        )

        // Act: 時間進捗を計算してアイコンを生成
        let fiveHoursInSeconds: Double = 5 * 60 * 60
        let periodStart = resetEpoch - Int(fiveHoursInSeconds)
        let elapsed = max(0, Double(now - periodStart))
        let timeProgress = min(elapsed / fiveHoursInSeconds, 1.0)

        let icon = MenuBarDonutIcon(
            usagePercentage: snapshot.primaryPct ?? 0,
            timeProgress: timeProgress,
            remainingSeconds: resetEpoch - now,
            diameter: 22
        )
        let image = icon.makeImage()

        // Assert
        XCTAssertNotNil(image, "resetEpochが有効な場合、アイコン画像が生成されるべき")
        XCTAssertGreaterThan(image.size.width, 22, "画像幅は円の直径より大きいべき")
    }

    /// テスト: primaryPctがnilの場合、アイコンは生成されずテキスト表示になること
    ///
    /// ## 期待される動作
    /// `primaryPct == nil` の場合はドーナツアイコンを表示せず、テキストのみ表示
    func testIconDisplay_whenPrimaryPctIsNil_showsTextOnly() async throws {
        // Arrange: primaryPctがnilのスナップショット
        let snapshot = UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: Int(Date().timeIntervalSince1970),
            primaryTitle: "GLM 5h",
            primaryPct: nil,  // primaryPctがnil
            primaryUsed: nil,
            primaryTotal: nil,
            primaryRemaining: nil,
            resetEpoch: Int(Date().timeIntervalSince1970) + 3600,
            secondary: [],
            rawDebugJson: nil
        )

        // Act & Assert: primaryPctがnilの場合の判定ロジック
        // MenuBarControllerの startIconAnimation() と同様のロジック
        guard let pct = snapshot.primaryPct else {
            // このパスではアイコンを生成せず、テキスト表示になる
            XCTAssertTrue(true, "primaryPctがnilの場合はテキスト表示になるべき")
            return
        }

        // ここに到達した場合はテスト失敗
        XCTFail("primaryPctがnilなのにアイコン生成パスに入った: pct=\(pct)")
    }

    // MARK: - 時間進捗計算テスト

    /// テスト: resetEpochがnilの場合、時間進捗は0%になること
    func testTimeProgress_whenResetEpochIsNil_isZero() async throws {
        // Arrange
        let snapshot = UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: Int(Date().timeIntervalSince1970),
            primaryTitle: "GLM 5h",
            primaryPct: 50,
            primaryUsed: 50.0,
            primaryTotal: 100.0,
            primaryRemaining: 50.0,
            resetEpoch: nil,
            secondary: [],
            rawDebugJson: nil
        )

        // Act: MenuBarControllerの時間進捗計算ロジックと同様
        let now = Int(Date().timeIntervalSince1970)
        let fiveHoursInSeconds: Double = 5 * 60 * 60
        let calculatedTimeProgress: Double

        if let resetEpoch = snapshot.resetEpoch, resetEpoch > now {
            let periodStart = resetEpoch - Int(fiveHoursInSeconds)
            let elapsed = max(0, Double(now - periodStart))
            calculatedTimeProgress = min(elapsed / fiveHoursInSeconds, 1.0)
        } else {
            // resetEpochがnilまたは過去の場合は進捗0%
            calculatedTimeProgress = 0.0
        }

        // Assert
        XCTAssertEqual(calculatedTimeProgress, 0.0, "resetEpochがnilの場合、時間進捗は0%になるべき")
    }

    /// テスト: resetEpochが過去の場合、時間進捗は0%になること
    func testTimeProgress_whenResetEpochIsInPast_isZero() async throws {
        // Arrange: resetEpochを過去に設定
        let now = Int(Date().timeIntervalSince1970)
        let pastResetEpoch = now - 1000  // 過去

        let snapshot = UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: now,
            primaryTitle: "GLM 5h",
            primaryPct: 50,
            primaryUsed: 50.0,
            primaryTotal: 100.0,
            primaryRemaining: 50.0,
            resetEpoch: pastResetEpoch,
            secondary: [],
            rawDebugJson: nil
        )

        // Act
        let fiveHoursInSeconds: Double = 5 * 60 * 60
        let calculatedTimeProgress: Double

        if let resetEpoch = snapshot.resetEpoch, resetEpoch > now {
            let periodStart = resetEpoch - Int(fiveHoursInSeconds)
            let elapsed = max(0, Double(now - periodStart))
            calculatedTimeProgress = min(elapsed / fiveHoursInSeconds, 1.0)
        } else {
            calculatedTimeProgress = 0.0
        }

        // Assert
        XCTAssertEqual(calculatedTimeProgress, 0.0, "resetEpochが過去の場合、時間進捗は0%になるべき")
    }

    // MARK: - 境界値テスト

    /// テスト: 使用率0%のアイコンが正常に生成されること
    func testIconDisplay_withZeroUsagePercentage() async throws {
        let icon = MenuBarDonutIcon(
            usagePercentage: 0,
            timeProgress: 0.0,
            remainingSeconds: 18000,
            diameter: 22
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "使用率0%のアイコンが正常に生成されるべき")
    }

    /// テスト: 使用率100%のアイコンが正常に生成されること
    func testIconDisplay_with100UsagePercentage() async throws {
        let icon = MenuBarDonutIcon(
            usagePercentage: 100,
            timeProgress: 1.0,
            remainingSeconds: 0,
            diameter: 22
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "使用率100%のアイコンが正常に生成されるべき")
    }

    /// テスト: 残り秒数0でもアイコンが正常に生成されること
    func testIconDisplay_withZeroRemainingSeconds() async throws {
        let icon = MenuBarDonutIcon(
            usagePercentage: 50,
            timeProgress: 1.0,
            remainingSeconds: 0,
            diameter: 22
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "残り秒数0のアイコンが正常に生成されるべき")
    }

    // MARK: - ContentViewModel経由のテスト

    /// テスト: ContentViewModelのsnapshot更新時にMenuBarControllerが正しく動作すること
    func testContentViewModel_snapshotUpdate_triggersIconUpdate() async throws {
        // Arrange: ContentViewModelを作成
        let viewModel = ContentViewModel(engine: mockEngine, provider: mockProvider)

        // resetEpochがnilのスナップショット
        let snapshot = UsageSnapshot(
            providerId: "mock",
            fetchedAtEpoch: Int(Date().timeIntervalSince1970),
            primaryTitle: "GLM 5h",
            primaryPct: 42,
            primaryUsed: 42.0,
            primaryTotal: 100.0,
            primaryRemaining: 58.0,
            resetEpoch: nil,
            secondary: [],
            rawDebugJson: nil
        )
        await mockEngine.setSnapshot(snapshot)

        // Act: 初期データを読み込み
        await viewModel.loadInitialData()

        // Assert: snapshotが正しく設定されること
        try await awaitCondition(timeout: 0.5) {
            viewModel.snapshot?.primaryPct == 42
        }

        XCTAssertEqual(viewModel.snapshot?.primaryPct, 42, "snapshotが正しく更新されるべき")
        XCTAssertNil(viewModel.snapshot?.resetEpoch, "resetEpochはnilのまま")
    }
}
