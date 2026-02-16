# クイックリファレンス

QuotaWatch 開発でよく参照するアーキテクチャとデータモデルの要約です。

## 主要コンポーネント

```
Provider protocol（抽象レイヤー）
├── ZaiProvider（MVP実装）
│
QuotaEngine（actor）
├── フェッチとバックオフの意思決定
├── 多重実行防止（actorによる直列化）
└── UsageSnapshotの生成
│
ResetNotifier
├── 1分周期でリセットチェック
└── 重複防止して通知
│
ViewModel（@MainActor）
└── SwiftUIへ状態を供給
```

## データフロー

1. **Provider** → APIフェッチ → `UsageSnapshot`（正規化済みモデル）へ変換
2. **QuotaEngine** → バックオフ制御 + `usage_cache.json` へ永続化
3. **ResetNotifier** → 1分周期でリセット検知 → `NotificationManager` 経由で通知
4. **UI** → `UsageSnapshot` のみを参照（Provider固有構造は参照しない）

## 重要な設計原則

- **MVPは単一プロバイダ（Z.ai）で完結** - 将来拡張のための最小限の抽象のみ導入
- **UIは正規化済み `UsageSnapshot` のみ参照** - Provider生レスポンス構造を直接見ない
- **actor + @MainActorで状態管理を単純化** - 競合を回避
- **APIキーはKeychainのみ** - ディスク保存は禁止
- **ログはLoggerManagerで一元管理** - DEBUG/RELEASE両ビルドでログ出力をサポート

## UsageSnapshot（正規化モデル）

UI/通知が参照する唯一のモデル:

```swift
- providerId: String        // 例: "zai"
- fetchedAtEpoch: Int        // 取得時刻
- primaryTitle: String       // 例: "GLM 5h"
- primaryPct: Int?           // 0-100
- primaryUsed/Total/Remaining: Double?
- resetEpoch: Int?           // 次回リセットのepoch秒
- secondary: [UsageLimit]    // 月次枠等
- rawDebugJson: String?      // デバッグ用
```

## Z.ai API仕様

- **Endpoint**: `https://api.z.ai/api/monitor/usage/quota/limit`
- **Method**: GET
- **Headers**: `Authorization: <API_KEY>`（ベアトークン形式）
- **Response**: `docs-archive/spec/api_sample.json` 参照

## レート制限判定（バックオフ対象）

- HTTP 429
- JSON内 `code` / `error.code` / `errorCode` が {1302, 1303, 1305}

## 永続化

**保存先**: `Application Support/<BundleID>/`

- `usage_cache.json` - 最新成功レスポンス（`UsageSnapshot`）
- `state.json` - 実行状態（次回フェッチ時刻、バックオフ係数、通知重複防止用epoch）

**状態スキーマ**: `docs-archive/spec/state_schema.json` 参照

## ログ機能

**LoggerManager（actor）** - ログ出力を一元管理:
- `DebugLogger` のシングルトンインスタンスを管理
- DEBUG/RELEASE両ビルドでログ出力をサポート
- ログサイズ制限（100KB）とローテーション
- ログのエクスポート機能（Desktopへコピー）
- ログ出力先: `Application Support/<BundleID>/debug.log`

**DebugLogger（actor）** - テキストファイルにログを出力:
- ログフォーマット: `[ISO8601 timestamp] [CATEGORY] message`
- カテゴリ別ログ出力（例: "FETCH", "ENGINE", "NOTIFICATION"）
- ログローテーション（サイズ超過時に古いログから削除）

## セキュリティ

- **APIキーはKeychainのみ保存**（`service=zai_api_key`）
- ディスク（UserDefaults/Application Support）に平文保存禁止

## バックオフ仕様

- 初期 `backoffFactor = 1`
- レート制限時: `factor * 2`、最大15分 + ジッター(0-15秒)
- 成功時: `factor = 1` にリセット
- 非レート失敗: 次回は通常間隔でリトライ

## 通知仕様

- 1分周期で `now >= lastKnownResetEpoch` を判定（フェッチ間隔に依存しない）
- `lastNotifiedResetEpoch != lastKnownResetEpoch` の場合のみ通知
- 通知後、epochを+5時間進めて重複防止
- `UNNotificationRequest.interruptionLevel = .timeSensitive` 推奨

## コーディング規約

- **Swift 6** で実装
- **OSLog** でカテゴリ別ロギング（システムログ）
- **LoggerManager** でデバッグログ出力（DEBUG/RELEASE両対応）
- **async/await** を優先
- **actor** による競合回避
