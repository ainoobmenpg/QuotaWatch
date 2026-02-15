//
//  QuotaAnimations.swift
//  QuotaWatch
//
//  統一されたアニメーション効果を提供するユーティリティ
//

import SwiftUI

/// アニメーション効果を定義するユーティリティ
public enum QuotaAnimations {
    /// ゲージの値変化アニメーション（0.3秒）
    public static let gaugeTransition: Animation = .easeInOut(duration: 0.3)

    /// カード出現時のフェードインアニメーション（0.2秒）
    public static let cardAppear: Animation = .easeOut(duration: 0.2)

    /// 標準のインタラクションアニメーション
    public static let standard: Animation = .easeInOut(duration: 0.2)

    /// 遅めのスムーズアニメーション
    public static let smooth: Animation = .easeInOut(duration: 0.4)

    /// バネ効果を含むアニメーション
    public static let spring: Animation = .spring(response: 0.3, dampingFraction: 0.7)

    /// パルスエフェクト（警告時に使用）
    /// - Returns: 繰り返しパルスアニメーション
    public static func pulse() -> Animation {
        .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
    }

    /// カスタムパルスエフェクト
    /// - Parameters:
    ///   - duration: 1サイクルの秒数
    ///   - autoreverses: 自動反転するかどうか
    /// - Returns: パルスアニメーション
    public static func pulse(duration: Double, autoreverses: Bool = true) -> Animation {
        .easeInOut(duration: duration).repeatForever(autoreverses: autoreverses)
    }
}

/// View拡張機能 - アニメーション修飾子
extension View {
    /// ゲージのアニメーションを適用
    /// - Returns: アニメーション適用後のView
    public func gaugeAnimated<T>(value: T) -> some View where T: Equatable {
        self.animation(QuotaAnimations.gaugeTransition, value: value)
    }

    /// カード出現時のトランジションを適用
    /// - Returns: トランジション設定済みのView
    public func cardAppearTransition() -> some View {
        self.transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    /// 標準アニメーションを適用
    /// - Parameter value: アニメーション対象の値
    /// - Returns: アニメーション適用後のView
    public func standardAnimated<T>(value: T) -> some View where T: Equatable {
        self.animation(QuotaAnimations.standard, value: value)
    }

    /// スムーズアニメーションを適用
    /// - Parameter value: アニメーション対象の値
    /// - Returns: アニメーション適用後のView
    public func smoothAnimated<T>(value: T) -> some View where T: Equatable {
        self.animation(QuotaAnimations.smooth, value: value)
    }

    /// バネアニメーションを適用
    /// - Parameter value: アニメーション対象の値
    /// - Returns: アニメーション適用後のView
    public func springAnimated<T>(value: T) -> some View where T: Equatable {
        self.animation(QuotaAnimations.spring, value: value)
    }

    /// パルスエフェクトを適用（警告時などに使用）
    /// - Returns: パルスエフェクト適用後のView
    public func pulsing() -> some View {
        self.animation(QuotaAnimations.pulse(), value: UUID())
    }
}

/// トランジション関連の拡張機能
extension View {
    /// フェードイン + スライドインのトランジション
    /// - Parameter edge: スライド方向（デフォルトは下から）
    /// - Returns: トランジション適用後のView
    public func fadeSlideTransition(edge: Edge = .bottom) -> some View {
        self.transition(.move(edge: edge).combined(with: .opacity))
    }

    /// スケールインのトランジション
    /// - Parameter scale: 初期スケール（デフォルトは0.9）
    /// - Returns: トランジション適用後のView
    public func scaleInTransition(scale: CGFloat = 0.9) -> some View {
        self.transition(.scale(scale: scale).combined(with: .opacity))
    }
}
