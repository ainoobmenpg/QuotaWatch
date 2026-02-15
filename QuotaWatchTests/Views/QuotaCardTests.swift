//
//  QuotaCardTests.swift
//  QuotaWatchTests
//
//  QuotaCardコンポーネントのテスト
//

import XCTest
import SwiftUI
@testable import QuotaWatch

@MainActor
final class QuotaCardTests: XCTestCase {

    // MARK: - 基本的な作成テスト

    func testQuotaCardCreationWithTitle() {
        // タイトル付きでカードが作成できることを確認
        let card = QuotaCard(title: "テストカード") {
            Text("コンテンツ")
        }
        XCTAssertNotNil(card, "タイトル付きカードは生成されるべき")
    }

    func testQuotaCardCreationWithoutTitle() {
        // タイトルなしでカードが作成できることを確認
        let card = QuotaCard {
            Text("コンテンツ")
        }
        XCTAssertNotNil(card, "タイトルなしカードは生成されるべき")
    }

    func testQuotaCardWithGradientColors() {
        // グラデーション背景付きでカードが作成できることを確認
        let card = QuotaCard(
            title: "グラデーション",
            gradientColors: [.blue.opacity(0.3), .purple.opacity(0.3)]
        ) {
            Text("コンテンツ")
        }
        XCTAssertNotNil(card, "グラデーション付きカードは生成されるべき")
    }

    func testQuotaCardWithNilGradientColors() {
        // グラデーション背景なしでカードが作成できることを確認
        let card = QuotaCard(
            title: "ノーグラデーション",
            gradientColors: nil
        ) {
            Text("コンテンツ")
        }
        XCTAssertNotNil(card, "グラデーションなしカードは生成されるべき")
    }

    func testQuotaCardWithEmptyGradientColors() {
        // 空のグラデーション色配列でカードが作成できることを確認
        let card = QuotaCard(
            title: "空のグラデーション",
            gradientColors: []
        ) {
            Text("コンテンツ")
        }
        XCTAssertNotNil(card, "空のグラデーション配列でもカードは生成されるべき")
    }

    // MARK: - 様々なコンテンツのテスト

    func testQuotaCardWithComplexContent() {
        // 複雑なコンテンツでカードが作成できることを確認
        let card = QuotaCard(title: "複雑なコンテンツ") {
            VStack(spacing: 8) {
                HStack {
                    Text("ラベル")
                    Spacer()
                    Text("値")
                }
                Divider()
                Text("説明文")
            }
        }
        XCTAssertNotNil(card, "複雑なコンテンツでもカードは生成されるべき")
    }

    func testQuotaCardWithMultipleGradientStops() {
        // 複数のグラデーション色でカードが作成できることを確認
        let card = QuotaCard(
            title: "複数グラデーション",
            gradientColors: [
                .red.opacity(0.3),
                .orange.opacity(0.25),
                .yellow.opacity(0.2),
                .green.opacity(0.15)
            ]
        ) {
            Text("コンテンツ")
        }
        XCTAssertNotNil(card, "複数のグラデーション色でもカードは生成されるべき")
    }

    // MARK: - エッジケース

    func testQuotaCardWithEmptyTitle() {
        // 空のタイトルでカードが作成できることを確認
        let card = QuotaCard(title: "") {
            Text("コンテンツ")
        }
        XCTAssertNotNil(card, "空のタイトルでもカードは生成されるべき")
    }

    func testQuotaCardWithLongTitle() {
        // 長いタイトルでカードが作成できることを確認
        let longTitle = "非常に長いタイトルです。このタイトルはUIで適切に処理されるべきです。"
        let card = QuotaCard(title: longTitle) {
            Text("コンテンツ")
        }
        XCTAssertNotNil(card, "長いタイトルでもカードは生成されるべき")
    }

    func testQuotaCardWithSingleColor() {
        // 単一色のグラデーションでカードが作成できることを確認
        let card = QuotaCard(
            title: "単一色",
            gradientColors: [.blue.opacity(0.3)]
        ) {
            Text("コンテンツ")
        }
        XCTAssertNotNil(card, "単一色のグラデーションでもカードは生成されるべき")
    }
}
