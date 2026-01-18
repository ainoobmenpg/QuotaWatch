//
//  SecondaryQuotaView.swift
//  QuotaWatch
//
//  セカンダリクォータ表示セクション
//

import SwiftUI

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
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(limit.label)
                    .font(.caption)
                    .foregroundStyle(.primary)

                if let pct = limit.pct {
                    Text("\(pct)%")
                        .font(.caption)
                        .foregroundStyle(Color.usageColor(for: pct))
                }

                Spacer()

                if let resetEpoch = limit.resetEpoch {
                    Text(TimeFormatter.formatTimeRemaining(resetEpoch: resetEpoch))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // プログレスバー
            if let pct = limit.pct {
                ProgressView(value: Double(pct), total: 100)
                    .progressViewStyle(.linear)
                    .tint(Color.usageColor(for: pct))
                    .scaleEffect(y: 0.5)
            }
        }
    }
}
