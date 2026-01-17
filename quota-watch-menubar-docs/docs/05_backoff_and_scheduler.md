# 05. スケジューリングとバックオフ

## 基本方針
- フェッチ周期（baseInterval）はユーザー設定
  - 最短 60秒
- バックオフ中は `nextFetchAt` までフェッチしない
- フェッチ実行は1本化（actorで直列化）

## 定数定義

```swift
// 時間関連定数（すべて秒数で統一）
let MAX_BACKOFF_SECONDS = 900              // バックオフ最大値（15分）
let JITTER_SECONDS = 15                    // ジッター範囲（0-15秒）
let RESET_INTERVAL_SECONDS = 18000         // クォータリセット間隔（5時間）
let NOTIFICATION_CHECK_INTERVAL = 60       // 通知チェック周期（1分）
let MIN_BASE_INTERVAL = 60                 // ユーザー設定可能な最短フェッチ間隔（1分）
```

## 用語定義

| 用語 | 意味 | 用途 |
|------|------|------|
| `resetEpoch` | 次回リセット時刻のepoch秒 | `UsageSnapshot`、通知判定 |
| `nextResetTime` | Z.ai APIレスポンスのリセット時刻表現 | パース処理でのみ使用 |
| `nextFetchAt` | 次回フェッチ実行時刻のepoch秒 | バックオフ制御 |
| `baseInterval` | ユーザー設定の通常フェッチ間隔（秒） | スケジューリング |

**重要**: `resetEpoch` は正規化後の用語、`nextResetTime` はAPI生レスポンスのパース処理でのみ使用します。

## バックオフ仕様
- 初期 `backoffFactor = 1`
- レート制限時:
  - `newFactor = backoffFactor * 2`
  - `wait = baseInterval * newFactor`
  - `wait > MAX_BACKOFF_SECONDS` の場合 `wait = MAX_BACKOFF_SECONDS` にクリップ
  - `jitter = random(0...JITTER_SECONDS)` を加算
  - `nextFetchAt = now + wait + jitter`
  - `lastError = "rate_limit http=... code=..."`
- 成功時:
  - `backoffFactor = 1`
  - `nextFetchAt = now + baseInterval`
  - `lastError = ""`
- 非レート失敗:
  - `nextFetchAt = now + baseInterval`
  - `lastError = "fetch_error http=... code=..."`

## 通知チェック
- **通知チェックはフェッチと独立**して `NOTIFICATION_CHECK_INTERVAL`（60秒）周期で回す
  - フェッチ間隔を長くしてもリセット通知は低遅延

## 推奨実装
- `QuotaEngine.runLoop()` を `Task` で起動し、
  - `await clock.sleep(until: nextFetchAt)`
  - `await refreshIfDue()`
  - 設定変更で `nextFetchAt` を再計算

## エッジケース: スリープ復帰時の処理
- `NSWorkspace.didWakeNotification` を監視
- 復帰時、`now >= nextFetchAt` なら即時フェッチを実行
- 通知チェック用タイマーも再起動（60秒周期を維持）

