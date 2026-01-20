//
//  SettingsView.swift
//  QuotaWatch
//
//  設定セクション
//

import SwiftUI

/// 設定ビュー
///
/// 更新間隔、通知ON/OFF、Login Itemの設定を表示します。
struct SettingsView: View {
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
        VStack(alignment: .leading, spacing: 8) {
            Text("設定")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                // 更新間隔
                HStack {
                    Text("更新間隔:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $settings.updateInterval) {
                        ForEach(UpdateInterval.allCases) { interval in
                            Text(interval.displayName)
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: settings.updateInterval) { _, newValue in
                        Task { await onUpdateIntervalChanged(newValue) }
                    }
                    .frame(width: 80)

                    Spacer()

                    Text("(\(settings.updateInterval.displayName)ごと)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // 通知ON/OFF
                HStack {
                    Text("通知:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("", isOn: $settings.notificationsEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: settings.notificationsEnabled) { _, newValue in
                            Task { await onNotificationsChanged(newValue) }
                        }

                    if settings.notificationsEnabled {
                        Text("有効")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    } else {
                        Text("無効")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                // Login Item
                HStack {
                    Text("ログイン時起動:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("", isOn: $settings.loginItemEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: settings.loginItemEnabled) { _, newValue in
                            Task { await onLoginItemChanged(newValue) }
                        }

                    if settings.loginItemEnabled {
                        Text("有効")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    } else {
                        Text("無効")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                // ログエクスポート
                HStack {
                    Text("ログ:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

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
