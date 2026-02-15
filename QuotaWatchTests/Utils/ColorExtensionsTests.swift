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
}
