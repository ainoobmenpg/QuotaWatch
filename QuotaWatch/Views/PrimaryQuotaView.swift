//
//  PrimaryQuotaView.swift
//  QuotaWatch
//
//  プライマリクォータ表示セクション
//

import SwiftUI

/// プライマリクォータ表示ビュー
///
/// QuotaCardを使用して、大きな円形ゲージと残量情報を
/// 見やすく表示します。リセット時刻はリアルタイムで更新されます。
@MainActor
struct PrimaryQuotaView: View, Equatable {
    /// フォーマット定数
    private enum Format {
        static let decimal = "%.1f"
        static let integer = "%.0f"
    }

    /// スナップショット
    let snapshot: UsageSnapshot

    /// リセットまでの残り時間を更新するためのタイマー
    @State private var timerTick = Date()

    var body: some View {
        QuotaCard(
            title: snapshot.primaryTitle,
            gradientColors: gradientColorsForCurrentState
        ) {
            VStack(spacing: 16) {
                // 中央に大きな円形ゲージ
                if let pct = snapshot.primaryPct {
                    VStack(spacing: 12) {
                        // 80ptの大きな円形ゲージ
                        QuotaGauge(percentage: pct, size: 80)

                        // 残量パーセントを大きく表示
                        Text("\(remainingPercentage)%")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(foregroundColorForCurrentState)

                        // ラベル
                        Text("残り")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                // 詳細情報セクション
                VStack(spacing: 8) {
                    // 残量・使用量
                    HStack(spacing: 20) {
                        if let remaining = snapshot.primaryRemaining,
                           let total = snapshot.primaryTotal {
                            StatItem(
                                label: "残り",
                                value: formatNumber(remaining),
                                unit: "/" + formatNumber(total)
                            )
                        }

                        if let used = snapshot.primaryUsed {
                            StatItem(
                                label: "使用済み",
                                value: formatNumber(used)
                            )
                        }
                    }

                    // リセット時刻
                    if let resetEpoch = snapshot.resetEpoch {
                        Divider()
                            .overlay(Color.secondary.opacity(0.2))

                        HStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("リセットまで")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                Text(TimeFormatter.formatTimeRemaining(resetEpoch: resetEpoch))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            Text(TimeFormatter.formatResetTime(resetEpoch: resetEpoch))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            // リセット時間表示を更新するためのトリガー
            timerTick = Date()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(snapshot.primaryTitle)のクォータ情報")
        .accessibilityValue("残り\(remainingPercentage)パーセント")
    }

    /// 残りパーセンテージ
    private var remainingPercentage: Int {
        guard let pct = snapshot.primaryPct else { return 0 }
        return max(100 - pct, 0)
    }

    /// 現在の状態に応じたグラデーション背景色
    private var gradientColorsForCurrentState: [Color]? {
        guard let pct = snapshot.primaryPct else { return nil }
        let remaining = max(100 - pct, 0)

        // 残り率に応じたグラデーション
        let baseColor = QuotaColorCalculator.shared.gradientColor(for: remaining)
        return [
            baseColor.opacity(0.15),
            baseColor.opacity(0.05)
        ]
    }

    /// 現在の状態に応じた前景色
    private var foregroundColorForCurrentState: Color {
        guard let pct = snapshot.primaryPct else { return .primary }
        let remaining = max(100 - pct, 0)
        return QuotaColorCalculator.shared.gradientColor(for: remaining)
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

// MARK: - StatItem Component

/// 統計情報表示アイテム
private struct StatItem: View {
    let label: String
    let value: String
    var unit: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // 健全状態（75%残り）
        PrimaryQuotaView(snapshot: UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: Date().epochSeconds,
            primaryTitle: "GLM-4 (5h)",
            primaryPct: 25,
            primaryUsed: 1250000,
            primaryTotal: 5000000,
            primaryRemaining: 3750000,
            resetEpoch: Date().epochSeconds + 9000,
            secondary: []
        ))

        Divider()

        // 警告状態（40%残り）
        PrimaryQuotaView(snapshot: UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: Date().epochSeconds,
            primaryTitle: "GLM-4 (5h)",
            primaryPct: 60,
            primaryUsed: 3000000,
            primaryTotal: 5000000,
            primaryRemaining: 2000000,
            resetEpoch: Date().epochSeconds + 3600,
            secondary: []
        ))

        Divider()

        // 危険状態（10%残り）
        PrimaryQuotaView(snapshot: UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: Date().epochSeconds,
            primaryTitle: "GLM-4 (5h)",
            primaryPct: 90,
            primaryUsed: 4500000,
            primaryTotal: 5000000,
            primaryRemaining: 500000,
            resetEpoch: Date().epochSeconds + 300,
            secondary: []
        ))
    }
    .frame(width: 280)
    .padding()
}
