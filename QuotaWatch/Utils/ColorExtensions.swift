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
    /// - Returns: 残り率に応じた色（緑: >50%, オレンジ: 20-50%, 赤: <=20%）
    static func statusColor(for percentage: Int) -> Color {
        QuotaColorCalculator.color(for: percentage)
    }
}
