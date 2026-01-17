# 13. Provider抽象（将来拡張のための最小フック）

## 目的
- MVP（Z.aiのみ）のスコープを増やさずに、将来の多プロバイダ化で“作り直し”を避ける。
- UIは Provider固有のスキーマを参照せず、`UsageSnapshot` のみを参照する。

## MVPのルール
- Providerは `ZaiProvider` **1つだけ**実装
- 設定UIに「Provider選択」は出さない（MVPのスコープ維持）
- 将来の追加時にProviderが差し替え可能な構造にする（DI / factory）

## Providerプロトコル案（概念）
- `id: String`（例: `zai`）
- `displayName: String`（例: `Z.ai`）
- `dashboardURL: URL?`
- `keychainService: String`（例: `zai_api_key`）
- `fetchUsage(apiKey: String) async throws -> UsageSnapshot`
- `classifyBackoff(error: ProviderError) -> BackoffDecision`（429/業務コードなど）

※MVPではエラー分類はProvider内で完結させ、Engineは `BackoffDecision`（通常/バックオフ対象/致命）だけを見ればよい。

## 正規化のコツ（多プロバイダ時の破綻を防ぐ）
- “Primary”は **アプリが最も見せたい枠**（例: 5h tokens / daily limit / monthly spend）を指す
- すべてのProviderが `primaryUsed/Total/Remaining` を持てるとは限らない
  - 取れない場合は `primaryPct` とラベルだけで表示できるようにする
- `resetEpoch` が無いProviderもあるため、通知は
  - `resetEpoch` がある場合のみ（MVPはあり）
  - 無い場合は「閾値超過通知」等へ将来拡張する

## 将来追加時の作業見積り目安
- Provider 1つ追加 = (Networking + 解析 + 正規化 + Keychain service追加) が中心
- UIは基本的に `UsageSnapshot` に従って動くため、改修が最小で済む
