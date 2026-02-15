//
//  QuotaColorCalculator.swift
//  QuotaWatch
//
//  クォータ残り率に応じた色判定ロジック（一元管理）
//

import AppKit
import SwiftUI

/// クォータ残り率に応じた色を計算するユーティリティ（キャッシュ機能付き）
///
/// @MainActorによるスレッドセーフな実装で、同じ入力に対してはキャッシュされた結果を返します。
/// これにより、円グラフの再描画時などに不要な再計算を防ぎます。
@MainActor
public final class QuotaColorCalculator {

    // MARK: - Singleton

    public static let shared = QuotaColorCalculator()

    private init() {}

    // MARK: - Cache

    /// SwiftUI Colorのキャッシュ
    private struct ColorCache {
        let lastInput: Int
        let color: SwiftUI.Color
        let useGradient: Bool
    }

    /// NSColorのキャッシュ
    private struct NSColorCache {
        let lastInput: Int
        let color: AppKit.NSColor
        let useGradient: Bool
    }

    private var colorCache: ColorCache?
    private var nsColorCache: NSColorCache?

    // MARK: - Public Methods

    /// 残り率に応じたSwiftUI Colorを返す
    ///
    /// - Parameter remainingPercentage: 残りパーセンテージ（0-100）
    /// - Returns: 残り率に応じた色（緑: >50%, オレンジ: 20-50%, 赤: <=20%）
    public func color(for remainingPercentage: Int) -> SwiftUI.Color {
        // キャッシュヒット確認（グラデーションなしのデフォルト動作）
        if let cache = colorCache, cache.lastInput == remainingPercentage, !cache.useGradient {
            return cache.color
        }

        // 計算実行
        let computedColor: SwiftUI.Color
        switch remainingPercentage {
        case AppConstants.quotaThresholdHealthy+1...100:
            computedColor = AppConstants.Color.SwiftUIColor.healthy
        case AppConstants.quotaThresholdWarning+1...AppConstants.quotaThresholdHealthy:
            computedColor = AppConstants.Color.SwiftUIColor.warning
        default:
            computedColor = AppConstants.Color.SwiftUIColor.critical
        }

        // キャッシュ更新
        colorCache = ColorCache(lastInput: remainingPercentage, color: computedColor, useGradient: false)
        return computedColor
    }

    /// 残り率に応じたグラデーション色を返す
    ///
    /// - Parameter remainingPercentage: 残りパーセンテージ（0-100）
    /// - Returns: 残り率に応じた補間色（緑〜黄〜オレンジ〜赤のスムーズなグラデーション）
    public func gradientColor(for remainingPercentage: Int) -> SwiftUI.Color {
        let clamped = max(0, min(100, remainingPercentage))

        // キャッシュヒット確認
        if let cache = colorCache, cache.lastInput == clamped, cache.useGradient {
            return cache.color
        }

        // グラデーション計算
        let rgb: AppConstants.Color.RGB
        switch clamped {
        case AppConstants.Color.GradientBoundary.high...100:
            // 75-100%: 黄緑〜鮮やかな緑
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.yellowGreen,
                to: AppConstants.Color.GradientStop.fullGreen,
                percentage: Double(clamped - AppConstants.Color.GradientBoundary.high) / 25.0
            )
        case AppConstants.Color.GradientBoundary.medium..<AppConstants.Color.GradientBoundary.high:
            // 50-75%: 黄〜黄緑
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.yellow,
                to: AppConstants.Color.GradientStop.yellowGreen,
                percentage: Double(clamped - AppConstants.Color.GradientBoundary.medium) / 25.0
            )
        case AppConstants.Color.GradientBoundary.midLow..<AppConstants.Color.GradientBoundary.medium:
            // 35-50%: 黄橙〜黄
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.yellowOrange,
                to: AppConstants.Color.GradientStop.yellow,
                percentage: Double(clamped - AppConstants.Color.GradientBoundary.midLow) / 15.0
            )
        case AppConstants.Color.GradientBoundary.low..<AppConstants.Color.GradientBoundary.midLow:
            // 20-35%: オレンジ〜黄橙
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.orange,
                to: AppConstants.Color.GradientStop.yellowOrange,
                percentage: Double(clamped - AppConstants.Color.GradientBoundary.low) / 15.0
            )
        case AppConstants.Color.GradientBoundary.critical..<AppConstants.Color.GradientBoundary.low:
            // 10-20%: 赤橙〜オレンジ
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.redOrange,
                to: AppConstants.Color.GradientStop.orange,
                percentage: Double(clamped - AppConstants.Color.GradientBoundary.critical) / 10.0
            )
        default:
            // 0-10%: 鮮やかな赤〜赤橙
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.fullRed,
                to: AppConstants.Color.GradientStop.redOrange,
                percentage: Double(clamped) / 10.0
            )
        }

        let computedColor = SwiftUI.Color(
            red: Double(rgb.red),
            green: Double(rgb.green),
            blue: Double(rgb.blue)
        )

        // キャッシュ更新
        colorCache = ColorCache(lastInput: clamped, color: computedColor, useGradient: true)
        return computedColor
    }

    /// 残り率に応じたAppKit NSColorを返す
    ///
    /// - Parameter remainingPercentage: 残りパーセンテージ（0-100）
    /// - Returns: 残り率に応じた色（緑: >50%, オレンジ: 20-50%, 赤: <=20%）
    public func nsColor(for remainingPercentage: Int) -> AppKit.NSColor {
        // キャッシュヒット確認
        if let cache = nsColorCache, cache.lastInput == remainingPercentage, !cache.useGradient {
            return cache.color
        }

        // 計算実行
        let computedColor: AppKit.NSColor
        switch remainingPercentage {
        case AppConstants.quotaThresholdHealthy+1...100:
            computedColor = AppConstants.Color.NSColor.healthy
        case AppConstants.quotaThresholdWarning+1...AppConstants.quotaThresholdHealthy:
            computedColor = AppConstants.Color.NSColor.warning
        default:
            computedColor = AppConstants.Color.NSColor.critical
        }

        // キャッシュ更新
        nsColorCache = NSColorCache(lastInput: remainingPercentage, color: computedColor, useGradient: false)
        return computedColor
    }

    /// 残り率に応じたグラデーションNSColorを返す
    ///
    /// - Parameter remainingPercentage: 残りパーセンテージ（0-100）
    /// - Returns: 残り率に応じた補間色（緑〜黄〜オレンジ〜赤のスムーズなグラデーション）
    public func gradientNSColor(for remainingPercentage: Int) -> AppKit.NSColor {
        let clamped = max(0, min(100, remainingPercentage))

        // キャッシュヒット確認
        if let cache = nsColorCache, cache.lastInput == clamped, cache.useGradient {
            return cache.color
        }

        // グラデーション計算（SwiftUI版と共通のロジック）
        let rgb: AppConstants.Color.RGB
        switch clamped {
        case AppConstants.Color.GradientBoundary.high...100:
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.yellowGreen,
                to: AppConstants.Color.GradientStop.fullGreen,
                percentage: Double(clamped - AppConstants.Color.GradientBoundary.high) / 25.0
            )
        case AppConstants.Color.GradientBoundary.medium..<AppConstants.Color.GradientBoundary.high:
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.yellow,
                to: AppConstants.Color.GradientStop.yellowGreen,
                percentage: Double(clamped - AppConstants.Color.GradientBoundary.medium) / 25.0
            )
        case AppConstants.Color.GradientBoundary.midLow..<AppConstants.Color.GradientBoundary.medium:
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.yellowOrange,
                to: AppConstants.Color.GradientStop.yellow,
                percentage: Double(clamped - AppConstants.Color.GradientBoundary.midLow) / 15.0
            )
        case AppConstants.Color.GradientBoundary.low..<AppConstants.Color.GradientBoundary.midLow:
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.orange,
                to: AppConstants.Color.GradientStop.yellowOrange,
                percentage: Double(clamped - AppConstants.Color.GradientBoundary.low) / 15.0
            )
        case AppConstants.Color.GradientBoundary.critical..<AppConstants.Color.GradientBoundary.low:
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.redOrange,
                to: AppConstants.Color.GradientStop.orange,
                percentage: Double(clamped - AppConstants.Color.GradientBoundary.critical) / 10.0
            )
        default:
            rgb = interpolateColor(
                from: AppConstants.Color.GradientStop.fullRed,
                to: AppConstants.Color.GradientStop.redOrange,
                percentage: Double(clamped) / 10.0
            )
        }

        let computedColor = AppKit.NSColor(
            srgbRed: rgb.red,
            green: rgb.green,
            blue: rgb.blue,
            alpha: 1.0
        )

        // キャッシュ更新
        nsColorCache = NSColorCache(lastInput: clamped, color: computedColor, useGradient: true)
        return computedColor
    }

    /// 使用率から色を判定する簡易メソッド
    ///
    /// - Parameter usagePercentage: 使用率（0-100）
    /// - Returns: 使用率に応じた色（使用率が低いほど緑、高いほど赤）
    public func color(forUsage usagePercentage: Int) -> SwiftUI.Color {
        let remaining = max(100 - usagePercentage, 0)
        return color(for: remaining)
    }

    /// 使用率からグラデーション色を判定する簡易メソッド
    ///
    /// - Parameter usagePercentage: 使用率（0-100）
    /// - Returns: 使用率に応じたグラデーション色
    public func gradientColor(forUsage usagePercentage: Int) -> SwiftUI.Color {
        let remaining = max(100 - usagePercentage, 0)
        return gradientColor(for: remaining)
    }

    /// 使用率からNSColorを判定する簡易メソッド
    ///
    /// - Parameter usagePercentage: 使用率（0-100）
    /// - Returns: 使用率に応じた色（使用率が低いほど緑、高いほど赤）
    public func nsColor(forUsage usagePercentage: Int) -> AppKit.NSColor {
        let remaining = max(100 - usagePercentage, 0)
        return nsColor(for: remaining)
    }

    /// 使用率からグラデーションNSColorを判定する簡易メソッド
    ///
    /// - Parameter usagePercentage: 使用率（0-100）
    /// - Returns: 使用率に応じたグラデーション色
    public func gradientNSColor(forUsage usagePercentage: Int) -> AppKit.NSColor {
        let remaining = max(100 - usagePercentage, 0)
        return gradientNSColor(for: remaining)
    }

    // MARK: - Private Methods

    /// 2色間の線形補間を行う
    ///
    /// - Parameters:
    ///   - from: 開始色
    ///   - to: 終了色
    ///   - percentage: 補間率（0.0-1.0）
    /// - Returns: 補間された色
    private func interpolateColor(
        from: AppConstants.Color.RGB,
        to: AppConstants.Color.RGB,
        percentage: Double
    ) -> AppConstants.Color.RGB {
        let t = max(0.0, min(1.0, percentage))
        return AppConstants.Color.RGB(
            red: from.red + (to.red - from.red) * CGFloat(t),
            green: from.green + (to.green - from.green) * CGFloat(t),
            blue: from.blue + (to.blue - from.blue) * CGFloat(t)
        )
    }

    // MARK: - Cache Management

    /// キャッシュをクリアする（テスト用）
    public func clearCache() {
        colorCache = nil
        nsColorCache = nil
    }
}
