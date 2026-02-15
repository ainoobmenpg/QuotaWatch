# 04. Networking / API（MVP: Z.ai）

## 方針
- Networkingの実装は Provider に閉じ込める
- MVPでは `ZaiProvider` のみ実装する
- 将来プロバイダ追加時も、UIは `UsageSnapshot` のみ参照する

## Endpoint（Z.ai）
- Default Origin: `https://api.z.ai`
- Endpoint: `/api/monitor/usage/quota/limit`

## Request
- Method: GET
- Headers:
  - `Authorization: Bearer <API_KEY>`
  - `Accept: application/json`

## Response取り扱い
- HTTP 200 + ボディ非空: 成功として `UsageSnapshot` を生成しキャッシュ更新
- それ以外: 失敗（エラー分類してバックオフに反映）

## レート制限判定（バックオフ対象）
- HTTP 429
- JSON内 `code` または `error.code` または `errorCode` が {1302,1303,1305}

## タイムアウト
- `URLSessionConfiguration.timeoutIntervalForRequest = 10`

## 実装注意
- Authorizationヘッダ値の形式は **Bearerトークン**（`Authorization: Bearer ${API_KEY}`）
