# QuotaWatch MCP Server

Z.aiのクォータデータをMCP（Model Context Protocol）経由で公開するサーバーです。

**このバージョンはZ.ai APIを直接叩きます**（QuotaWatchアプリ不要）。

## 機能

- `get_quota_status`: 現在のクォータ状態を構造化JSONで取得
- `get_quota_summary`: 人間が読みやすい形式でサマリーを取得

## セットアップ

### 1. 依存関係のインストール

```bash
cd mcp
npm install
```

### 2. ビルド

```bash
npm run build
```

### 3. 環境変数の設定

Z.aiのAPIキーを環境変数 `ZAI_API_KEY` に設定します。

```bash
# 一時的（現在のセッションのみ）
export ZAI_API_KEY="your-api-key"

# 永続的（.bashrc や .zshrc に追加）
echo 'export ZAI_API_KEY="your-api-key"' >> ~/.bashrc
```

### 4. MCPクライアントへの登録

#### Claude Code

`.claude/settings.json` に以下を追加：

```json
{
  "mcpServers": {
    "quotawatch": {
      "command": "node",
      "args": ["/path/to/QuotaWatch/mcp/dist/index.js"],
      "env": {
        "ZAI_API_KEY": "your-api-key"
      }
    }
  }
}
```

#### OpenCode（Windows/WSL2）

`~/.config/opencode/mcp.json` または該当設定ファイルに追加：

```json
{
  "mcpServers": {
    "quotawatch": {
      "command": "node",
      "args": ["/mnt/c/path/to/QuotaWatch/mcp/dist/index.js"],
      "env": {
        "ZAI_API_KEY": "your-api-key"
      }
    }
  }
}
```

## 使用可能なツール

### get_quota_status

構造化データでクォータ状態を返します。

**出力例:**
```json
{
  "success": true,
  "data": {
    "providerId": "zai",
    "fetchedAt": "2026-02-16T21:00:00Z",
    "primary": {
      "title": "GLM 5h",
      "percentage": 42,
      "used": 126000,
      "total": 300000,
      "remaining": 174000
    },
    "resetAt": "2026-02-17T02:00:00Z",
    "resetAtJST": "2026-02-17 11:00:00",
    "secondary": []
  }
}
```

### get_quota_summary

人間が読みやすい形式でサマリーを返します。

**出力例:**
```
📊 GLM 5h: 42% used (126.0k/300.0k tokens)
⏰ Resets at 2026-02-17 11:00:00
📦 Secondary: Web Search 12%
📡 Last fetched at 2026-02-17 06:00:00
```

## データソース

このMCPサーバーは **Z.ai API** を直接叩きます：

- **Endpoint**: `https://api.z.ai/api/monitor/usage/quota/limit`
- **Method**: GET
- **Auth**: Bearer Token（`ZAI_API_KEY` 環境変数）

QuotaWatchアプリは不要です。

## 開発

```bash
# インストール
npm install

# ビルド
npm run build

# ウォッチモードでビルド
npm run watch

# 手動実行（テスト用）
ZAI_API_KEY=your-key npm start
```

## エラーハンドリング

| エラータイプ | 説明 |
|-------------|------|
| `config` | `ZAI_API_KEY` が設定されていない |
| `auth` | 認証失敗（HTTP 401/403） |
| `rate_limit` | レート制限（HTTP 429 または APIコード 1302/1303/1305） |
| `server` | サーバーエラー（HTTP 5xx） |
| `network` | ネットワークエラー、タイムアウト |
| `parse` | JSONパースエラー |

## ライセンス

MIT
