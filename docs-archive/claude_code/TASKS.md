# 実装タスク（順番固定推奨）

**実装完了: 2026-01-19**（Issue #29 Phase 10完了）

## T0: プロジェクト雛形
- [x] `QuotaWatch` というXcodeプロジェクトを作成（SwiftUI App）
- [x] macOS Deployment Target を **26.2+（指定できない場合は最新）** に設定
- [x] `MenuBarExtra` を使った最小表示（"Hello"）を動かす

## T1: 正規化モデル + Z.ai生モデル
- [x] `UsageSnapshot` / `UsageLimit`（UIが参照する正規化モデル）
- [x] `QuotaLimit` / `QuotaResponse`（Z.ai生レスポンスのCodable）
- [x] `nextResetTime` を epoch秒へ正規化する関数（秒/ミリ秒/ISO対応）
- [x] 使用率の計算（percentage優先）

## T2: Keychain
- [x] `KeychainStore`（read/write/delete）
- [x] `service=zai_api_key`（SwiftBar互換）で保存/取得
- [x] APIキー未設定時のUI導線

## T2.5: ログ機能
- [x] `LoggerManager`（actor）- ログ出力を一元管理
- [x] `DebugLogger`（actor）- テキストファイルにログを出力
- [x] DEBUG/RELEASE両ビルドでログ出力をサポート
- [x] ログサイズ制限（100KB）とローテーション
- [x] ログのエクスポート機能（Desktopへコピー）
- [x] カテゴリ別ログ出力（テストヘルパー付き）

## T3: Provider（抽象は最小 / 実装はZ.aiのみ）
- [x] `Provider` protocol を定義
- [x] `ZaiProvider` を実装（Networking + 解析 + `UsageSnapshot`正規化）
- [x] エラー分類（HTTP429 / biz_code 1302/1303/1305）→ `BackoffDecision` に変換
- [x] タイムアウト10秒、リトライはしない（バックオフで制御）

## T4: 永続化
- [x] `AppSupport` への JSON atomic write
- [x] `usage_cache.json`, `state.json` のロード/セーブ

## T5: エンジン（バックオフ + キャッシュ + 多重実行防止）
- [x] `QuotaEngine` actor
- [x] baseInterval（設定：最短1分）を読み込み
- [x] backoffFactor/nextFetchAt/state更新
- [x] `forceRefresh()`
- [x] キャッシュがある限り表示を維持

## T6: 通知
- [x] `NotificationManager`（権限要求、即時通知）
- [x] `ResetNotifier`（1分周期チェック、重複防止、epoch繰り上げ）
- [x] UIに「通知テスト」ボタン
- [x] 可能なら timeSensitive を使用（OS設定に従う）

## T7: UI（グラフィカル）
- [x] メニューバータイトル（例: `GLM 5h 42% • 2h36m`）
- [x] ポップオーバーに Gauge / Progress
- [x] 状態表示（Last fetch / Next attempt / Backoff / Error）
- [x] Actions（Force fetch / Open Dashboard / Test notification）

## T8: 設定
- [x] 更新間隔（最短1分）
- [x] 通知ON/OFF
- [x] Login Item ON/OFF
- [x] （注）Provider選択UIはMVPでは実装しない

## 受け入れ基準（MVP）
- [x] APIキーをKeychainに保存し、成功時にメニューバー表示が更新される
- [x] API失敗でもキャッシュがある限り表示が維持される
- [x] 429 または biz_code 1302/1303/1305 でバックオフが増える
- [x] リセット跨ぎで通知が1回だけ発火し、以後重複しない
- [x] 通知テストボタンで確実に通知が出る
- [x] 更新間隔を変更すると次回スケジュールが反映される
- [x] ログイン時起動トグルが動作する

### エッジケース（受け入れ基準に追加）
- [x] アプリ強制終了後、起動時に `state.json` から状態が復旧される
  - 自動テスト: `EdgeCaseIntegrationTests.testCrashRecoveryRestoresSnapshot()`
  - 手動テスト: `11_testing.md` 「強制終了後の復旧の確認」参照
- [x] macOSスリープ復帰時、`nextFetchAt` が経過していれば即時フェッチが実行される
  - 自動テスト: `SleepWakeIntegrationTests.testWakeFromSleepTriggersImmediateFetch()`
  - 手動テスト: `11_testing.md` 「スリープ復帰の確認」参照
- [x] 長時間スリープ後、通知チェックが即座に実行され取りこぼしがない
  - 自動テスト: `SleepWakeIntegrationTests.testResetNotifierWakeupIntegration()`
  - 手動テスト: `11_testing.md` 「スリープ復帰の確認」参照
- [x] ネットワーク切断時、`lastError` に適切なエラーメッセージが表示される
  - 自動テスト: `EdgeCaseIntegrationTests.testNetworkErrorWithCachedData()`
  - 手動テスト: `11_testing.md` 「エラー表示の確認」参照
- [x] `usage_cache.json` 破損時、"no cache" 表示がされる
  - 自動テスト: `EdgeCaseIntegrationTests.testCorruptedCacheFileHandledGracefully()`
  - 手動テスト: `11_testing.md` 「キャッシュ破損の確認」参照

