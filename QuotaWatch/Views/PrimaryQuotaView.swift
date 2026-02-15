//
//  PrimaryQuotaView.swift
//  QuotaWatch
//
//  プライマリクォータ表示セクション
//

import SwiftUI

/// プライマリクォータ表示ビュー
///
/// Gauge（円形グラフ）＋ 線形ProgressViewを併用し、
/// 使用量/上限/残りとリセット時刻を表示します。
@MainActor
struct PrimaryQuotaView: View, Equatable {
    /// フォーマット定数
    private enum Format {
        static let decimal = "%.1f"
        static let integer = "%.0f"
    }

    /// スナップショット
    let snapshot: UsageSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Text(snapshot.primaryTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                // 残り時間
                if let resetEpoch = snapshot.resetEpoch {
                    Text(TimeFormatter.formatTimeRemaining(resetEpoch: resetEpoch))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // ゲージと詳細情報
            HStack(spacing: 16) {
                // 円形ゲージ
                if let pct = snapshot.primaryPct {
                    QuotaGauge(percentage: pct, size: 60)
                }

                // 詳細情報
                VStack(alignment: .leading, spacing: 4) {
                    // 残量（最優先情報）
                    if let remaining = snapshot.primaryRemaining,
                       let total = snapshot.primaryTotal {
                        usageRow(label: "残り", value: formatNumber(remaining), total: formatNumber(total))
                    }

                    // 使用量
                    if let used = snapshot.primaryUsed {
                        usageRow(label: "使用済み", value: formatNumber(used))
                    }

                    if let resetEpoch = snapshot.resetEpoch {
                        HStack {
                            Text("リセット:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(TimeFormatter.formatResetTime(resetEpoch: resetEpoch))
                                .font(.caption2)
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Spacer()
            }

        }
    }

    /// 使用量行を表示
    @ViewBuilder
    private func usageRow(label: String, value: String, total: String? = nil) -> some View {
        HStack {
            Text("\(label):")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let total = total {
                Text("\(value) / \(total)")
                    .font(.caption2)
                    .foregroundStyle(.primary)
            } else {
                Text(value)
                    .font(.caption2)
                    .foregroundStyle(.primary)
            }
        }
    }

    /// 数値をフォーマット（大きな数値はK/Mで簡略表示）
    private func formatNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            let millions = value / 1_000_000
            return String(format: Format.decimal + "M", millions)
        } else if value >= 1_000 {
            let thousands = value / 1_000
            return String(format: Format.decimal + "K", thousands)
        } else {
            return String(format: Format.integer, value)
        }
    }

    // MARK: - Equatable

    nonisolated static func == (lhs: PrimaryQuotaView, rhs: PrimaryQuotaView) -> Bool {
        lhs.snapshot == rhs.snapshot
    }
}
