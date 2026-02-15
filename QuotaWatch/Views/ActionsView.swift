//
//  ActionsView.swift
//  QuotaWatch
//
//  アクションボタンセクション
//

import SwiftUI

/// ホバーエフェクト付きアイコンボタン
struct IconButton: View {
    let systemImage: String
    let tooltip: String
    let action: () async -> Void
    var isDisabled: Bool = false
    @State private var isHovering = false

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16))
                .foregroundStyle(isDisabled ? .secondary : .primary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovering && !isDisabled ? Color.accentColor.opacity(0.1) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHovering && !isDisabled ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

/// アクションビュー
///
/// Force fetch、Test notification、Open Dashboardのアイコンボタンを表示します。
struct ActionsView: View {
    /// 強制フェッチアクション
    let onForceFetch: () async -> Void

    /// テスト通知アクション
    let onTestNotification: () async -> Void

    /// ダッシュボードを開くアクション
    let onOpenDashboard: () async -> Void

    /// フェッチ中かどうか
    var isFetching: Bool = false

    /// ダッシュボードURL
    var dashboardURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("アクション")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                // Force fetch
                IconButton(
                    systemImage: "arrow.clockwise",
                    tooltip: "強制フェッチ",
                    action: onForceFetch,
                    isDisabled: isFetching
                )

                // Test notification
                IconButton(
                    systemImage: "bell.badge",
                    tooltip: "通知テスト",
                    action: onTestNotification
                )

                // Open dashboard
                if dashboardURL != nil {
                    IconButton(
                        systemImage: "safari",
                        tooltip: "ダッシュボード",
                        action: onOpenDashboard
                    )
                }
            }
        }
    }
}
