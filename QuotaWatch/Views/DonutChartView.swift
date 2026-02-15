//
//  DonutChartView.swift
//  QuotaWatch
//
//  円グラフ（ドーナツチャート）コンポーネント
//

import SwiftUI
import Charts

// MARK: - Base Protocol

/// 円グラフコンポーネントの共通プロトコル
///
/// 残り率に応じた色分けを適用した円形グラフを表示するコンポーネントの基底プロトコル。
@MainActor
protocol BaseDonutChartProtocol: View {
    /// 残りパーセンテージ（0-100）
    var remainingPercentage: Int { get }

    /// グラフのサイズ
    var size: CGFloat { get }

    /// 残り率に応じた色を計算する
    func chartColor(for remainingPercentage: Int) -> Color
}

// MARK: - Default Implementation

extension BaseDonutChartProtocol {
    /// デフォルトの色計算実装
    func chartColor(for remainingPercentage: Int) -> Color {
        QuotaColorCalculator.shared.color(for: remainingPercentage)
    }
}

// MARK: - Donut Chart View

/// ドーナツチャートView
/// 残り部分をメインの色で塗りつぶし、中央に残りパーセンテージを表示
struct DonutChartView: BaseDonutChartProtocol {
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
    var remainingPercentage: Int {
        Int(remainingRatio * 100)
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
            .foregroundStyle(chartColor(for: remainingPercentage))

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

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // 大きいサイズ（ポップアップ内用）
        DonutChartView(used: 3.5, total: 5.0, size: 120)
            .frame(width: 150, height: 150)

        // 小さいサイズ（メニューバー用）- percentageベース
        MenuBarDonutChart(percentage: 70, size: 18)
            .frame(width: 30, height: 30)

        HStack(spacing: 20) {
            MenuBarDonutChart(percentage: 20, size: 18)  // 緑
            MenuBarDonutChart(percentage: 70, size: 18)  // オレンジ
            MenuBarDonutChart(percentage: 90, size: 18)  // 赤
        }
    }
    .padding()
}
