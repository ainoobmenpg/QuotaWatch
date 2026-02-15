# 03. データモデル

## 正規化モデル（UI/通知が参照する唯一のモデル）

### UsageSnapshot
Providerごとの生レスポンスを、UIが扱いやすい形に正規化する。

推奨フィールド（MVPで使う範囲のみ）:
- `providerId: String`（例: `zai`）
- `fetchedAtEpoch: Int`（取得時刻）
- `primaryTitle: String`（例: `GLM 5h` / 将来は `ProviderShortLabel 5h`）
- `primaryPct: Int?`（0-100、無ければnil）
- `primaryUsed: Double?`
- `primaryTotal: Double?`
- `primaryRemaining: Double?`
- `resetEpoch: Int?`（次回リセットのepoch秒）
- `secondary: [UsageLimit]`（月次等。MVPでは表示だけ）
- `rawDebugJson: String?`（任意。デバッグ表示用）

### UsageLimit
- `label: String`（例: `Search (Monthly)`）
- `pct: Int?`
- `used: Double?`
- `total: Double?`
- `remaining: Double?`
- `resetEpoch: Int?`

## Z.ai（MVP）の生レスポンス（推定）
SwiftBarスクリプトは以下を参照している:
- `data.limits` または `limits`
- `limits[*].type`, `percentage`, `usage`, `number`, `remaining`, `nextResetTime`

### typeの分類（大文字小文字無視）
- 5hトークン枠: `TOKEN` / `TOKENS`
- 月次枠: `WEB` / `SEARCH` / `READER` / `ZREAD`

### nextResetTimeの正規化（epoch秒）
- 数値の場合
  - `> 10_000_000_000` なら ms とみなして `ms/1000`
  - それ以外は秒
- ISO文字列の場合
  - `Date` へparse（Z/offset対応）

### 使用率（整数%）
- `percentage` があれば `floor` して採用
- なければ `floor(100 * usage / number)`

## 永続状態（state.json）
- `nextFetchEpoch: Int`
- `backoffFactor: Int`
- `lastFetchEpoch: Int`
- `lastError: String`
- `lastKnownResetEpoch: Int`
- `lastNotifiedResetEpoch: Int`

### ロールバック防止
APIが一時的に古い `resetEpoch` を返す可能性があるため、候補値が大きく巻き戻る場合は無視する。
- `candidate >= lastKnownResetEpoch - 120` の場合のみ更新（2分の許容）
- それ以外は `lastKnownResetEpoch` を維持
