# Plans.md - 大規模リファクタリング

> **作成日**: 2026-02-15
> **完了日**: 2026-02-15
> **種別**: 大規模リファクタリング（順次実行）

---

## ✅ 完了サマリー

### Phase 1: クリーンアップ ✅

- [x] ビルド成果物削除
- [x] Gitignore強化

### Phase 2: ドキュメント整理 ✅

- [x] `quota-watch-menubar-docs/` → `docs-archive/` に移動
- [x] README.md 更新

### Phase 3: コード整理 ✅

- [x] Utils統合（現状維持で適切）
- [x] 未使用コード削除（該当なし）
- [x] 不要import削除

### Phase 4: アーキテクチャ改善（部分完了）

- [x] QuotaEngine分割（715行 → 631行、-11.7%）
  - QuotaEngineProtocol.swift（92行）を抽出
- [ ] ContentViewModel軽量化（保留）

### Phase 5: テスト再設計

- [ ] テスト構造再編成
- [ ] テストヘルパー整理

---

## 結果

| 項目 | 変更前 | 変更後 | 状態 |
|------|--------|--------|------|
| QuotaEngine.swift | 715行 | 631行 | ✅ 改善 |
| ドキュメント | quota-watch-menubar-docs/ | docs-archive/ | ✅ 整理 |
| ビルド | - | 成功 | ✅ |

---

## 今後の改善案

- QuotaEngineのさらなる分割（高リスク）
- ContentViewModelの軽量化
- テスト構造の見直し

---

## 関連ドキュメント

- [CLAUDE.md](./CLAUDE.md)
- [アーカイブ: UI再設計計画](./.claude/memory/archive/Plans-2026-02-15-ui-redesign-completed.md)
