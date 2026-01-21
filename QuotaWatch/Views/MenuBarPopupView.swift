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
    private func unauthorizedView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("APIキーが無効です", systemImage: "exclamationmark.shield")
                .font(.headline)
                .foregroundColor(.orange)

            Text("APIキーが期限切れか無効です。設定で再確認してください。")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("設定を開く") {
                appDelegate.showingAPIKeySheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    @ViewBuilder
    private func contentView(viewModel: ContentViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoadingInitialData {
                    // スケルトンローダー（初期ロード中）
                    loadingSkeletonView()
                } else if viewModel.authorizationError {
                    // 認証エラー時の専用UI
                    unauthorizedView()
                } else {
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
            }
            .padding()
        }
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
    }

    // MARK: - スケルトンローダー

    /// 初期ロード中のスケルトン表示
    @ViewBuilder
    private func loadingSkeletonView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダースケルトン
            skeletonRow(height: 24, width: 150)

            Divider()

            // プライマリクォータスケルトン
            VStack(alignment: .leading, spacing: 8) {
                skeletonRow(height: 20, width: 120)
                skeletonRow(height: 36, width: 200)
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(.secondary)
            }

            Divider()

            // セカンダリクォータスケルトン
            VStack(alignment: .leading, spacing: 8) {
                skeletonRow(height: 16, width: 180)
                skeletonRow(height: 16, width: 140)
            }

            Divider()

            // ステータススケルトン
            VStack(alignment: .leading, spacing: 8) {
                skeletonRow(height: 14, width: 100)
                skeletonRow(height: 14, width: 160)
            }

            Divider()

            // アクションセクション（簡略版）
            HStack(spacing: 12) {
                skeletonCircle(size: 32)
                skeletonCircle(size: 32)
                skeletonCircle(size: 32)
                Spacer()
            }

            Divider()

            // 設定セクションスケルトン
            VStack(alignment: .leading, spacing: 12) {
                skeletonRow(height: 16, width: 80)
                skeletonRow(height: 20, width: 200)
                skeletonRow(height: 20, width: 200)
            }

            Text("データを読み込み中...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
    }

    /// スケルトン用矩形
    @ViewBuilder
    private func skeletonRow(height: CGFloat, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.secondary.opacity(0.2))
            .frame(width: width, height: height)
            .shimmer()
    }

    /// スケルトン用円形
    @ViewBuilder
    private func skeletonCircle(size: CGFloat) -> some View {
        Circle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - シマーエフェクト

extension View {
    /// シマーエフェクト（読み込み中のアニメーション）
    @ViewBuilder
    func shimmer() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.3),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .onAppear {
                    // シマーアニメーションは簡易版
                }
        )
    }
}
