# 06. 通知

## 目的
- 5hクォータがリセットされたタイミングを通知
- バックオフ中でも通知が遅延しない設計

## 通知の種類
- ローカル通知（UNUserNotificationCenter）

## チェック周期
- **60秒周期**で通知チェックを実行（`NOTIFICATION_CHECK_INTERVAL`）
- フェッチ間隔に依存せず、独立して動作

## 推奨設定
- `UNNotificationRequest` に `interruptionLevel = .timeSensitive`（可能なら）
- サウンドは `UNNotificationSound.default`（ユーザー設定に従う）
- 追加の音（任意）はアプリ内で再生（MVPは省略可）

## 重複防止
- `lastNotifiedResetEpoch != lastKnownResetEpoch` の場合のみ通知
- 通知後、`lastKnownResetEpoch` を `+RESET_INTERVAL_SECONDS`（18000秒 = 5h）で未来へ進め、"跨いだ状態"を継続的に解消

## スリープ復帰時の挙動
- `NSWorkspace.didWakeNotification` を監視
- 復帰時、即座に通知チェックを実行（60秒待たずに判定）
- 長時間スリープによる通知取りこぼしを防止

## 予約通知（任意・発展）
`lastKnownResetEpoch` が確定したタイミングで、その日時に通知予約を再作成する。
- 長時間スリープ/CPU停止時の取りこぼし低減
- ただし macOS の通知配信はユーザー設定や集中モードに依存

## 通知テストボタン
- UIボタン押下で即時通知
- 未許可なら `requestAuthorization` を呼び、結果をUIに表示

