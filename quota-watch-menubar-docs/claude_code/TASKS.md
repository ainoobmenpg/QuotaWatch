# 実装タスク（順番固定推奨）

## T0: プロジェクト雛形
- [ ] `QuotaWatch` というXcodeプロジェクトを作成（SwiftUI App）
- [ ] macOS Deployment Target を **26.2+（指定できない場合は最新）** に設定
- [ ] `MenuBarExtra` を使った最小表示（"Hello"）を動かす

## T1: 正規化モデル + Z.ai生モデル
- [ ] `UsageSnapshot` / `UsageLimit`（UIが参照する正規化モデル）
- [ ] `QuotaLimit` / `QuotaResponse`（Z.ai生レスポンスのCodable）
- [ ] `nextResetTime` を epoch秒へ正規化する関数（秒/ミリ秒/ISO対応）
- [ ] 使用率の計算（percentage優先）

## T2: Keychain
- [ ] `KeychainStore`（read/write/delete）
- [ ] `service=zai_api_key`（SwiftBar互換）で保存/取得
- [ ] APIキー未設定時のUI導線

## T3: Provider（抽象は最小 / 実装はZ.aiのみ）
- [ ] `Provider` protocol を定義
- [ ] `ZaiProvider` を実装（Networking + 解析 + `UsageSnapshot`正規化）
- [ ] エラー分類（HTTP429 / biz_code 1302/1303/1305）→ `BackoffDecision` に変換
- [ ] タイムアウト10秒、リトライはしない（バックオフで制御）

## T4: 永続化
- [ ] `AppSupport` への JSON atomic write
- [ ] `usage_cache.json`, `state.json` のロード/セーブ

## T5: エンジン（バックオフ + キャッシュ + 多重実行防止）
- [ ] `QuotaEngine` actor
- [ ] baseInterval（設定：最短1分）を読み込み
- [ ] backoffFactor/nextFetchAt/state更新
- [ ] `forceRefresh()`
- [ ] キャッシュがある限り表示を維持

## T6: 通知
- [ ] `NotificationManager`（権限要求、即時通知）
- [ ] `ResetNotifier`（1分周期チェック、重複防止、epoch繰り上げ）
- [ ] UIに「通知テスト」ボタン
- [ ] 可能なら timeSensitive を使用（OS設定に従う）

## T7: UI（グラフィカル）
- [ ] メニューバータイトル（例: `GLM 5h 42% • 2h36m`）
- [ ] ポップオーバーに Gauge / Progress
- [ ] 状態表示（Last fetch / Next attempt / Backoff / Error）
- [ ] Actions（Force fetch / Open Dashboard / Test notification）

## T8: 設定
- [ ] 更新間隔（最短1分）
- [ ] 通知ON/OFF
- [ ] Login Item ON/OFF
- [ ] （注）Provider選択UIはMVPでは実装しない

## 受け入れ基準（MVP）
- [ ] APIキーをKeychainに保存し、成功時にメニューバー表示が更新される
- [ ] API失敗でもキャッシュがある限り表示が維持される
- [ ] 429 または biz_code 1302/1303/1305 でバックオフが増える
- [ ] リセット跨ぎで通知が1回だけ発火し、以後重複しない
- [ ] 通知テストボタンで確実に通知が出る
- [ ] 更新間隔を変更すると次回スケジュールが反映される
- [ ] ログイン時起動トグルが動作する

### エッジケース（受け入れ基準に追加）
- [ ] アプリ強制終了後、起動時に `state.json` から状態が復旧される
- [ ] macOSスリープ復帰時、`nextFetchAt` が経過していれば即時フェッチが実行される
- [ ] 長時間スリープ後、通知チェックが即座に実行され取りこぼしがない
- [ ] ネットワーク切断時、`lastError` に適切なエラーメッセージが表示される
- [ ] `usage_cache.json` 破損時、"no cache" 表示がされる
