# 01. 要件定義

## 機能要件
### 表示
- メニューバー上に以下を表示
  - 例: `GLM 5h Quota 42% Used • 2h36m`
  - リセット残りが 60秒未満の場合は `<1m` を表示（"0m" を避ける）
- ポップオーバーに詳細
  - 5hクォータ（トークン）の使用率（グラフィカル表示）
  - 月次クォータ（Web Search / Reader / Zread相当）があれば併記
  - Last fetch / Next attempt / Backoff状態 / Last error
  - 生の limits 一覧（デバッグ）

### 更新
- 更新間隔をユーザーが設定可能
  - 最短 1分（60秒）
  - それ以上は任意（推奨UI: 1〜60分の範囲でStep/Slider）
- 更新処理は re-entrant（多重実行）を避ける

### API取得
- Endpoint: `${ORIGIN}/api/monitor/usage/quota/limit`（デフォルト `https://api.z.ai`）
- Header:
  - `Authorization: <API_KEY>`
  - `Accept: application/json`
- タイムアウト: 10秒程度

### エラー/バックオフ
- HTTP 429 または business code が {1302,1303,1305} の場合は指数バックオフ
- バックオフ係数: 1 → 2 → 4 → …
- 待機: `baseInterval * factor` を上限15分でクリップ
- ジッター: 0〜15秒を加算
- その他エラーは次回を baseInterval 後

### キャッシュ
- 取得成功時のレスポンスをローカル保存
- 失敗時もキャッシュから表示（UIを空にしない）

### リセット通知
- APIの `nextResetTime` から「次のリセット時刻（epoch）」を推定
- ローカルで管理する `lastKnownResetEpoch` を用い、時刻を跨いだら通知
- 重複防止: `lastNotifiedResetEpoch` と比較
- リセット後は `lastKnownResetEpoch += 18000`（5h）で次周期へ進める
- 「取得バックオフ中でも通知」は必須
  - 実装方針: **通知チェック専用の1分タイマー**を持つ（フェッチ間隔とは独立）

### 通知テスト
- ポップオーバーに「通知テスト」ボタン
- 通知権限が未許可なら、許可導線を表示

### セキュリティ
- APIキーはKeychainに保存
- ディスクキャッシュや設定に平文保存しない

### 常駐
- ログイン時起動（Login Item）対応
- いわゆるDock非表示アプリ（LSUIElement）も選択可能

## 非機能要件
- macOS 26.2+ 前提（手元のXcodeでDeployment Targetとして指定できない場合は、**指定可能な範囲で最新**を選択）
- 低消費資源（1分〜数分周期の軽量処理）
- ログはOSLogに出力（デバッグしやすさ）


## 将来拡張（MVPではUI非対応）
- 内部実装として Provider 抽象（protocol）を用意し、APIの差分を `UsageSnapshot` へ正規化する
- MVPではプロバイダ選択UIは提供しない（`ZaiProvider` 固定）
- 将来、Provider追加時にUIの大改修が発生しないこと（UIは正規化済みスナップショットのみを参照）
