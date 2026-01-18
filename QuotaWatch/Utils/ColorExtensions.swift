//
//  ColorExtensions.swift
//  QuotaWatch
//
//  Color拡張 - 使用率に応じた色分け
//

import SwiftUI

extension Color {
    /// 使用率に応じた色を返す
    ///
    /// - Parameter percentage: 使用率（0-100）
    /// - Returns: 使用率に応じた色（緑<70% / オレンジ70-90% / 赤>90%）
    static func usageColor(for percentage: Int) -> Color {
        switch percentage {
        case 0..<70:
            return .green
        case 70..<90:
            return .orange
        default:
            return .red
        }
    }
}
