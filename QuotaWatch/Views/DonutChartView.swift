//
//  DonutChartView.swift
//  QuotaWatch
//
//  円グラフ（ドーナツチャート）コンポーネント
//

import SwiftUI
import Charts

/// ドーナツチャートView
/// 残り部分をメインの色で塗りつぶし、中央に残りパーセンテージを表示
struct DonutChartView: View {
    /// 使用量
    let used: Double

    /// 総量
    let total: Double

    /// サイズ
    let size: CGFloat

    /// 使用率（0-1）
    private var usageRatio: Double {
        guard total > 0 else { return 0 }
        return min(used / total, 1.0)
    }

    /// 残量
    private var remaining: Double {
        max(total - used, 0)
    }

    /// 残り率（0-1）
    private var remainingRatio: Double {
        guard total > 0 else { return 1.0 }
        return max(1.0 - usageRatio, 0.0)
    }

    /// 残りパーセンテージ
    private var remainingPercentage: Int {
        Int(remainingRatio * 100)
    }

    /// 色の決定（残り率に応じて変化）
    private var chartColor: Color {
        let ratio = remainingRatio
        let thresholdHealthy = Double(AppConstants.quotaThresholdHealthy) / 100.0
        let thresholdWarning = Double(AppConstants.quotaThresholdWarning) / 100.0
        if ratio > thresholdHealthy {
            return AppConstants.Color.SwiftUIColor.healthy
        } else if ratio > thresholdWarning {
            return AppConstants.Color.SwiftUIColor.warning
        } else {
            return AppConstants.Color.SwiftUIColor.critical
        }
    }

    var body: some View {
        Chart {
            // 残りセクター（メインの色）
            SectorMark(
                angle: .value("残り", remaining),
                innerRadius: .ratio(0.6),
                outerRadius: .ratio(1.0),
                angularInset: 2.0
            )
            .foregroundStyle(chartColor)

            // 使用済みセクター（薄い色）
            SectorMark(
                angle: .value("使用済み", used),
                innerRadius: .ratio(0.6),
                outerRadius: .ratio(1.0),
                angularInset: 2.0
            )
            .foregroundStyle(Color.secondary.opacity(0.2))
        }
        .frame(width: size, height: size)
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                if let frame = chartProxy.plotFrame {
                    // 中央に残りパーセンテージを表示（白色）
                    Text("\(remainingPercentage)%")
                        .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .position(x: geometry[frame].midX, y: geometry[frame].midY)
                }
            }
        }
    }
}

/// メニューバー表示用の円グラフ（テキストなし、シンプル版）
/// 残り部分をメインの色で塗りつぶします
struct MenuBarDonutChartView: View {
    /// 使用量
    let used: Double

    /// 総量
    let total: Double

    /// サイズ
    let size: CGFloat

    /// 使用率（0-1）
    private var usageRatio: Double {
        guard total > 0 else { return 0 }
        return min(used / total, 1.0)
    }

    /// 残り率（0-1）
    private var remainingRatio: Double {
        guard total > 0 else { return 1.0 }
        return max(1.0 - usageRatio, 0.0)
    }

    /// 残りパーセンテージ
    private var remainingPercentage: Int {
        Int(remainingRatio * 100)
    }

    /// 色の決定（残り率に応じて変化）
    private var chartColor: Color {
        let ratio = remainingRatio
        let thresholdHealthy = Double(AppConstants.quotaThresholdHealthy) / 100.0
        let thresholdWarning = Double(AppConstants.quotaThresholdWarning) / 100.0
        if ratio > thresholdHealthy {
            return AppConstants.Color.SwiftUIColor.healthy
        } else if ratio > thresholdWarning {
            return AppConstants.Color.SwiftUIColor.warning
        } else {
            return AppConstants.Color.SwiftUIColor.critical
        }
    }

    var body: some View {
        Chart {
            // 残りセクター（メインの色）
            SectorMark(
                angle: .value("残り", max(total - used, 0)),
                innerRadius: .ratio(0.6),
                outerRadius: .ratio(1.0),
                angularInset: 1.0
            )
            .foregroundStyle(chartColor)

            // 使用済みセクター（薄い色）
            SectorMark(
                angle: .value("使用済み", used),
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

#Preview {
    VStack(spacing: 20) {
        // 大きいサイズ（ポップアップ内用）
        DonutChartView(used: 3.5, total: 5.0, size: 120)
            .frame(width: 150, height: 150)

        // 小さいサイズ（メニューバー用）
        MenuBarDonutChartView(used: 3.5, total: 5.0, size: 18)
            .frame(width: 30, height: 30)

        HStack(spacing: 20) {
            MenuBarDonutChartView(used: 1.0, total: 5.0, size: 18)  // 緑
            MenuBarDonutChartView(used: 3.5, total: 5.0, size: 18)  // オレンジ
            MenuBarDonutChartView(used: 4.5, total: 5.0, size: 18)  // 赤
        }
    }
    .padding()
}
