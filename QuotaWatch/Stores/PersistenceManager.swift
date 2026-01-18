//
//  PersistenceManager.swift
//  QuotaWatch
//
//  Application SupportディレクトリへのJSON保存・読み込み
//

import Foundation
import OSLog

// MARK: - PersistenceError

public enum PersistenceError: Error, Sendable, LocalizedError {
    case directoryNotFound
    case fileNotFound(String)
    case decodeFailed(String)
    case writeFailed(String)
    case invalidPath

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound: return "Application Supportディレクトリが見つかりません"
        case .fileNotFound(let file): return "\(file)が見つかりません"
        case .decodeFailed(let file): return "\(file)のデコードに失敗しました"
        case .writeFailed(let file): return "\(file)の書き込みに失敗しました"
        case .invalidPath: return "無効なパスです"
        }
    }
}

// MARK: - PersistenceManager

public actor PersistenceManager {
    private let cacheFileName = "usage_cache.json"
    private let stateFileName = "state.json"
    private let logger = Logger(subsystem: "com.quotawatch.persistence", category: "PersistenceManager")

    private var appSupportURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appending(path: Bundle.main.bundleIdentifier ?? "com.quotawatch")
    }

    private let customDirectoryURL: URL?

    public init() {
        self.customDirectoryURL = nil
        logger.log("PersistenceManager初期化")
    }

    /// テスト用: カスタムディレクトリを指定して初期化
    internal init(customDirectoryURL: URL) {
        self.customDirectoryURL = customDirectoryURL
        logger.log("PersistenceManager初期化（カスタムディレクトリ）")
    }

    // MARK: - ディレクトリ管理

    /// Application Supportディレクトリを確保
    private func ensureAppSupportDirectory() throws -> URL {
        let url = customDirectoryURL ?? appSupportURL
        if !FileManager.default.fileExists(atPath: url.path) {
            logger.debug("Application Supportディレクトリを作成: \(url.path)")
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    // MARK: - usage_cache.json

    /// UsageSnapshotを保存
    public func saveCache(_ snapshot: UsageSnapshot) throws {
        logger.debug("キャッシュ保存開始")
        let directory = try ensureAppSupportDirectory()
        let fileURL = directory.appending(path: cacheFileName)
        try atomicWrite(data: snapshot, to: fileURL)
        logger.log("キャッシュ保存成功")
    }

    /// UsageSnapshotを読み込み
    public func loadCache() throws -> UsageSnapshot {
        let directory = try ensureAppSupportDirectory()
        let fileURL = directory.appending(path: cacheFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw PersistenceError.fileNotFound(cacheFileName)
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        do {
            let snapshot = try decoder.decode(UsageSnapshot.self, from: data)
            logger.debug("キャッシュ読み込み成功")
            return snapshot
        } catch {
            logger.error("キャッシュデコード失敗: \(error)")
            throw PersistenceError.decodeFailed(cacheFileName)
        }
    }

    /// キャッシュを読み込み（破損時はnilを返す）
    public func loadCacheOrDefault() -> UsageSnapshot? {
        do {
            return try loadCache()
        } catch {
            logger.debug("キャッシュ読み込み失敗、デフォルト（nil）を返す")
            return nil
        }
    }

    /// キャッシュを削除
    public func deleteCache() throws {
        let directory = try ensureAppSupportDirectory()
        let fileURL = directory.appending(path: cacheFileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
            logger.log("キャッシュ削除成功")
        }
    }

    // MARK: - state.json

    /// AppStateを保存
    public func saveState(_ state: AppState) throws {
        logger.debug("状態保存開始")
        let directory = try ensureAppSupportDirectory()
        let fileURL = directory.appending(path: stateFileName)
        try atomicWrite(data: state, to: fileURL)
        logger.log("状態保存成功")
    }

    /// AppStateを読み込み
    public func loadState() throws -> AppState {
        let directory = try ensureAppSupportDirectory()
        let fileURL = directory.appending(path: stateFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.debug("状態ファイルが存在しない、デフォルト値を返す")
            return AppState()
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        do {
            let state = try decoder.decode(AppState.self, from: data)
            logger.debug("状態読み込み成功")
            return state
        } catch {
            logger.error("状態デコード失敗: \(error)、デフォルト値を返す")
            return AppState()
        }
    }

    /// 状態を読み込み（破損時はデフォルト値）
    public func loadOrDefaultState() -> AppState {
        do {
            return try loadState()
        } catch {
            logger.debug("状態読み込み失敗、デフォルト値を返す")
            return AppState()
        }
    }

    /// 状態を削除
    public func deleteState() throws {
        let directory = try ensureAppSupportDirectory()
        let fileURL = directory.appending(path: stateFileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
            logger.log("状態削除成功")
        }
    }

    // MARK: - Atomic Write

    /// Atomic write: 一時ファイルに書き込み → renameで置き換え
    private func atomicWrite<T: Encodable>(data: T, to fileURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(data)

        let tempURL = fileURL.appendingPathExtension("tmp")
        try jsonData.write(to: tempURL)

        // 既存ファイルがあれば削除してからrename
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }

        try FileManager.default.moveItem(at: tempURL, to: fileURL)
    }
}
