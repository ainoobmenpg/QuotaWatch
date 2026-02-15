//
//  QuotaColorCalculator.swift
//  QuotaWatch
//
//  クォータ残り率に応じた色判定ロジック（一元管理）
//

import AppKit
import SwiftUI

/// クォータ残り率に応じた色を計算するユーティリティ
public enum QuotaColorCalculator {
    /// 残り率に応じたSwiftUI Colorを返す
    ///
    /// - Parameter remainingPercentage: 残りパーセンテージ（0-100）
    /// - Returns: 残り率に応じた色（緑: >50%, オレンジ: 20-50%, 赤: <=20%）
    public static func color(for remainingPercentage: Int) -> SwiftUI.Color {
        switch remainingPercentage {
        case AppConstants.quotaThresholdHealthy+1...100:
            return AppConstants.Color.SwiftUIColor.healthy
        case AppConstants.quotaThresholdWarning+1...AppConstants.quotaThresholdHealthy:
            return AppConstants.Color.SwiftUIColor.warning
        default:
            return AppConstants.Color.SwiftUIColor.critical
        }
    }

    /// 残り率に応じたAppKit NSColorを返す
    ///
    /// - Parameter remainingPercentage: 残りパーセンテージ（0-100）
    /// - Returns: 残り率に応じた色（緑: >50%, オレンジ: 20-50%, 赤: <=20%）
    public static func nsColor(for remainingPercentage: Int) -> AppKit.NSColor {
        switch remainingPercentage {
        case AppConstants.quotaThresholdHealthy+1...100:
            return AppConstants.Color.NSColor.healthy
        case AppConstants.quotaThresholdWarning+1...AppConstants.quotaThresholdHealthy:
            return AppConstants.Color.NSColor.warning
        default:
            return AppConstants.Color.NSColor.critical
        }
    }

    /// 使用率から色を判定する簡易メソッド
    ///
    /// - Parameter usagePercentage: 使用率（0-100）
    /// - Returns: 使用率に応じた色（使用率が低いほど緑、高いほど赤）
    public static func color(forUsage usagePercentage: Int) -> SwiftUI.Color {
        let remaining = max(100 - usagePercentage, 0)
        return color(for: remaining)
    }

    /// 使用率からNSColorを判定する簡易メソッド
    ///
    /// - Parameter usagePercentage: 使用率（0-100）
    /// - Returns: 使用率に応じた色（使用率が低いほど緑、高いほど赤）
    public static func nsColor(forUsage usagePercentage: Int) -> AppKit.NSColor {
        let remaining = max(100 - usagePercentage, 0)
        return nsColor(for: remaining)
    }
}
