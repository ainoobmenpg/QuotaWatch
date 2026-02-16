//
// reader.ts
// QuotaWatch MCP Server
//
// QuotaWatchアプリが書き出すJSONファイルを読み取るユーティリティ
//

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

// MARK: - Type Definitions

/** UsageSnapshot - QuotaWatchアプリが保存する正規化済みクォータデータ */
export interface UsageSnapshot {
  providerId: string;
  fetchedAtEpoch: number;
  primaryTitle: string;
  primaryPct: number | null;
  primaryUsed: number | null;
  primaryTotal: number | null;
  primaryRemaining: number | null;
  resetEpoch: number | null;
  secondary: UsageLimit[];
  rawDebugJson: string | null;
}

/** UsageLimit - セカンダリクォータ */
export interface UsageLimit {
  label: string;
  pct: number | null;
  used: number | null;
  total: number | null;
  remaining: number | null;
  resetEpoch: number | null;
  usageDetails: UsageDetail[];
}

/** UsageDetail - MCPサービスごとの使用量内訳 */
export interface UsageDetail {
  modelCode: string;
  usage: number;
}

/** AppState - QuotaWatchアプリの実行状態 */
export interface AppState {
  nextFetchEpoch: number;
  backoffFactor: number;
  lastFetchEpoch: number;
  lastError: string;
  lastKnownResetEpoch: number;
  lastNotifiedResetEpoch: number;
}

/** 読み取り結果（ファイルが存在しない場合はnull） */
export type ReadResult<T> = T | null;

// MARK: - Constants

const QUOTAWATCH_BUNDLE_ID = "com.quotawatch";
const FILENAME_USAGE_CACHE = "usage_cache.json";
const FILENAME_STATE = "state.json";

// MARK: - Path Utilities

/** QuotaWatchのApplication Supportディレクトリパスを取得 */
export function getQuotaWatchDataDir(): string {
  const homeDir = os.homedir();
  return path.join(homeDir, "Library", "Application Support", QUOTAWATCH_BUNDLE_ID);
}

/** usage_cache.json のファイルパスを取得 */
export function getUsageCachePath(): string {
  return path.join(getQuotaWatchDataDir(), FILENAME_USAGE_CACHE);
}

/** state.json のファイルパスを取得 */
export function getStateFilePath(): string {
  return path.join(getQuotaWatchDataDir(), FILENAME_STATE);
}

// MARK: - Read Functions

/** usage_cache.json を読み取る
 * @returns UsageSnapshot または null（ファイル不存在時）
 */
export function readUsageCache(): ReadResult<UsageSnapshot> {
  const filePath = getUsageCachePath();
  try {
    const content = fs.readFileSync(filePath, "utf-8");
    const data = JSON.parse(content) as UsageSnapshot;
    return data;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      // ファイルが存在しない場合はnullを返す
      return null;
    }
    // その他のエラーは再スロー
    throw error;
  }
}

/** state.json を読み取る
 * @returns AppState または null（ファイル不存在時）
 */
export function readState(): ReadResult<AppState> {
  const filePath = getStateFilePath();
  try {
    const content = fs.readFileSync(filePath, "utf-8");
    const data = JSON.parse(content) as AppState;
    return data;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      // ファイルが存在しない場合はnullを返す
      return null;
    }
    // その他のエラーは再スロー
    throw error;
  }
}

/** 両方のファイルを読み取る
 * @returns { usageCache, state } 読み取り結果（存在しない場合はnull）
 */
export function readAll(): {
  usageCache: ReadResult<UsageSnapshot>;
  state: ReadResult<AppState>;
} {
  return {
    usageCache: readUsageCache(),
    state: readState(),
  };
}

// MARK: - Validation Utilities

/** epoch秒をISO8601文字列に変換 */
export function epochToISOString(epochSeconds: number | null): string | null {
  if (epochSeconds === null) {
    return null;
  }
  return new Date(epochSeconds * 1000).toISOString();
}

/** epoch秒をJST日時に変換（表示用） */
export function epochToJSTString(epochSeconds: number | null): string | null {
  if (epochSeconds === null) {
    return null;
  }
  const date = new Date(epochSeconds * 1000);
  return date.toLocaleString("ja-JP", { timeZone: "Asia/Tokyo" });
}
