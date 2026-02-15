# Plans.md - 大規模リファクタリング

> **作成日**: 2026-02-15
> **種別**: 大規模リファクタリング（順次実行）

---

## Phase 1: クリーンアップ ✅

- [x] ビルド成果物削除
- [x] Gitignore強化

## Phase 2: ドキュメント整理

- [ ] `quota-watch-menubar-docs/` → `docs-archive/` に移動
- [ ] README.md 更新

## Phase 3: コード整理

- [ ] Utils統合（Color系、Formatter系）
- [ ] 未使用コード削除
- [ ] 不要import削除

## Phase 4: アーキテクチャ改善

- [ ] QuotaEngine分割（730行 → 300行以下）
- [ ] ContentViewModel軽量化（409行 → 300行以下）

## Phase 5: テスト再設計

- [ ] テスト構造再編成
- [ ] テストヘルパー整理

---

## 成功基準

- [ ] ビルド成功
- [ ] 全テストパス
- [ ] QuotaEngine < 300行
- [ ] ContentViewModel < 300行
- [ ] Utils < 10ファイル

---

## 実行方法

```
/work で順次実行
```
