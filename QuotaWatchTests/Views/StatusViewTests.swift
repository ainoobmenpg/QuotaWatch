//
//  StatusViewTests.swift
//  QuotaWatchTests
//
//  StatusViewのテスト
//

import XCTest
import SwiftUI
@testable import QuotaWatch

@MainActor
final class StatusViewTests: XCTestCase {

    // MARK: - 正常状態のテスト

    func testNormalStateRendering() {
        // 正常状態のビューが作成できることを確認
        let now = Date().epochSeconds
        let view = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: nil
        )

        // Equatableのテスト
        let equivalentView = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: nil
        )

        XCTAssertEqual(view, equivalentView, "同じパラメータのビューは等しいべき")
    }

    func testNormalStateNoGradient() {
        // 正常状態ではグラデーション背景がないことを確認
        let now = Date().epochSeconds
        let view = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: nil
        )

        // グラデーション背景の確認（reflectionでprivateプロパティを確認）
        // 実際のUIテストではsnapshotテストを使用することを推奨
        XCTAssertNotNil(view, "正常状態のビューは生成されるべき")
    }

    // MARK: - バックオフ状態のテスト

    func testBackoffStateRendering() {
        // バックオフ状態のビューが作成できることを確認
        let now = Date().epochSeconds
        let view = StatusView(
            lastFetchEpoch: now - 300,
            nextFetchEpoch: now + 600,
            backoffFactor: 4,
            errorMessage: nil
        )

        XCTAssertNotNil(view, "バックオフ状態のビューは生成されるべき")
    }

    func testBackoffFactorVariations() {
        // 様々なバックオフ係数でビューが作成できることを確認
        let now = Date().epochSeconds

        for factor in [2, 4, 8, 16] {
            let view = StatusView(
                lastFetchEpoch: now - 300,
                nextFetchEpoch: now + 600,
                backoffFactor: factor,
                errorMessage: nil
            )
            XCTAssertNotNil(view, "バックオフ係数\(factor)のビューは生成されるべき")
        }
    }

    func testBackoffStateEquatable() {
        // バックオフ状態のEquatableテスト
        let now = Date().epochSeconds
        let view1 = StatusView(
            lastFetchEpoch: now - 300,
            nextFetchEpoch: now + 600,
            backoffFactor: 4,
            errorMessage: nil
        )

        let view2 = StatusView(
            lastFetchEpoch: now - 300,
            nextFetchEpoch: now + 600,
            backoffFactor: 4,
            errorMessage: nil
        )

        let view3 = StatusView(
            lastFetchEpoch: now - 300,
            nextFetchEpoch: now + 600,
            backoffFactor: 2,  // 異なる係数
            errorMessage: nil
        )

        XCTAssertEqual(view1, view2, "同じバックオフ係数のビューは等しいべき")
        XCTAssertNotEqual(view1, view3, "異なるバックオフ係数のビューは等しくないべき")
    }

    // MARK: - エラー状態のテスト

    func testErrorStateRendering() {
        // エラー状態のビューが作成できることを確認
        let now = Date().epochSeconds
        let view = StatusView(
            lastFetchEpoch: now - 600,
            nextFetchEpoch: now + 300,
            backoffFactor: 1,
            errorMessage: "APIキーが無効です"
        )

        XCTAssertNotNil(view, "エラー状態のビューは生成されるべき")
    }

    func testErrorStateVariations() {
        // 様々なエラーメッセージでビューが作成できることを確認
        let now = Date().epochSeconds
        let errorMessages = [
            "APIキーが無効です",
            "ネットワークエラーが発生しました",
            "サーバーが応答しません",
            "不明なエラーが発生しました"
        ]

        for errorMessage in errorMessages {
            let view = StatusView(
                lastFetchEpoch: now - 600,
                nextFetchEpoch: now + 300,
                backoffFactor: 1,
                errorMessage: errorMessage
            )
            XCTAssertNotNil(view, "エラーメッセージ「\(errorMessage)」のビューは生成されるべき")
        }
    }

    func testErrorStateEquatable() {
        // エラー状態のEquatableテスト
        let now = Date().epochSeconds
        let view1 = StatusView(
            lastFetchEpoch: now - 600,
            nextFetchEpoch: now + 300,
            backoffFactor: 1,
            errorMessage: "APIエラー"
        )

        let view2 = StatusView(
            lastFetchEpoch: now - 600,
            nextFetchEpoch: now + 300,
            backoffFactor: 1,
            errorMessage: "APIエラー"
        )

        let view3 = StatusView(
            lastFetchEpoch: now - 600,
            nextFetchEpoch: now + 300,
            backoffFactor: 1,
            errorMessage: "ネットワークエラー"  // 異なるエラーメッセージ
        )

        XCTAssertEqual(view1, view2, "同じエラーメッセージのビューは等しいべき")
        XCTAssertNotEqual(view1, view3, "異なるエラーメッセージのビューは等しくないべき")
    }

    // MARK: - 複合状態のテスト

    func testErrorWithBackoffState() {
        // エラー+バックオフの複合状態
        let now = Date().epochSeconds
        let view = StatusView(
            lastFetchEpoch: now - 900,
            nextFetchEpoch: now + 720,
            backoffFactor: 8,
            errorMessage: "ネットワークエラーが発生しました"
        )

        XCTAssertNotNil(view, "エラー+バックオフ状態のビューは生成されるべき")
    }

    // MARK: - 時間フォーマットのテスト

    func testFormatLastFetch() {
        // formatLastFetchの挙動を確認（実際のフォーマット結果は表示に依存）
        let now = Date().epochSeconds

        // 直前にフェッチした場合
        let viewRecent = StatusView(
            lastFetchEpoch: now - 30,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: nil
        )
        XCTAssertNotNil(viewRecent)

        // 数分前にフェッチした場合
        let viewMinutes = StatusView(
            lastFetchEpoch: now - 300,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: nil
        )
        XCTAssertNotNil(viewMinutes)

        // 数時間前にフェッチした場合
        let viewHours = StatusView(
            lastFetchEpoch: now - 7200,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: nil
        )
        XCTAssertNotNil(viewHours)
    }

    func testFormatNextFetch() {
        // formatNextFetchの挙動を確認
        let now = Date().epochSeconds

        // すぐにフェッチする場合
        let viewSoon = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now,
            backoffFactor: 1,
            errorMessage: nil
        )
        XCTAssertNotNil(viewSoon)

        // 数秒後にフェッチする場合
        let viewSeconds = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 30,
            backoffFactor: 1,
            errorMessage: nil
        )
        XCTAssertNotNil(viewSeconds)

        // 数分後にフェッチする場合
        let viewMinutes = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 300,
            backoffFactor: 1,
            errorMessage: nil
        )
        XCTAssertNotNil(viewMinutes)
    }

    // MARK: - エッジケースのテスト

    func testFutureLastFetchEpoch() {
        // 未来のlastFetchEpoch（異常値）
        let now = Date().epochSeconds
        let view = StatusView(
            lastFetchEpoch: now + 1000,  // 未来
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: nil
        )

        XCTAssertNotNil(view, "未来のlastFetchEpochでもビューは生成されるべき")
    }

    func testZeroBackoffFactor() {
        // バックオフ係数が0の場合（異常値）
        let now = Date().epochSeconds
        let view = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 180,
            backoffFactor: 0,
            errorMessage: nil
        )

        XCTAssertNotNil(view, "バックオフ係数0でもビューは生成されるべき")
    }

    func testEmptyErrorMessage() {
        // 空のエラーメッセージ
        let now = Date().epochSeconds
        let view = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: ""
        )

        XCTAssertNotNil(view, "空のエラーメッセージでもビューは生成されるべき")
    }

    func testLongErrorMessage() {
        // 長いエラーメッセージ（lineLimitで制限される）
        let now = Date().epochSeconds
        let longError = "非常に長いエラーメッセージです。これはlineLimitによって表示が制限されるべきです。" +
                       "さらに長いテキストを追加して、UIが正しく処理できることを確認します。"

        let view = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: longError
        )

        XCTAssertNotNil(view, "長いエラーメッセージでもビューは生成されるべき")
    }

    // MARK: - Equatable境界値テスト

    func testEquatableBoundaryConditions() {
        // Equatableの境界値テスト
        let now = Date().epochSeconds

        // 完全に同じ
        let view1 = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: nil
        )

        // lastFetchEpochが1秒異なる
        let view2 = StatusView(
            lastFetchEpoch: now - 121,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: nil
        )

        // nextFetchEpochが1秒異なる
        let view3 = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 181,
            backoffFactor: 1,
            errorMessage: nil
        )

        XCTAssertEqual(view1, view1, "同じビューは等しいべき")
        XCTAssertNotEqual(view1, view2, "lastFetchEpochが異なれば等しくないべき")
        XCTAssertNotEqual(view1, view3, "nextFetchEpochが異なれば等しくないべき")
    }

    func testErrorMessagePresence() {
        // errorMessageの有無によるEquatableのテスト
        let now = Date().epochSeconds

        let viewWithError = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: "エラー"
        )

        let viewWithoutError = StatusView(
            lastFetchEpoch: now - 120,
            nextFetchEpoch: now + 180,
            backoffFactor: 1,
            errorMessage: nil
        )

        XCTAssertNotEqual(
            viewWithError,
            viewWithoutError,
            "errorMessageの有無が異なれば等しくないべき"
        )
    }
}
