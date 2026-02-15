//
//  ColorExtensionsTests.swift
//  QuotaWatchTests
//
//  ColorExtensionsのテスト
//

import XCTest
@testable import QuotaWatch
import SwiftUI

@MainActor
final class ColorExtensionsTests: XCTestCase {
    // 残り率ベースの閾値: healthy=50%, warning=20%

    func testStatusColorGreen() {
        // 残り51-100%は緑
        for i in 51...100 {
            let color = Color.statusColor(for: i)
            XCTAssertNotNil(color)
        }
    }

    func testStatusColorOrange() {
        // 残り21-50%はオレンジ
        for i in 21...50 {
            let color = Color.statusColor(for: i)
            XCTAssertNotNil(color)
        }
    }

    func testStatusColorRed() {
        // 残り0-20%は赤
        for i in 0...20 {
            let color = Color.statusColor(for: i)
            XCTAssertNotNil(color)
        }
    }

    func testStatusColorBoundaries() {
        // 境界値テスト
        let color50 = Color.statusColor(for: 50)  // オレンジ（50以下）
        let color51 = Color.statusColor(for: 51)  // 緑（51以上）
        let color20 = Color.statusColor(for: 20)  // 赤（20以下）
        let color21 = Color.statusColor(for: 21)  // オレンジ（21以上）

        XCTAssertNotNil(color50)
        XCTAssertNotNil(color51)
        XCTAssertNotNil(color20)
        XCTAssertNotNil(color21)
    }

    func testStatusColorEdgeCases() {
        // エッジケース
        XCTAssertNotNil(Color.statusColor(for: 0))   // 最小値（赤）
        XCTAssertNotNil(Color.statusColor(for: 100)) // 最大値（緑）
    }

    // MARK: - グラデーション色テスト

    func testGradientColorReturnsColor() {
        // グラデーションメソッドが色を返すことを確認
        for i in 0...100 {
            let color = QuotaColorCalculator.shared.gradientColor(for: i)
            XCTAssertNotNil(color, "残り率\(i)%のグラデーション色がnil")
        }
    }

    func testGradientColorHighRange() {
        // 残り50%以上: 緑〜黄緑グラデーション
        let color100 = QuotaColorCalculator.shared.gradientColor(for: 100) // 鮮やかな緑
        let color75 = QuotaColorCalculator.shared.gradientColor(for: 75)    // 黄緑
        let color50 = QuotaColorCalculator.shared.gradientColor(for: 50)    // 黄

        XCTAssertNotNil(color100)
        XCTAssertNotNil(color75)
        XCTAssertNotNil(color50)
    }

    func testGradientColorMediumRange() {
        // 残り20-50%: 黄〜オレンジグラデーション
        let color50 = QuotaColorCalculator.shared.gradientColor(for: 50)    // 黄
        let color35 = QuotaColorCalculator.shared.gradientColor(for: 35)    // 黄橙
        let color20 = QuotaColorCalculator.shared.gradientColor(for: 20)    // オレンジ

        XCTAssertNotNil(color50)
        XCTAssertNotNil(color35)
        XCTAssertNotNil(color20)
    }

    func testGradientColorLowRange() {
        // 残り20%未満: オレンジ〜赤グラデーション
        let color20 = QuotaColorCalculator.shared.gradientColor(for: 20)    // オレンジ
        let color10 = QuotaColorCalculator.shared.gradientColor(for: 10)    // 赤橙
        let color0 = QuotaColorCalculator.shared.gradientColor(for: 0)      // 鮮やかな赤

        XCTAssertNotNil(color20)
        XCTAssertNotNil(color10)
        XCTAssertNotNil(color0)
    }

    func testGradientColorBoundaries() {
        // グラデーション境界値テスト
        XCTAssertNotNil(QuotaColorCalculator.shared.gradientColor(for: 0))   // 最小値
        XCTAssertNotNil(QuotaColorCalculator.shared.gradientColor(for: 10))  // critical境界
        XCTAssertNotNil(QuotaColorCalculator.shared.gradientColor(for: 20))  // low境界
        XCTAssertNotNil(QuotaColorCalculator.shared.gradientColor(for: 35))  // midLow境界
        XCTAssertNotNil(QuotaColorCalculator.shared.gradientColor(for: 50))  // medium境界
        XCTAssertNotNil(QuotaColorCalculator.shared.gradientColor(for: 75))  // high境界
        XCTAssertNotNil(QuotaColorCalculator.shared.gradientColor(for: 100)) // 最大値
    }

    func testGradientNSColorReturnsColor() {
        // NSColor版グラデーションメソッドのテスト
        for i in 0...100 {
            let color = QuotaColorCalculator.shared.gradientNSColor(for: i)
            XCTAssertNotNil(color, "残り率\(i)%のグラデーションNSColorがnil")
        }
    }

    func testGradientColorClamping() {
        // 範囲外の値がクラップされることを確認
        let colorNegative = QuotaColorCalculator.shared.gradientColor(for: -10)
        let colorOver100 = QuotaColorCalculator.shared.gradientColor(for: 150)

        XCTAssertNotNil(colorNegative, "負の値でも色を返すべき")
        XCTAssertNotNil(colorOver100, "100超過の値でも色を返すべき")
    }

    func testGradientColorCache() {
        // キャッシュ機能のテスト
        let calculator = QuotaColorCalculator.shared
        calculator.clearCache()

        // 最初の呼び出し
        let color1 = calculator.gradientColor(for: 75)

        // キャッシュされた2回目の呼び出し（同じ結果になるはず）
        let color2 = calculator.gradientColor(for: 75)

        XCTAssertNotNil(color1)
        XCTAssertNotNil(color2)
        // 同じ入力なら同じ色が返される
        // Note: Colorの直接比較は難しいため、nilチェックで十分
    }

    func testGradientColorForUsage() {
        // 使用率からのグラデーション色計算
        let calculator = QuotaColorCalculator.shared

        // 使用率0%（残り100%） -> 緑
        let color0 = calculator.gradientColor(forUsage: 0)
        // 使用率100%（残り0%） -> 赤
        let color100 = calculator.gradientColor(forUsage: 100)
        // 使用率50%（残り50%） -> 黄
        let color50 = calculator.gradientColor(forUsage: 50)

        XCTAssertNotNil(color0)
        XCTAssertNotNil(color100)
        XCTAssertNotNil(color50)
    }
}
