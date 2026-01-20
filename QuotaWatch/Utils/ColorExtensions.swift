//
//  ColorExtensions.swift
//  QuotaWatch
//
//  Color拡張 - ステータスに応じた色分け
//

import SwiftUI

extension Color {
    /// 残り率に応じたステータス色を返す
    ///
    /// - Parameter percentage: 残りパーセンテージ（0-100）
    /// - Returns: 残り率に応じた色（緑: >50%, オレンジ: 20-50%, 赤: <20%）
    static func statusColor(for percentage: Int) -> Color {
        switch percentage {
        case AppConstants.quotaThresholdHealthy+1...100:
            return AppConstants.Color.SwiftUIColor.healthy
        case AppConstants.quotaThresholdWarning+1...AppConstants.quotaThresholdHealthy:
            return AppConstants.Color.SwiftUIColor.warning
        default:
            return AppConstants.Color.SwiftUIColor.critical
        }
    }
}
