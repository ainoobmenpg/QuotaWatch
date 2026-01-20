//
//  SecondaryQuotaView.swift
//  QuotaWatch
//
//  セカンダリクォータ表示セクション
//

import SwiftUI
import Charts

/// セカンダリクォータ表示ビュー
///
/// UsageLimit一覧を表示し、それぞれの使用率に応じた色分けを適用します。
struct SecondaryQuotaView: View {
    /// セカンダリクォータのリスト
    let limits: [UsageLimit]

    /// 表示する最大数（これ以上は省略）
    var maxCount: Int = 3

    var body: some View {
        if !displayedLimits.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("その他のクォータ")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(displayedLimits) { limit in
                        secondaryLimitRow(limit)
                    }

                    if limits.count > maxCount {
                        Text("+ \(limits.count - maxCount)件のクォータ")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    /// 表示するクォータリスト
    private var displayedLimits: [UsageLimit] {
        Array(limits.prefix(maxCount))
    }

    /// セカンダリクォータ行を表示
    @ViewBuilder
    private func secondaryLimitRow(_ limit: UsageLimit) -> some View {
        HStack(spacing: 8) {
            // ドーナツチャート（残り強調）
            if let pct = limit.pct {
                SecondaryDonutChart(percentage: pct, size: 24)
            }

            // ラベルと詳細情報
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(limit.label)
                        .font(.caption)
                        .foregroundStyle(.primary)

                    if let pct = limit.pct {
                        Text("\(pct)%")
                            .font(.caption)
                            .foregroundStyle(Color.statusColor(for: max(100 - pct, 0)))
                    }

                    Spacer()

                    if let resetEpoch = limit.resetEpoch {
                        Text(TimeFormatter.formatTimeRemaining(resetEpoch: resetEpoch))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

/// セカンダリクォータ用の小型ドーナツチャート
/// 残り部分をメインの色で塗りつぶします
struct SecondaryDonutChart: View {
    /// 使用率（0-100）
    let percentage: Int

    /// サイズ
    let size: CGFloat

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
                angularInset: 1.5
            )
            .foregroundStyle(chartColor)

            // 使用済みセクター（薄い色）
            SectorMark(
                angle: .value("使用済み", Double(percentage)),
                innerRadius: .ratio(0.6),
                outerRadius: .ratio(1.0),
                angularInset: 1.5
            )
            .foregroundStyle(Color.secondary.opacity(0.15))
        }
        .frame(width: size, height: size)
        .chartLegend(.hidden)
    }
}
