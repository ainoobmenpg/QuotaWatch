# 07. セキュリティ（APIキー）

## 方針
- APIキーは **Keychain** に保存
- ディスクキャッシュ（Application Support / UserDefaults）に平文を保存しない

## Keychain設計
- クラス: Generic Password
- `service`: `zai_api_key`（SwiftBar実装との互換を優先）
- `account`: macOSのユーザー名（任意、Keychainクエリで固定しても良い）

## UI
- Settings（またはポップオーバー内）に
  - APIキー入力欄（SecureField）
  - 保存ボタン
  - "Keychainから削除" ボタン
  - 接続テスト（成功/失敗表示）

## 実装注意
- Keychain読み取り失敗時は UI を赤表示し、設定導線を優先


## 将来拡張（多プロバイダ）
- Providerごとに `service` を分ける（例: `openai_api_key`, `anthropic_api_key`）
- MVPでは `ZaiProvider` のみのため、既存互換の `zai_api_key` を固定使用
