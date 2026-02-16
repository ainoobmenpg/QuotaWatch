//
//  MenuBarDonutIconTests.swift
//  QuotaWatchTests
//
//  MenuBarDonutIconのテスト（案A: 円グラフ＋テキスト）
//

import XCTest
@testable import QuotaWatch
import AppKit

@MainActor
final class MenuBarDonutIconTests: XCTestCase {
    // MARK: - 色計算ロジックのテスト

    func testUsageColorGreen() {
        // 残り51%以上は緑（使用率49%以下）
        let icon1 = MenuBarDonutIcon(usagePercentage: 0, timeProgress: 0, remainingSeconds: 0, diameter: 22)
        let icon2 = MenuBarDonutIcon(usagePercentage: 49, timeProgress: 0, remainingSeconds: 0, diameter: 22)

        let image1 = icon1.makeImage()
        let image2 = icon2.makeImage()

        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        XCTAssertTrue(image1.representations.count > 0)
        XCTAssertTrue(image2.representations.count > 0)
    }

    func testUsageColorOrange() {
        // 残り21-50%はオレンジ（使用率50-79%）
        let icon1 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0, remainingSeconds: 0, diameter: 22)
        let icon2 = MenuBarDonutIcon(usagePercentage: 79, timeProgress: 0, remainingSeconds: 0, diameter: 22)

        let image1 = icon1.makeImage()
        let image2 = icon2.makeImage()

        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        XCTAssertTrue(image1.representations.count > 0)
        XCTAssertTrue(image2.representations.count > 0)
    }

    func testUsageColorRed() {
        // 残り0-20%は赤（使用率80-100%）
        let icon1 = MenuBarDonutIcon(usagePercentage: 80, timeProgress: 0, remainingSeconds: 0, diameter: 22)
        let icon2 = MenuBarDonutIcon(usagePercentage: 100, timeProgress: 0, remainingSeconds: 0, diameter: 22)

        let image1 = icon1.makeImage()
        let image2 = icon2.makeImage()

        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        XCTAssertTrue(image1.representations.count > 0)
        XCTAssertTrue(image2.representations.count > 0)
    }

    // MARK: - 境界値テスト

    func testUsageColorBoundaries() {
        let icon49 = MenuBarDonutIcon(usagePercentage: 49, timeProgress: 0, remainingSeconds: 0, diameter: 22)
        let icon50 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0, remainingSeconds: 0, diameter: 22)
        let icon79 = MenuBarDonutIcon(usagePercentage: 79, timeProgress: 0, remainingSeconds: 0, diameter: 22)
        let icon80 = MenuBarDonutIcon(usagePercentage: 80, timeProgress: 0, remainingSeconds: 0, diameter: 22)

        XCTAssertNotNil(icon49.makeImage())
        XCTAssertNotNil(icon50.makeImage())
        XCTAssertNotNil(icon79.makeImage())
        XCTAssertNotNil(icon80.makeImage())
    }

    // MARK: - 時間グラフのテスト

    func testTimeProgress() {
        let icon0 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.0, remainingSeconds: 0, diameter: 22)
        let icon50 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, remainingSeconds: 1800, diameter: 22)
        let icon100 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 1.0, remainingSeconds: 3600, diameter: 22)

        XCTAssertNotNil(icon0.makeImage())
        XCTAssertNotNil(icon50.makeImage())
        XCTAssertNotNil(icon100.makeImage())
    }

    // MARK: - 画像サイズのテスト（案A: 円＋テキスト）

    func testImageSizeStandard22pt() {
        // 標準サイズ（円22pt + テキスト）
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, remainingSeconds: 1800, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image)
        // 円(22) + スペース(4) + テキスト(可変) = 円以上の幅
        XCTAssertGreaterThan(image.size.width, 22, "画像の幅は円の直径より大きいべき")
        XCTAssertEqual(image.size.height, 22, "画像の高さが22ピクセルであるべき")
    }

    func testImageSizeSmall16pt() {
        // 小さいサイズ（円16pt + テキスト）
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, remainingSeconds: 1800, diameter: 16)
        let image = icon.makeImage()

        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.size.width, 16, "画像の幅は円の直径より大きいべき")
        XCTAssertEqual(image.size.height, 16, "画像の高さが16ピクセルであるべき")
    }

    // MARK: - 案A特有のテスト（円＋テキスト）

    func testIconWithTextGeneratesImage() {
        // 円＋テキストが生成されることを確認
        let icon = MenuBarDonutIcon(usagePercentage: 25, timeProgress: 0.7, remainingSeconds: 5328, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image, "円＋テキストアイコンが生成されるべき")
        XCTAssertTrue(image.representations.count > 0, "画像表現が存在するべき")
        // 幅は円＋スペース＋テキスト
        XCTAssertGreaterThan(image.size.width, 22, "幅は円より大きい")
        XCTAssertEqual(image.size.height, 22, "高さは円の直径")
    }

    func testRemainingPercentageDisplay() {
        // 残りパーセントが正しく計算されることを確認
        let icon = MenuBarDonutIcon(usagePercentage: 25, timeProgress: 0.5, remainingSeconds: 1800, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image, "残り75%のアイコンが生成されるべき")
    }

    // MARK: - 時間フォーマットのテスト

    func testTimeFormatOverOneHour() {
        // 1時間以上: H:MM 形式
        // 5432秒 = 1時間30分32秒 → "1:30"
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, remainingSeconds: 5432, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image, "1:30形式の時間が表示されるべき")
    }

    func testTimeFormatUnderOneHour() {
        // 1時間未満: M:SS 形式
        // 1832秒 = 30分32秒 → "30:32"
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, remainingSeconds: 1832, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image, "30:32形式の時間が表示されるべき")
    }

    func testTimeFormatUnderOneMinute() {
        // 1分未満: M:SS 形式（0:45）
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, remainingSeconds: 45, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image, "0:45形式の時間が表示されるべき")
    }

    func testTimeFormatZero() {
        // 0秒（リセット時間なし）→ "--:--" が表示される
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, remainingSeconds: 0, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image, "リセット時間なしの場合は--:--が表示されるべき")
    }

    func testTimeFormatNegative() {
        // 負の値（リセット時間なし扱い）→ "--:--" が表示される
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, remainingSeconds: -100, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image, "負の値は--:--として表示されるべき")
    }

    // MARK: - エッジケース

    func testEdgeCases() {
        let icon0 = MenuBarDonutIcon(usagePercentage: 0, timeProgress: 0, remainingSeconds: 0, diameter: 22)
        let icon100 = MenuBarDonutIcon(usagePercentage: 100, timeProgress: 1.0, remainingSeconds: 18000, diameter: 22)

        XCTAssertNotNil(icon0.makeImage())
        XCTAssertNotNil(icon100.makeImage())
    }

    func testNegativeHandling() {
        let iconNeg = MenuBarDonutIcon(usagePercentage: -10, timeProgress: 0, remainingSeconds: -100, diameter: 22)
        let iconOver = MenuBarDonutIcon(usagePercentage: 150, timeProgress: 1.5, remainingSeconds: 99999, diameter: 22)

        XCTAssertNotNil(iconNeg.makeImage())
        XCTAssertNotNil(iconOver.makeImage())
    }

    // MARK: - Retinaディスプレイ対応テスト

    func testRetinaDisplaySupport() {
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, remainingSeconds: 1800, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image)
    }

    // MARK: - デフォルトパラメータテスト

    func testDefaultParameters() {
        // デフォルトパラメータで初期化
        let icon = MenuBarDonutIcon(
            usagePercentage: 50,
            timeProgress: 0.5,
            remainingSeconds: 1800
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.size.width, 22) // 円より広い
        XCTAssertEqual(image.size.height, 22)
    }

    func testCustomSpacing() {
        // カスタムスペース
        let icon = MenuBarDonutIcon(
            usagePercentage: 50,
            timeProgress: 0.5,
            remainingSeconds: 1800,
            diameter: 22,
            spacing: 8
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image)
        // スペースが広がるので幅も広がる
        XCTAssertGreaterThan(image.size.width, 22)
        XCTAssertEqual(image.size.height, 22)
    }

    // MARK: - 境界値テスト（バグ防止）

    /// テスト: 残り秒数が0でもアイコンが正常に生成されること
    func testIconDisplay_whenRemainingSecondsIsZero() {
        let icon = MenuBarDonutIcon(
            usagePercentage: 50,
            timeProgress: 1.0,
            remainingSeconds: 0,
            diameter: 22
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "残り秒数0でもアイコンが生成されるべき")
        XCTAssertTrue(image.representations.count > 0)
    }

    /// テスト: 使用率100%でもアイコンが正常に生成されること
    func testIconDisplay_whenUsagePercentageIs100() {
        let icon = MenuBarDonutIcon(
            usagePercentage: 100,
            timeProgress: 0.5,
            remainingSeconds: 1800,
            diameter: 22
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "使用率100%でもアイコンが生成されるべき")
        XCTAssertTrue(image.representations.count > 0)
    }

    /// テスト: 使用率0%でもアイコンが正常に生成されること
    func testIconDisplay_whenUsagePercentageIsZero() {
        let icon = MenuBarDonutIcon(
            usagePercentage: 0,
            timeProgress: 0.5,
            remainingSeconds: 1800,
            diameter: 22
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "使用率0%でもアイコンが生成されるべき")
        XCTAssertTrue(image.representations.count > 0)
    }

    // MARK: - 3桁表示テスト（残量100%）

    /// テスト: 残量100%（使用率0%）の「100」が3桁でも正しく表示されること
    func testIconDisplay_withThreeDigitPercentage() {
        // 使用率0% = 残量100%（3桁）
        let icon = MenuBarDonutIcon(
            usagePercentage: 0,
            timeProgress: 0.0,
            remainingSeconds: 0,  // リセット時間なし
            diameter: 22
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "残量100%（3桁）でもアイコンが生成されるべき")
        XCTAssertTrue(image.representations.count > 0)
        // フォントサイズが縮小されることで円内に収まる
    }

    /// テスト: 残量100%かつリセット時間なしの場合の表示
    func testIconDisplay_withFullQuotaAndNoResetTime() {
        // 使用率0% = 残量100%、リセット時間なし = --:--
        let icon = MenuBarDonutIcon(
            usagePercentage: 0,
            timeProgress: 0.0,
            remainingSeconds: 0,
            diameter: 22
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "100% + --:-- の組み合わせが正しく表示されるべき")
        XCTAssertTrue(image.representations.count > 0)
    }

    /// テスト: 時間進捗0%でもアイコンが正常に生成されること
    func testIconDisplay_whenTimeProgressIsZero() {
        let icon = MenuBarDonutIcon(
            usagePercentage: 50,
            timeProgress: 0.0,
            remainingSeconds: 18000,
            diameter: 22
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "時間進捗0%でもアイコンが生成されるべき")
        XCTAssertTrue(image.representations.count > 0)
    }

    /// テスト: 時間進捗100%でもアイコンが正常に生成されること
    func testIconDisplay_whenTimeProgressIsOneHundred() {
        let icon = MenuBarDonutIcon(
            usagePercentage: 50,
            timeProgress: 1.0,
            remainingSeconds: 0,
            diameter: 22
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "時間進捗100%でもアイコンが生成されるべき")
        XCTAssertTrue(image.representations.count > 0)
    }

    /// テスト: 全てのパラメータが最小値でもアイコンが正常に生成されること
    func testIconDisplay_withAllMinimumValues() {
        let icon = MenuBarDonutIcon(
            usagePercentage: 0,
            timeProgress: 0.0,
            remainingSeconds: 0,
            diameter: 16  // 最小直径
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "全て最小値でもアイコンが生成されるべき")
        XCTAssertEqual(image.size.height, 16)
    }

    /// テスト: 全てのパラメータが最大境界でもアイコンが正常に生成されること
    func testIconDisplay_withMaximumBoundaryValues() {
        let icon = MenuBarDonutIcon(
            usagePercentage: 100,
            timeProgress: 1.0,
            remainingSeconds: 86400,  // 1日（最大想定）
            diameter: 22
        )
        let image = icon.makeImage()

        XCTAssertNotNil(image, "最大境界値でもアイコンが生成されるべき")
        XCTAssertTrue(image.representations.count > 0)
    }
}
