//
//  APIKeySettingsSheet.swift
//  QuotaWatch
//
//  APIキー設定シート
//

import SwiftUI
import OSLog

/// APIキー設定用のシートView
struct APIKeySettingsSheet: View {
    let onSave: (String) async -> Void
    let initialError: String?
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var isSaving: Bool = false
    @State private var saveError: String?

    private let logger = Logger(subsystem: "com.quotawatch.app", category: "APIKeySettingsSheet")

    init(onSave: @escaping (String) async -> Void, initialError: String? = nil) {
        self.onSave = onSave
        self.initialError = initialError
        _saveError = State(initialValue: initialError)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // タイトル
            Text("Z.ai APIキー設定")
                .font(.title2)
                .fontWeight(.semibold)

            // 説明文
            Text("Z.aiのダッシュボードからAPIキーを取得してください")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            // APIキー入力フィールド
            SecureField("APIキー", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    Task { await saveKey() }
                }

            // エラーメッセージ表示
            if let error = saveError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Spacer()

            // ボタン群
            HStack {
                Button("キャンセル") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button("保存") {
                        Task { await saveKey() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty)
                }
            }

            // ダッシュボードリンク
            Link("Z.aiダッシュボードを開く", destination: URL(string: "https://api.z.ai")!)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - プライベートメソッド

    /// APIキーを保存
    private func saveKey() async {
        isSaving = true
        saveError = nil

        let trimmed = apiKey.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            saveError = "APIキーを入力してください"
            isSaving = false
            return
        }

        logger.debug("APIキー保存開始（長さ: \(trimmed.count)）")
        await onSave(trimmed)
        dismiss()
    }
}

#Preview {
    APIKeySettingsSheet(onSave: { apiKey in
        try? await Task.sleep(nanoseconds: 500_000_000)
    }, initialError: nil)
}

#Preview("エラー状態") {
    APIKeySettingsSheet(onSave: { _ in }, initialError: "保存に失敗しました")
}
