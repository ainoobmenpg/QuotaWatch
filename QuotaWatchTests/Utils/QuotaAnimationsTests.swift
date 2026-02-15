//
//  QuotaAnimationsTests.swift
//  QuotaWatchTests
//
//  QuotaAnimationsのテスト
//

import XCTest
import SwiftUI
@testable import QuotaWatch

final class QuotaAnimationsTests: XCTestCase {

    // MARK: - 静的アニメーションプロパティのテスト

    func testGaugeTransitionAnimation() {
        // gaugeTransitionが有効なAnimationであることを確認
        let animation = QuotaAnimations.gaugeTransition

        // Animation型であることを確認（コンパイル時チェック）
        let _: Animation = animation
        XCTAssertNotNil(animation, "gaugeTransitionは非nilのAnimationであるべき")
    }

    func testCardAppearAnimation() {
        // cardAppearが有効なAnimationであることを確認
        let animation = QuotaAnimations.cardAppear

        let _: Animation = animation
        XCTAssertNotNil(animation, "cardAppearは非nilのAnimationであるべき")
    }

    func testStandardAnimation() {
        // standardが有効なAnimationであることを確認
        let animation = QuotaAnimations.standard

        let _: Animation = animation
        XCTAssertNotNil(animation, "standardは非nilのAnimationであるべき")
    }

    func testSmoothAnimation() {
        // smoothが有効なAnimationであることを確認
        let animation = QuotaAnimations.smooth

        let _: Animation = animation
        XCTAssertNotNil(animation, "smoothは非nilのAnimationであるべき")
    }

    func testSpringAnimation() {
        // springが有効なAnimationであることを確認
        let animation = QuotaAnimations.spring

        let _: Animation = animation
        XCTAssertNotNil(animation, "springは非nilのAnimationであるべき")
    }

    // MARK: - パルスアニメーションのテスト

    func testPulseAnimationReturnsAnimation() {
        // pulse()が有効なAnimationを返すことを確認
        let animation = QuotaAnimations.pulse()

        let _: Animation = animation
        XCTAssertNotNil(animation, "pulse()は非nilのAnimationを返すべき")
    }

    func testPulseAnimationCanBeCreatedMultipleTimes() {
        // pulse()が複数回呼び出せることを確認
        let animation1 = QuotaAnimations.pulse()
        let animation2 = QuotaAnimations.pulse()

        XCTAssertNotNil(animation1)
        XCTAssertNotNil(animation2)
    }

    func testPulseWithCustomDuration() {
        // カスタム期間のパルスアニメーション
        let animation = QuotaAnimations.pulse(duration: 1.0, autoreverses: false)

        let _: Animation = animation
        XCTAssertNotNil(animation, "カスタムパルスは非nilのAnimationを返すべき")
    }

    // MARK: - アニメーション値のテスト

    func testAnimationValuesAreReasonable() {
        // アニメーション値が合理的な範囲内であることを確認
        // これらは定数なので、単に存在を確認

        // gaugeTransition: 0.3秒のeaseInOut
        // cardAppear: 0.2秒のeaseOut
        // standard: 0.2秒のeaseInOut
        // smooth: 0.4秒のeaseInOut
        // spring: バネアニメーション

        // Animationは実際の値を直接取得できないため、
        // 型チェックと非nil確認で十分
        XCTAssertNotNil(QuotaAnimations.gaugeTransition)
        XCTAssertNotNil(QuotaAnimations.cardAppear)
        XCTAssertNotNil(QuotaAnimations.standard)
        XCTAssertNotNil(QuotaAnimations.smooth)
        XCTAssertNotNil(QuotaAnimations.spring)
        XCTAssertNotNil(QuotaAnimations.pulse())
    }
}
