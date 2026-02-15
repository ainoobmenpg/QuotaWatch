# Claude Code へ渡すプロンプト例（コピペ用）

## 1) 雛形（MenuBarExtra）
「SwiftUIのMenuBarExtraで、メニューバー常駐アプリ `QuotaWatch` の最小構成を作って。ポップオーバーにテキストを表示するだけで良い。macOS 26.2+ 前提（Deployment Targetに26.2が無い場合は指定可能な範囲で最新）。」

## 2) 正規化モデル + Z.ai生モデル
「`UsageSnapshot` / `UsageLimit`（正規化モデル）と、`spec/api_sample.json` に合わせたZ.aiの `Codable` モデルを作成。`nextResetTime` を epoch秒へ正規化する関数（秒/ミリ秒/ISO対応）も実装。」

## 3) Keychain
「Keychainに `service=zai_api_key` でAPIキーを保存/取得/削除できる `KeychainStore` をSwiftで実装。SecureFieldで入力して保存できるUIも追加。」

## 4) Provider（抽象は最小・実装はZ.aiのみ）
「`Provider` protocol を定義し、`ZaiProvider` でNetworking + 解析 + `UsageSnapshot` への正規化を実装。レート制限判定はHTTP429またはbiz_code 1302/1303/1305。結果は `BackoffDecision`（通常/バックオフ/致命）として返す。」

## 5) エンジン
「バックオフ仕様（docs/05）に従い `QuotaEngine` actor を実装。更新間隔は設定値（最短1分）。成功時は `usage_cache.json` を更新、失敗時はキャッシュ値を維持して表示。多重フェッチを禁止。」

## 6) 通知
「`ResetNotifier` を実装。1分周期で `now >= lastKnownResetEpoch` を判定し、重複防止して通知。通知テストボタンも用意。可能なら timeSensitive を使用。」
