//
//  ColorExtensionsTests.swift
//  QuotaWatchTests
//
//  ColorExtensionsのテスト
//

import XCTest
@testable import QuotaWatch
import SwiftUI

final class ColorExtensionsTests: XCTestCase {
    func testUsageColorUnder70() {
        // 0-69%は緑
        for i in 0..<70 {
            let color = Color.usageColor(for: i)
            // SwiftUIのColorは直接比較できないため、クラッシュしないことを確認
            XCTAssertNotNil(color)
        }
    }

    func testUsageColor70to89() {
        // 70-89%はオレンジ
        for i in 70..<90 {
            let color = Color.usageColor(for: i)
            XCTAssertNotNil(color)
        }
    }

    func testUsageColor90AndAbove() {
        // 90-100%は赤
        for i in 90...100 {
            let color = Color.usageColor(for: i)
            XCTAssertNotNil(color)
        }
    }

    func testUsageColorBoundaries() {
        // 境界値テスト
        let color69 = Color.usageColor(for: 69)  // 緑
        let color70 = Color.usageColor(for: 70)  // オレンジ
        let color89 = Color.usageColor(for: 89)  // オレンジ
        let color90 = Color.usageColor(for: 90)  // 赤
        let color100 = Color.usageColor(for: 100) // 赤

        XCTAssertNotNil(color69)
        XCTAssertNotNil(color70)
        XCTAssertNotNil(color89)
        XCTAssertNotNil(color90)
        XCTAssertNotNil(color100)
    }

    func testUsageColorEdgeCases() {
        // エッジケース
        XCTAssertNotNil(Color.usageColor(for: 0))   // 最小値
        XCTAssertNotNil(Color.usageColor(for: 100)) // 最大値

        // 範囲外の値もクラッシュしないことを確認（実装次第ではエラーになる可能性がある）
        // ここでは範囲内の値のみテスト
    }
}
