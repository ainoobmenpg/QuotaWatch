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
    }

    /// NSColorのキャッシュ
    private struct NSColorCache {
        let lastInput: Int
        let color: AppKit.NSColor
    }

    private var colorCache: ColorCache?
    private var nsColorCache: NSColorCache?

    // MARK: - Public Methods

    /// 残り率に応じたSwiftUI Colorを返す
    ///
    /// - Parameter remainingPercentage: 残りパーセンテージ（0-100）
    /// - Returns: 残り率に応じた色（緑: >50%, オレンジ: 20-50%, 赤: <=20%）
    public func color(for remainingPercentage: Int) -> SwiftUI.Color {
        // キャッシュヒット確認
        if let cache = colorCache, cache.lastInput == remainingPercentage {
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
        colorCache = ColorCache(lastInput: remainingPercentage, color: computedColor)
        return computedColor
    }

    /// 残り率に応じたAppKit NSColorを返す
    ///
    /// - Parameter remainingPercentage: 残りパーセンテージ（0-100）
    /// - Returns: 残り率に応じた色（緑: >50%, オレンジ: 20-50%, 赤: <=20%）
    public func nsColor(for remainingPercentage: Int) -> AppKit.NSColor {
        // キャッシュヒット確認
        if let cache = nsColorCache, cache.lastInput == remainingPercentage {
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
        nsColorCache = NSColorCache(lastInput: remainingPercentage, color: computedColor)
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

    /// 使用率からNSColorを判定する簡易メソッド
    ///
    /// - Parameter usagePercentage: 使用率（0-100）
    /// - Returns: 使用率に応じた色（使用率が低いほど緑、高いほど赤）
    public func nsColor(forUsage usagePercentage: Int) -> AppKit.NSColor {
        let remaining = max(100 - usagePercentage, 0)
        return nsColor(for: remaining)
    }

    // MARK: - Cache Management

    /// キャッシュをクリアする（テスト用）
    public func clearCache() {
        colorCache = nil
        nsColorCache = nil
    }
}
