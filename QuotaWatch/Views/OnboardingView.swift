//
//  OnboardingView.swift
//  QuotaWatch
//
//  初回起動時のオンボーディングView
//

import SwiftUI
import OSLog

/// 初回起動時のオンボーディングView
///
/// APIキー設定とログイン時起動設定を行い、初回フェッチを実行します。
public struct OnboardingView: View {
    let onComplete: () -> Void
    let onDismiss: () -> Void

    @State private var apiKey: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var fetchSuccessful = false
    @State private var isFetching = false

    // AppSettingsからログイン時起動の設定を管理
    @State private var loginItemEnabled: Bool = false

    // プロバイダー選択
    @State private var selectedProviderId: ProviderId = .zai

    private let logger = Logger(subsystem: "com.quotawatch.app", category: "OnboardingView")

    public init(
        onComplete: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }

    private var currentProvider: ProviderId {
        selectedProviderId
    }

    public var body: some View {
        VStack(spacing: 24) {
            Text("QuotaWatch セットアップ")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("\(currentProvider.displayName)のクォータ使用状況を監視するアプリケーション")
                .foregroundColor(.secondary)

            Divider()

            // プロバイダー選択
            VStack(alignment: .leading, spacing: 8) {
                Text("プロバイダー")
                    .font(.headline)

                Picker("プロバイダー", selection: $selectedProviderId) {
                    ForEach(ProviderId.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("APIキー")
                    .font(.headline)

                Text("\(currentProvider.displayName)のダッシュボードからAPIキーを取得してください")
                    .font(.caption)
                    .foregroundColor(.secondary)

                SecureField("APIキーを入力", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await saveAndFetch() }
                    }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                if let dashboardURL = currentProvider.dashboardURL {
                    Link("\(currentProvider.displayName)ダッシュボードを開く", destination: dashboardURL)
                        .font(.caption)
                }
            }

            Toggle("ログイン時に起動", isOn: $loginItemEnabled)
                .toggleStyle(.switch)
                .onChange(of: loginItemEnabled) { _, newValue in
                    Task {
                        await updateLoginItem(newValue)
                    }
                }

            Spacer()

            HStack(spacing: 12) {
                Button("後で設定") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .disabled(isSaving || isFetching)

                Spacer()

                if isFetching {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button("開始する") {
                        Task { await saveAndFetch() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty || isSaving)
                }
            }

            if fetchSuccessful {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("設定完了！")
                        .font(.headline)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // AppSettingsから初期値を読み込み
            let appSettings = AppSettings()
            loginItemEnabled = appSettings.loginItemEnabled
            selectedProviderId = appSettings.providerId
            logger.log("OnboardingViewが表示されました")
        }
    }

    // MARK: - Actions

    /// APIキーを保存して初回フェッチを実行
    private func saveAndFetch() async {
        let trimmed = apiKey.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorMessage = "APIキーを入力してください"
            return
        }

        isSaving = true
        errorMessage = nil
        isFetching = true

        do {
            // プロバイダー設定を保存
            let settings = AppSettings()
            settings.providerId = selectedProviderId

            // APIキーを保存
            let keychain = KeychainStore(providerId: selectedProviderId)
            try await keychain.write(apiKey: trimmed)
            logger.log("APIキー保存成功: provider=\(selectedProviderId.displayName)")

            // 初回フェッチを実行（成功確認）
            let provider = ProviderFactory.create(providerId: selectedProviderId)
            let persistence = PersistenceManager(customDirectoryURL: FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first!
                .appending(path: "com.quotawatch"))

            let engine = try await QuotaEngine(
                provider: provider,
                persistence: persistence,
                keychain: keychain
            )

            // 初回フェッチ実行
            _ = try await engine.forceFetch()
            logger.log("初回フェッチ成功")

            fetchSuccessful = true

            // 成功後に遅延して完了処理を実行
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            onComplete()

        } catch {
            logger.error("設定エラー: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isFetching = false
        }

        isSaving = false
    }

    /// ログイン時起動設定を更新
    private func updateLoginItem(_ enabled: Bool) async {
        let appSettings = AppSettings()
        appSettings.loginItemEnabled = enabled
        logger.log("ログイン時起動を\(enabled ? "有効" : "無効")に設定")
    }
}

#Preview {
    OnboardingView(
        onComplete: {},
        onDismiss: {}
    )
}
