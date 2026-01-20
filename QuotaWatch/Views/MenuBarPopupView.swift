//
//  MenuBarPopupView.swift
//  QuotaWatch
//
//  NSMenu に埋め込むための SwiftUI View
//

import SwiftUI

/// NSMenu に埋め込むためのメニューバーポップアップビュー
struct MenuBarPopupView: View {
    @ObservedObject var viewModel: ContentViewModel
    let appDelegate: AppDelegate

    var body: some View {
        VStack {
            if let error = appDelegate.initializationError {
                errorView(error)
            } else if appDelegate.isInitializing {
                ProgressView("初期化中...")
            } else {
                contentView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
    }

    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        // APIキー未設定時は専用UIを表示
        if let engineError = error as? QuotaEngineError,
           case .apiKeyNotSet = engineError {
            apiKeyNotSetView()
        } else {
            // 既存のエラー表示
            VStack(alignment: .leading, spacing: 12) {
                Label("初期化エラー", systemImage: "exclamationmark.triangle")
                    .font(.headline)
                    .foregroundColor(.red)

                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("再試行") {
                    Task { await appDelegate.setupEngine() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func apiKeyNotSetView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("APIキー未設定", systemImage: "key.badge")
                .font(.headline)
                .foregroundColor(.orange)

            Text("Z.aiのAPIキーを設定してください")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("APIキーを設定") {
                appDelegate.showingAPIKeySheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            // 少し遅延してから自動的にシートを表示
            DispatchQueue.main.async {
                appDelegate.showingAPIKeySheet = true
            }
        }
    }

    @ViewBuilder
    private func contentView(viewModel: ContentViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // ヘッダー
                if let engineState = viewModel.engineState {
                    HeaderView(
                        isBackingOff: engineState.isBackingOff,
                        hasError: viewModel.errorMessage != nil,
                        providerDisplayName: viewModel.providerDisplayName
                    )
                }

                Divider()

                // プライマリクォータ
                if let snapshot = viewModel.snapshot {
                    PrimaryQuotaView(snapshot: snapshot)
                }

                // セカンダリクォータ
                if let snapshot = viewModel.snapshot {
                    SecondaryQuotaView(limits: snapshot.secondary)
                }

                Divider()

                // ステータス
                if let engineState = viewModel.engineState {
                    StatusView(
                        lastFetchEpoch: engineState.lastFetchEpoch,
                        nextFetchEpoch: engineState.nextFetchEpoch,
                        backoffFactor: engineState.backoffFactor,
                        errorMessage: viewModel.errorMessage
                    )
                }

                Divider()

                // アクション
                ActionsView(
                    onForceFetch: {
                        await viewModel.forceFetch()
                    },
                    onTestNotification: {
                        await viewModel.sendTestNotification()
                    },
                    onOpenDashboard: {
                        await viewModel.openDashboard()
                    },
                    isFetching: viewModel.isFetching,
                    dashboardURL: viewModel.dashboardURL
                )

                Divider()

                // 設定
                SettingsView(
                    settings: viewModel.appSettings,
                    onUpdateIntervalChanged: { interval in
                        await viewModel.setUpdateInterval(interval)
                    },
                    onNotificationsChanged: { enabled in
                        await viewModel.setNotificationsEnabled(enabled)
                    },
                    onLoginItemChanged: { enabled in
                        await viewModel.setLoginItemEnabled(enabled)
                    },
                    onExportLog: {
                        Task {
                            _ = await viewModel.exportDebugLog()
                        }
                    }
                )

                // エラーメッセージ
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
    }
}
