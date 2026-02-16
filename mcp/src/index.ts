//
// index.ts
// QuotaWatch MCP Server
//
// MCPサーバーのエントリーポイント
// STDIO transportでClaude Code等のMCPクライアントと通信
//

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import {
  getQuotaStatusTool,
  getQuotaSummaryTool,
  handleGetQuotaStatus,
  handleGetQuotaSummary,
} from "./tools.js";

// MARK: - Server Setup

const server = new Server(
  {
    name: "quotawatch-mcp",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// MARK: - Request Handlers

/** 利用可能なツールの一覧を返す */
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [getQuotaStatusTool, getQuotaSummaryTool],
  };
});

/** ツールの実行を処理 */
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case "get_quota_status":
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(handleGetQuotaStatus(), null, 2),
          },
        ],
      };

    case "get_quota_summary":
      const summary = handleGetQuotaSummary();
      return {
        content: [
          {
            type: "text",
            text: summary.content,
          },
        ],
      };

    default:
      throw new Error(`Unknown tool: ${name}`);
  }
});

// MARK: - Server Startup

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  // MCPサーバーはSTDIOで通信するため、ここで終了せずに待機し続ける
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});
