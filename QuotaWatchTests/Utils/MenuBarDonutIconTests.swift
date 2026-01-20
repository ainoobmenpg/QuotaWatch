//
//  MenuBarDonutIconTests.swift
//  QuotaWatchTests
//
//  MenuBarDonutIconのテスト
//

import XCTest
@testable import QuotaWatch
import AppKit

final class MenuBarDonutIconTests: XCTestCase {
    // MARK: - 色計算ロジックのテスト

    func testUsageColorGreen() {
        // 残り51%以上は緑（使用率49%以下）
        let icon1 = MenuBarDonutIcon(usagePercentage: 0, timeProgress: 0, diameter: 16)
        let icon2 = MenuBarDonutIcon(usagePercentage: 49, timeProgress: 0, diameter: 16)

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
        let icon1 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0, diameter: 16)
        let icon2 = MenuBarDonutIcon(usagePercentage: 79, timeProgress: 0, diameter: 16)

        let image1 = icon1.makeImage()
        let image2 = icon2.makeImage()

        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        XCTAssertTrue(image1.representations.count > 0)
        XCTAssertTrue(image2.representations.count > 0)
    }

    func testUsageColorRed() {
        // 残り0-20%は赤（使用率80-100%）
        let icon1 = MenuBarDonutIcon(usagePercentage: 80, timeProgress: 0, diameter: 16)
        let icon2 = MenuBarDonutIcon(usagePercentage: 100, timeProgress: 0, diameter: 16)

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
        let icon49 = MenuBarDonutIcon(usagePercentage: 49, timeProgress: 0, diameter: 16)  // 残り51%: 緑
        let icon50 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0, diameter: 16)  // 残り50%: オレンジ
        let icon79 = MenuBarDonutIcon(usagePercentage: 79, timeProgress: 0, diameter: 16)  // 残り21%: オレンジ
        let icon80 = MenuBarDonutIcon(usagePercentage: 80, timeProgress: 0, diameter: 16)  // 残り20%: 赤

        XCTAssertNotNil(icon49.makeImage())
        XCTAssertNotNil(icon50.makeImage())
        XCTAssertNotNil(icon79.makeImage())
        XCTAssertNotNil(icon80.makeImage())
    }

    // MARK: - 時間グラフのテスト

    func testTimeProgress() {
        // 時間グラフの異なる進捗度で画像が生成されることを確認
        let icon0 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.0, diameter: 16)
        let icon50 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, diameter: 16)
        let icon100 = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 1.0, diameter: 16)

        XCTAssertNotNil(icon0.makeImage())
        XCTAssertNotNil(icon50.makeImage())
        XCTAssertNotNil(icon100.makeImage())
    }

    // MARK: - 画像サイズのテスト

    func testImageSize() {
        let icon = MenuBarDonutIcon(usagePercentage: 50, timeProgress: 0.5, diameter: 16)
        let image = icon.makeImage()

        XCTAssertNotNil(image)
        // 画像サイズが適切に設定されていることを確認
        // 絵文字(10pt) + 円グラフ(16pt) + スペース(2pt) × 2 + グラフ間スペース(8pt) = 約48pt幅
        XCTAssertTrue(image.size.width > 40, "画像の幅が40ピクセル以上であるべき")
        XCTAssertEqual(image.size.height, 16, "画像の高さが16ピクセルであるべき")
    }

    // MARK: - エッジケース

    func testEdgeCases() {
        // 使用率のエッジケース
        let icon0 = MenuBarDonutIcon(usagePercentage: 0, timeProgress: 0, diameter: 16)
        let icon100 = MenuBarDonutIcon(usagePercentage: 100, timeProgress: 1.0, diameter: 16)

        XCTAssertNotNil(icon0.makeImage())
        XCTAssertNotNil(icon100.makeImage())
    }
}
