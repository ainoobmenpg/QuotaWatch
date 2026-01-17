# 02. アーキテクチャ

## 採用方針
- UI: SwiftUI
- メニューバー: `MenuBarExtra`（macOS 26.2+ 前提）
- 非同期: `async/await`
- 競合回避: `actor` による直列化（多重フェッチ防止）
- 永続化:
  - 状態JSON（Application Support）
  - 設定（UserDefaults）
  - APIキー（Keychain）

## 重要な設計意図（MVPを小さく保つ）
- **MVPは単一プロバイダ（Z.ai）で完結**させる
- ただし将来拡張のため、**Provider抽象は最小限だけ導入**する
  - UIは Provider固有のレスポンス構造を参照しない
  - UIは `UsageSnapshot`（正規化済み）だけを見る

## モジュール

### Provider（protocol）
- API差分を吸収する抽象
- 役割:
  - 認証方式（Keychainのキー名、ヘッダ形式など）
  - エンドポイント
  - レート制限/バックオフ判定のためのエラー分類
  - レスポンスを `UsageSnapshot` へ正規化

### ZaiProvider（MVP実装）
- Default Origin: `https://api.z.ai`
- Endpoint: `/api/monitor/usage/quota/limit`
- `Authorization: <API_KEY>`（SwiftBar互換）

### UsageSnapshot（正規化結果）
- 画面と通知の唯一の入力
- 例:
  - `primaryPct`（5h枠の使用率）
  - `resetEpoch`（次リセット時刻）
  - `primaryUsed/Total/Remaining`（可能なら数値）
  - `secondaryLimits`（月次等、存在する場合）
  - `rawDebug`（任意：デバッグ表示用の生情報）

### QuotaEngine（actor）
- フェッチとバックオフの意思決定を担当
- 設定（更新間隔）を読み込み、次回フェッチ時刻を計算
- 成功時: `UsageSnapshot` とキャッシュを更新
- 失敗時: キャッシュがあればそれを表示用に維持
- UIからの `forceRefresh()` を受け付ける

### ResetNotifier
- 1分周期で `now >= lastKnownResetEpoch` を判定
- 必要に応じて通知を送信し、状態を更新（重複防止、epochの繰り上げ）
- フェッチ間隔とは独立（バックオフ中でも通知するため）

### NotificationManager
- `UNUserNotificationCenter` を薄くラップ
- 権限要求・即時通知・（任意）予約通知

### Persistence
- `AppSupport/usage_cache.json` … 最新の `UsageSnapshot`（API成功時に更新）
- `AppSupport/state.json` … 実行状態（次回フェッチ、バックオフ、通知の重複防止用epoch）

### KeychainStore
- APIキーの read/write/delete

### ViewModel（@MainActor）
- Engine/Notifierの状態を購読し、SwiftUIへ供給

## 依存関係
- ViewModel -> (QuotaEngine, ResetNotifier, KeychainStore, SettingsStore)
- QuotaEngine -> (Provider, Persistence)
- ResetNotifier -> (NotificationManager, Persistence)
