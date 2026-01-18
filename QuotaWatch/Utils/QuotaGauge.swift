//
//  QuotaGauge.swift
//  QuotaWatch
//
//  円形Gaugeコンポーネント（色分けロジック含む）
//

import SwiftUI

/// 円形Gaugeコンポーネント
///
/// 使用率に応じた色分け（緑/オレンジ/赤）を適用した円形グラフを表示します。
struct QuotaGauge: View {
    /// 使用率（0-100）
    let percentage: Int

    /// サイズ
    var size: CGFloat = 60

    var body: some View {
        Gauge(value: Double(percentage), in: 0...100) {
            Text("\(percentage)%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.usageColor(for: percentage))
        } currentValueLabel: {
            EmptyView()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(Color.usageColor(for: percentage))
        .frame(width: size, height: size)
    }
}
