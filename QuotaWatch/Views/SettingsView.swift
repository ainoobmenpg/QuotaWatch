//
//  SettingsView.swift
//  QuotaWatch
//
//  設定セクション
//

import SwiftUI

// MARK: - Custom Switch Toggle Style
/// カスタムスイッチスタイル
///
/// macOS 26.2 (Tahoe) で `.toggleStyle(.switch)` と `.tint()` の
/// 組み合わせが正しく動作しない既知のバグへのワークアラウンドとして実装。
/// Apple HIG標準サイズ（51×31pt）に準拠。
struct CustomSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            ZStack {
                // スイッチの背景（ON時はアクセントカラー）
                RoundedRectangle(cornerRadius: 14)
                    .fill(configuration.isOn ? Color.accentColor : Color.gray.opacity(0.25))
                    .frame(width: 51, height: 31)

                // つまみ（白丸）
                Circle()
                    .fill(Color.white)
                    .frame(width: 27, height: 27)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isOn)
            }
            .frame(width: 51, height: 31)  // 最小ヒット領域確保（44×44pt要件を満たすため余白を持たせる）
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 設定ビュー
///
/// 更新間隔、通知ON/OFF、Login Itemの設定を表示します。
struct SettingsView: View {
    /// カラースキーム（ライト/ダークモード検出用）
    @Environment(\.colorScheme) private var colorScheme

    /// アプリ設定
    @Bindable var settings: AppSettings

    /// 更新間隔変更アクション
    let onUpdateIntervalChanged: (UpdateInterval) async -> Void

    /// 通知設定変更アクション
    let onNotificationsChanged: (Bool) async -> Void

    /// Login Item設定変更アクション
    let onLoginItemChanged: (Bool) async -> Void

    /// ログエクスポートアクション
    let onExportLog: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("設定")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 16) {
                // 更新間隔
                HStack(spacing: 12) {
                    Text("更新間隔:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    Button(action: {
                        // 次の間隔に切り替え（サイクリック）
                        let allCases = UpdateInterval.allCases
                        if let currentIndex = allCases.firstIndex(of: settings.updateInterval) {
                            let nextIndex = (currentIndex + 1) % allCases.count
                            let nextInterval = allCases[nextIndex]
                            settings.updateInterval = nextInterval
                            Task { await onUpdateIntervalChanged(nextInterval) }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(settings.updateInterval.displayName)
                            Image(systemName: "chevron.left")
                                .font(.caption2)
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .frame(width: 80)

                    Spacer()

                    Text("(\(settings.updateInterval.displayName)ごと)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // 通知ON/OFF
                HStack(spacing: 12) {
                    Text("通知:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    Toggle("", isOn: $settings.notificationsEnabled)
                        .toggleStyle(CustomSwitchToggleStyle())
                        .onChange(of: settings.notificationsEnabled) { _, newValue in
                            Task { await onNotificationsChanged(newValue) }
                        }

                    Spacer()
                }

                // Login Item
                HStack(spacing: 12) {
                    Text("ログイン時起動:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    Toggle("", isOn: $settings.loginItemEnabled)
                        .toggleStyle(CustomSwitchToggleStyle())
                        .onChange(of: settings.loginItemEnabled) { _, newValue in
                            Task { await onLoginItemChanged(newValue) }
                        }

                    Spacer()
                }

                // ログエクスポート
                HStack(spacing: 12) {
                    Text("ログ:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    Button("ログをエクスポート") {
                        Task {
                            await onExportLog()
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)

                    Spacer()
                }
            }
        }
    }
}
