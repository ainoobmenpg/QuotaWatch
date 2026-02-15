# 08. UI/UX

## メニューバー（タイトル）
- 基本形（Primary枠が取れている場合）
  - 例: `GLM 5h 42% • 2h36m`
  - 将来拡張に備え、内部的には `primaryTitle` と `resetRemaining` を組み立てる
- 取れない場合
  - 例: `Quota N/A`（または `GLM N/A`）

## ポップオーバー構成（最小）
1. ヘッダ
   - アプリ名: QuotaWatch
   - 状態アイコン（正常/バックオフ/エラー）
   - Providerラベル（MVP: Z.ai）
2. Primary（MVP: 5hトークン枠）
   - Gauge / ProgressView（円 or バー）
   - Used / Total / Remaining（可能な範囲で）
   - Resets in / Reset at
3. Secondary（存在する場合）
   - 月次枠などを `UsageLimit` として一覧表示（Gaugeは任意）
4. 状態
   - Last fetch
   - Next attempt
   - Backoff factor
   - Last error（あれば）
5. 操作（必須）
   - Force fetch
   - Test notification（必須）
   - Open Dashboard
6. 設定（折りたたみでも良い）
   - 更新間隔（最短1分）
   - 通知のON/OFF
   - APIキー設定（未設定時はここへ誘導）
   - Login Item ON/OFF

## “ちょっとグラフィカル”の低コスト案
- SwiftUIの `Gauge` と `ProgressView` の組合せ
- 余力があれば Swift Charts でスパークライン（直近N回のpct）
