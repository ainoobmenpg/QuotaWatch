//
//  QuotaGauge.swift
//  QuotaWatch
//
//  円形Gaugeコンポーネント（色分けロジック含む）
//

import SwiftUI
import Charts

// MARK: - Base Protocol

/// 円グラフコンポーネントの共通プロトコル
///
/// 残り率に応じた色分けを適用した円形グラフを表示するコンポーネントの基底プロトコル。
@MainActor
protocol BaseDonutChart: View {
    /// 残りパーセンテージ（0-100）
    var remainingPercentage: Int { get }

    /// グラフのサイズ
    var size: CGFloat { get }

    /// 残り率に応じた色を計算する
    func chartColor(for remainingPercentage: Int) -> Color
}

// MARK: - Default Implementation

extension BaseDonutChart {
    /// デフォルトの色計算実装
    func chartColor(for remainingPercentage: Int) -> Color {
        QuotaColorCalculator.shared.color(for: remainingPercentage)
    }
}

// MARK: - Gauge Based Component

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
        .tint(QuotaColorCalculator.shared.color(for: remainingPercentage))
        .frame(width: size, height: size)
        .overlay {
            Text("\(remainingPercentage)%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("クォータ残量ゲージ")
        .accessibilityValue("\(remainingPercentage)パーセント残り")
    }
}

// MARK: - Donut Chart Components

/// メニューバー表示用の円グラフ（ドーナツチャート）
/// 残り部分をメインの色で塗りつぶします
struct MenuBarDonutChart: BaseDonutChart {
    /// 使用率（0-100）
    let percentage: Int

    /// サイズ
    let size: CGFloat

    /// 残りパーセンテージ
    var remainingPercentage: Int {
        max(100 - percentage, 0)
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
            .foregroundStyle(chartColor(for: remainingPercentage))

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
struct MenuBarDoubleDonutChart: BaseDonutChart {
    /// 使用率（0-100）
    let usagePercentage: Int

    /// 残り時間の進捗（0-1）
    let timeProgress: Double

    /// 各グラフのサイズ
    let size: CGFloat

    /// 残りパーセンテージ
    var remainingPercentage: Int {
        max(100 - usagePercentage, 0)
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
                    .foregroundStyle(chartColor(for: remainingPercentage))

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
