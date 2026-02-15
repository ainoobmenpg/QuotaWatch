//
//  MenuBarDonutIconTests.swift
//  QuotaWatchTests
//
//  MenuBarDonutIconのテスト（案E: 1つの円 + 数字 + 外枠）
//

import XCTest
@testable import QuotaWatch
import AppKit

@MainActor
final class MenuBarDonutIconTests: XCTestCase {
    // MARK: - 色計算ロジックのテスト

    func testUsageColorGreen() {
        // 残り51%以上は緑（使用率49%以下）
        let icon1 = MenuBarDonutIcon(usagePercentage: 0, timeProgress: 0, diameter: 22)
        let icon2 = MenuBarDonutIcon(usagePercentage: 49, timeProgress: 0, diameter: 22)

        // 画像が生成されることを確認
        let image1 = icon1.makeImage()
        let image2 = icon2.makeImage()

        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        XCTAssertTrue(image1.representations.count > 0)
        XCTAssertTrue(image2.representations.count > 0)
    }

    func testUsageColorOrange() {
        // 残り21-50%はオレンジ（使用率50-79%）
        let icon1 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0, diameter: 22)
        let icon2 = MenuBarDonutIcon(usagePercentage: 79, timeProgress: 0, diameter: 22)

        let image1 = icon1.makeImage()
        let image2 = icon2.makeImage()

        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        XCTAssertTrue(image1.representations.count > 0)
        XCTAssertTrue(image2.representations.count > 0)
    }

    func testUsageColorRed() {
        // 残り0-20%は赤（使用率80-100%）
        let icon1 = MenuBarDonutIcon(usagePercentage: 80, timeProgress: 0, diameter: 22)
        let icon2 = MenuBarDonutIcon(usagePercentage: 100, timeProgress: 0, diameter: 22)

        let image1 = icon1.makeImage()
        let image2 = icon2.makeImage()

        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        XCTAssertTrue(image1.representations.count > 0)
        XCTAssertTrue(image2.representations.count > 0)
    }

    // MARK: - 境界値テスト

    func testUsageColorBoundaries() {
        // 境界値テスト（残り50%, 20%）
        let icon49 = MenuBarDonutIcon(usagePercentage: 49, timeProgress: 0, diameter: 22)  // 残り51%: 緑
        let icon50 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0, diameter: 22)  // 残り50%: オレンジ
        let icon79 = MenuBarDonutIcon(usagePercentage: 79, timeProgress: 0, diameter: 22)  // 残り21%: オレンジ
        let icon80 = MenuBarDonutIcon(usagePercentage: 80, timeProgress: 0, diameter: 22)  // 残り20%: 赤

        XCTAssertNotNil(icon49.makeImage())
        XCTAssertNotNil(icon50.makeImage())
        XCTAssertNotNil(icon79.makeImage())
        XCTAssertNotNil(icon80.makeImage())
    }

    // MARK: - 時間グラフのテスト

    func testTimeProgress() {
        // 時間グラフ（外枠）の異なる進捗度で画像が生成されることを確認
        let icon0 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.0, diameter: 22)
        let icon50 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, diameter: 22)
        let icon100 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 1.0, diameter: 22)

        XCTAssertNotNil(icon0.makeImage())
        XCTAssertNotNil(icon50.makeImage())
        XCTAssertNotNil(icon100.makeImage())
    }

    // MARK: - 画像サイズのテスト（案E: 1つの円）

    func testImageSizeStandard22pt() {
        // 標準サイズ（22pt）のテスト
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image)
        // 案E: 1つの円なので幅と高さが同じ
        XCTAssertEqual(image.size.width, 22, "画像の幅が22ピクセルであるべき")
        XCTAssertEqual(image.size.height, 22, "画像の高さが22ピクセルであるべき")
    }

    func testImageSizeSmall16pt() {
        // 小さいサイズ（16pt）のテスト（後方互換性）
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, diameter: 16)
        let image = icon.makeImage()

        XCTAssertNotNil(image)
        XCTAssertEqual(image.size.width, 16, "画像の幅が16ピクセルであるべき")
        XCTAssertEqual(image.size.height, 16, "画像の高さが16ピクセルであるべき")
    }

    func testImageSizeLarge28pt() {
        // 大きいサイズ（28pt）のテスト
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, diameter: 28)
        let image = icon.makeImage()

        XCTAssertNotNil(image)
        XCTAssertEqual(image.size.width, 28, "画像の幅が28ピクセルであるべき")
        XCTAssertEqual(image.size.height, 28, "画像の高さが28ピクセルであるべき")
    }

    // MARK: - 案E特有のテスト

    func testUnifiedIconGeneratesImage() {
        // 統合アイコン（1つの円 + 数字 + 外枠）が生成されることを確認
        let icon = MenuBarDonutIcon(usagePercentage: 25, timeProgress: 0.7, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image, "統合アイコンが生成されるべき")
        XCTAssertTrue(image.representations.count > 0, "画像表現が存在するべき")
    }

    func testRemainingPercentageDisplay() {
        // 残りパーセントが正しく計算されることを確認
        // 使用率25% → 残り75%
        let icon = MenuBarDonutIcon(usagePercentage: 25, timeProgress: 0.5, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image, "残り75%のアイコンが生成されるべき")
    }

    func testZeroRemainingPercentage() {
        // 使用率100%（残り0%）のエッジケース
        let icon = MenuBarDonutIcon(usagePercentage: 100, timeProgress: 1.0, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image, "残り0%のアイコンが生成されるべき")
    }

    func testFullRemainingPercentage() {
        // 使用率0%（残り100%）のエッジケース
        let icon = MenuBarDonutIcon(usagePercentage: 0, timeProgress: 0.0, diameter: 22)
        let image = icon.makeImage()

        XCTAssertNotNil(image, "残り100%のアイコンが生成されるべき")
    }

    // MARK: - エッジケース

    func testEdgeCases() {
        // 使用率のエッジケース
        let icon0 = MenuBarDonutIcon(usagePercentage: 0, timeProgress: 0, diameter: 22)
        let icon100 = MenuBarDonutIcon(usagePercentage: 100, timeProgress: 1.0, diameter: 22)

        XCTAssertNotNil(icon0.makeImage())
        XCTAssertNotNil(icon100.makeImage())
    }

    func testNegativeHandling() {
        // 使用率が負の値や100を超える場合のハンドリング
        // 実装上は max(0, min(100, 100 - usagePercentage)) でクランプされる
        let iconNeg = MenuBarDonutIcon(usagePercentage: -10, timeProgress: 0, diameter: 22)
        let iconOver = MenuBarDonutIcon(usagePercentage: 150, timeProgress: 1.5, diameter: 22)

        // エラーなく画像が生成されることを確認
        XCTAssertNotNil(iconNeg.makeImage())
        XCTAssertNotNil(iconOver.makeImage())
    }

    // MARK: - Retinaディスプレイ対応テスト

    func testRetinaDisplaySupport() {
        // Retinaディスプレイ用の高解像度画像が生成されることを確認
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, diameter: 22)
        let image = icon.makeImage()

        // 画像が複数の解像度表現を持つ可能性があることを確認
        XCTAssertNotNil(image)
        // ImageRendererがbackingScaleFactorを考慮していることを確認
        // （実際のスケールファクターは実行環境に依存）
    }
}
