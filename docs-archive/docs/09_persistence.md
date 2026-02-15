# 09. 永続化

## 保存先
- `Application Support/<BundleID>/`
  - `usage_cache.json` … 最新成功レスポンス（`UsageSnapshot`）
  - `state.json` … 実行状態

## 更新タイミング
- 成功時: usage_cache.json を更新
- state.json: フェッチ試行後、通知後、設定変更時など

## 破損耐性
- JSON decode失敗時は
  - stateはデフォルト値で復旧
  - cacheは "no cache" 表示
- 書き込みは atomic（tmp -> rename）

## 状態復旧（エッジケース対応）
- アプリ強制終了後:
  - `state.json` から `nextFetchAt` / `backoffFactor` を復元
  - 復旧時刻と `nextFetchAt` を比較し、過去なら即時フェッチ
- macOSスリープ復帰時:
  - `NSWorkspace.willSleepNotifications` / `didWakeNotifications` を監視
  - 復帰時、`nextFetchAt` が経過していれば即時フェッチ
  - 通知チェック用タイマーも再起動

