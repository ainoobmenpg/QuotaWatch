//
//  QuotaGauge.swift
//  QuotaWatch
//
//  円形Gaugeコンポーネント（色分けロジック含む）
//

import SwiftUI
import Charts

/// 円形Gaugeコンポーネント
///
/// 残り率に応じた色分け（緑/オレンジ/赤）を適用した円形グラフを表示します。
/// 中央に残りパーセンテージを表示します。
struct QuotaGauge: View {
    /// 使用率（0-100）
    let percentage: Int

    /// サイズ
    var size: CGFloat = 60

    /// 残りパーセンテージ
    private var remainingPercentage: Int {
        max(100 - percentage, 0)
    }

    var body: some View {
        Gauge(value: Double(remainingPercentage), in: 0...100) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(Color.statusColor(for: remainingPercentage))
        .frame(width: size, height: size)
        .overlay {
            Text("\(remainingPercentage)%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - ドーナツチャート（メニューバー表示用）

/// メニューバー表示用の円グラフ（ドーナツチャート）
/// 残り部分をメインの色で塗りつぶします
struct MenuBarDonutChart: View {
    /// 使用率（0-100）
    let percentage: Int

    /// サイズ
    let size: CGFloat

    /// 使用率（0-1）
    private var usageRatio: Double {
        return min(Double(percentage) / 100.0, 1.0)
    }

    /// 残りの割合（0-1）
    private var remainingRatio: Double {
        return max(1.0 - usageRatio, 0.0)
    }

    /// 残りパーセンテージ
    private var remainingPercentage: Int {
        max(100 - percentage, 0)
    }

    /// 色の決定（残り率に応じて変化）
    private var chartColor: Color {
        if remainingPercentage > AppConstants.quotaThresholdHealthy {
            return AppConstants.Color.SwiftUIColor.healthy
        } else if remainingPercentage > AppConstants.quotaThresholdWarning {
            return AppConstants.Color.SwiftUIColor.warning
        } else {
            return AppConstants.Color.SwiftUIColor.critical
        }
    }

    var body: some View {
        Chart {
            // 残りセクター（メインの色）
            SectorMark(
                angle: .value("残り", Double(remainingPercentage)),
                innerRadius: .ratio(0.6),
                outerRadius: .ratio(1.0),
                angularInset: 1.0
            )
            .foregroundStyle(chartColor)

            // 使用済みセクター（薄い色）
            SectorMark(
                angle: .value("使用済み", Double(percentage)),
                innerRadius: .ratio(0.6),
                outerRadius: .ratio(1.0),
                angularInset: 1.0
            )
            .foregroundStyle(Color.secondary.opacity(0.15))
        }
        .frame(width: size, height: size)
        .chartLegend(.hidden)
    }
}

/// メニューバー表示用の複合円グラフ
/// 残り率と残り時間を2つの円グラフで並べて表示（残り強調）
struct MenuBarDoubleDonutChart: View {
    /// 使用率（0-100）
    let usagePercentage: Int

    /// 残り時間の進捗（0-1）
    let timeProgress: Double

    /// 各グラフのサイズ
    let size: CGFloat

    /// 残りパーセンテージ
    private var remainingPercentage: Int {
        max(100 - usagePercentage, 0)
    }

    /// ステータス色（残り率ベース）
    private var statusColor: Color {
        if remainingPercentage > AppConstants.quotaThresholdHealthy {
            return AppConstants.Color.SwiftUIColor.healthy
        } else if remainingPercentage > AppConstants.quotaThresholdWarning {
            return AppConstants.Color.SwiftUIColor.warning
        } else {
            return AppConstants.Color.SwiftUIColor.critical
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            // 残り率グラフ + ラベル
            HStack(spacing: 2) {
                Text("📊")
                    .font(.system(size: 10))

                Chart {
                    // 残りセクター（メインの色）
                    SectorMark(
                        angle: .value("残り", Double(remainingPercentage)),
                        innerRadius: .ratio(0.6),
                        outerRadius: .ratio(1.0),
                        angularInset: 1.0
                    )
                    .foregroundStyle(statusColor)

                    // 使用済みセクター（薄い色）
                    SectorMark(
                        angle: .value("使用済み", Double(usagePercentage)),
                        innerRadius: .ratio(0.6),
                        outerRadius: .ratio(1.0),
                        angularInset: 1.0
                    )
                    .foregroundStyle(Color.secondary.opacity(0.15))
                }
                .frame(width: size, height: size)
                .chartLegend(.hidden)
            }

            // 残り時間グラフ + ラベル
            HStack(spacing: 2) {
                Text("⏰")
                    .font(.system(size: 10))

                Chart {
                    // 残り時間セクター（メインの色）
                    SectorMark(
                        angle: .value("残り", (1.0 - timeProgress) * 100),
                        innerRadius: .ratio(0.6),
                        outerRadius: .ratio(1.0),
                        angularInset: 1.0
                    )
                    .foregroundStyle(Color.blue)

                    // 経過セクター（薄い色）
                    SectorMark(
                        angle: .value("経過", timeProgress * 100),
                        innerRadius: .ratio(0.6),
                        outerRadius: .ratio(1.0),
                        angularInset: 1.0
                    )
                    .foregroundStyle(Color.secondary.opacity(0.15))
                }
                .frame(width: size, height: size)
                .chartLegend(.hidden)
            }
        }
        .frame(height: size)
    }
}
