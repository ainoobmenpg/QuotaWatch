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
/// UsageLimit一覧を横並びのカード形式で表示し、それぞれの使用率に応じた色分けを適用します。
/// percentageのみのデータもサポートします。
@MainActor
struct SecondaryQuotaView: View, Equatable {
    @Environment(\.colorScheme) private var colorScheme
    /// セカンダリクォータのリスト
    let limits: [UsageLimit]

    /// 表示する最大数（これ以上は省略）
    var maxCount: Int = 3

    var body: some View {
        if !displayedLimits.isEmpty {
            QuotaCard(title: "その他のクォータ") {
                // 横並びレイアウト
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(displayedLimits) { limit in
                            secondaryQuotaCard(limit)
                        }

                        // 追加インジケーター
                        if limits.count > maxCount {
                            moreIndicator
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("その他のクォータ、\(displayedLimits.count)件表示中")
        }
    }

    /// 表示するクォータリスト
    private var displayedLimits: [UsageLimit] {
        Array(limits.prefix(maxCount))
    }

    /// セカンダリクォータカード（小型）
    @ViewBuilder
    private func secondaryQuotaCard(_ limit: UsageLimit) -> some View {
        let cardWidth: CGFloat = limit.usageDetails.isEmpty ? 80 : 110

        VStack(spacing: 8) {
            // 小型円グラフ（32pt）
            secondaryGauge(for: limit)

            // ラベル
            Text(limit.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: cardWidth - 16)

            // 使用率または残り量表示
            VStack(alignment: .leading, spacing: 2) {
                if let pct = limit.pct {
                    Text("\(pct)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(percentageColor(pct))
                } else if let remaining = limit.remaining {
                    Text(formatRemaining(remaining))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("N/A")
                        .font(.caption)
                        .foregroundStyle(Color.secondary.opacity(0.6))
                }

                // リセット時刻
                if let resetEpoch = limit.resetEpoch {
                    Text(TimeFormatter.formatTimeRemaining(resetEpoch: resetEpoch))
                        .font(.caption2)
                        .foregroundStyle(Color.secondary.opacity(0.6))
                }

                // MCPサービス内訳（usageDetails）
                if !limit.usageDetails.isEmpty {
                    Divider()
                        .padding(.vertical, 2)

                    ForEach(limit.usageDetails.prefix(3)) { detail in
                        HStack(spacing: 4) {
                            Text(formatUsageDetailLabel(detail.modelCode))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(detail.usage)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // 省略インジケーター
                    if limit.usageDetails.count > 3 {
                        Text("+\(limit.usageDetails.count - 3) more")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.secondary.opacity(0.6))
                    }
                }
            }
        }
        .frame(width: cardWidth)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }

    /// セカンダリ用小型ゲージ（32pt）
    @ViewBuilder
    private func secondaryGauge(for limit: UsageLimit) -> some View {
        let size: CGFloat = 32

        if let pct = limit.pct {
            // percentageがある場合は円グラフを表示
            let remaining = max(100 - pct, 0)
            let color = QuotaColorCalculator.shared.color(for: remaining)

            Chart {
                // 残りセクター（メインの色）
                SectorMark(
                    angle: .value("残り", Double(remaining)),
                    innerRadius: .ratio(0.6),
                    outerRadius: .ratio(1.0),
                    angularInset: 1.5
                )
                .foregroundStyle(color)

                // 使用済みセクター（薄い色）
                SectorMark(
                    angle: .value("使用済み", Double(pct)),
                    innerRadius: .ratio(0.6),
                    outerRadius: .ratio(1.0),
                    angularInset: 1.5
                )
                .foregroundStyle(Color.secondary.opacity(0.15))
            }
            .frame(width: size, height: size)
            .chartLegend(.hidden)
        } else if let remaining = limit.remaining, let total = limit.total {
            // usageがないがremaining/totalがある場合は残り量を表示
            let pct = Int((remaining / total) * 100)
            let color = QuotaColorCalculator.shared.color(for: pct)

            Chart {
                SectorMark(
                    angle: .value("残り", Double(pct)),
                    innerRadius: .ratio(0.6),
                    outerRadius: .ratio(1.0),
                    angularInset: 1.5
                )
                .foregroundStyle(color)

                SectorMark(
                    angle: .value("使用済み", Double(100 - pct)),
                    innerRadius: .ratio(0.6),
                    outerRadius: .ratio(1.0),
                    angularInset: 1.5
                )
                .foregroundStyle(Color.secondary.opacity(0.15))
            }
            .frame(width: size, height: size)
            .chartLegend(.hidden)
        } else {
            // データ不足の場合はプレースホルダー
            Circle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "questionmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
        }
    }

    /// 追加インジケーター（省略されたクォータ数を表示）
    private var moreIndicator: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay {
                    Text("+\(limits.count - maxCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

            Text("その他")
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.8))
        }
        .frame(width: 80)
        .padding(.vertical, 8)
    }

    /// 残り量のフォーマット
    private func formatRemaining(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }

    /// 使用率に応じた色を返す
    private func percentageColor(_ pct: Int) -> Color {
        let remaining = max(100 - pct, 0)
        return QuotaColorCalculator.shared.color(for: remaining)
    }

    // MARK: - Equatable

    nonisolated static func == (lhs: SecondaryQuotaView, rhs: SecondaryQuotaView) -> Bool {
        lhs.limits == rhs.limits && lhs.maxCount == rhs.maxCount
    }
}

// MARK: - Preview

#Preview("セカンダリクォータ") {
    SecondaryQuotaView(limits: [
        UsageLimit(label: "Monthly", pct: 75, used: 750, total: 1000, remaining: 250, resetEpoch: nil),
        UsageLimit(label: "Daily", pct: 30, used: 30, total: 100, remaining: 70, resetEpoch: nil),
        UsageLimit(label: "Reader", pct: nil, used: nil, total: 500, remaining: 500, resetEpoch: nil)
    ])
    .frame(width: 350)
    .padding()
}

#Preview("percentageのみ") {
    SecondaryQuotaView(limits: [
        UsageLimit(label: "Monthly", pct: 90, used: nil, total: nil, remaining: nil, resetEpoch: nil),
        UsageLimit(label: "Daily", pct: 45, used: nil, total: nil, remaining: nil, resetEpoch: nil)
    ])
    .frame(width: 300)
    .padding()
}

#Preview("TIME_LIMIT（内訳付き）") {
    SecondaryQuotaView(limits: [
        UsageLimit(
            label: "Time Limit",
            pct: 4,
            used: 42,
            total: 1000,
            remaining: 958,
            resetEpoch: Int(Date().timeIntervalSince1970) + 300 * 3600 + 4 * 60,
            usageDetails: [
                UsageDetail(modelCode: "search-prime", usage: 35),
                UsageDetail(modelCode: "web-reader", usage: 7),
                UsageDetail(modelCode: "zread", usage: 0)
            ]
        )
    ])
    .frame(width: 350)
    .padding()
}

#Preview("大量のクォータ") {
    SecondaryQuotaView(limits: [
        UsageLimit(label: "Monthly", pct: 75, used: 750, total: 1000, remaining: 250, resetEpoch: nil),
        UsageLimit(label: "Daily", pct: 30, used: 30, total: 100, remaining: 70, resetEpoch: nil),
        UsageLimit(label: "Reader", pct: 50, used: 50, total: 100, remaining: 50, resetEpoch: nil),
        UsageLimit(label: "ZRead", pct: 20, used: 20, total: 100, remaining: 80, resetEpoch: nil)
    ], maxCount: 3)
    .frame(width: 350)
    .padding()
}

#Preview("空の状態") {
    SecondaryQuotaView(limits: [])
    .frame(width: 300)
    .padding()
}
