# Plans.md - Liquid Glass UI対応

> **作成日**: 2026-02-15
> **Issue**: #1
> **目的**: macOS 26 (Tahoe) の Liquid Glass デザイン言語に対応

---

## 📋 タスク一覧

### Phase 1: カードコンポーネント [feature:a11y]

#### [ ] T1-1: QuotaCardをLiquid Glass化
**目的**: カード背景をガラス効果に変更

- **対象**: `QuotaWatch/Views/Components/QuotaCard.swift`
- **作業内容**:
  1. `cardBackground()` を `.glassEffect()` に置換
  2. `GlassEffectContainer` でラップ
  3. グラデーションオプションは `.glassEffect(.regular.tint())` に移行
- **受入条件**:
  - [ ] カードが透明なガラス効果で表示される
  - [ ] ダークモード/ライトモード両対応
  - [ ] 既存のテストがパスする

#### [ ] T1-2: PrimaryQuotaViewのガラス化
**目的**: プライマリクォータ表示をガラス効果に

- **対象**: `QuotaWatch/Views/PrimaryQuotaView.swift`
- **作業内容**:
  1. `QuotaCard` の変更を反映
  2. 進捗バー等のサブ要素を確認
- **受入条件**:
  - [ ] ガラス効果が適用される
  - [ ] グラデーション色が維持される

#### [ ] T1-3: SecondaryQuotaViewのガラス化
**目的**: セカンダリクォータ表示をガラス効果に

- **対象**: `QuotaWatch/Views/SecondaryQuotaView.swift`
- **作業内容**:
  1. `QuotaCard` の変更を反映
- **受入条件**:
  - [ ] ガラス効果が適用される

#### [ ] T1-4: StatusViewのガラス化
**目的**: ステータス表示をガラス効果に

- **対象**: `QuotaWatch/Views/StatusView.swift`
- **作業内容**:
  1. `QuotaCard` の変更を反映
- **受入条件**:
  - [ ] ガラス効果が適用される

---

### Phase 2: ボタンとコントロール [feature:a11y]

#### [ ] T2-1: アクションボタンのガラス化
**目的**: アクションボタンをガラススタイルに

- **対象**: `QuotaWatch/Views/ActionsView.swift`
- **作業内容**:
  1. `Button` に `.buttonStyle(.glass)` を適用
  2. `GlassEffectContainer` でボタン群をラップ
- **受入条件**:
  - [ ] ボタンがガラス効果で表示される
  - [ ] ホバー/クリック時のインタラクションが動作

#### [ ] T2-2: HeaderViewのガラス化
**目的**: ヘッダーにガラス効果を適用

- **対象**: `QuotaWatch/Views/HeaderView.swift`
- **作業内容**:
  1. ヘッダー背景に `.glassEffect()` を適用
- **受入条件**:
  - [ ] ガラス効果が適用される

---

### Phase 3: 設定画面 [feature:a11y]

#### [ ] T3-1: SettingsViewのガラス化
**目的**: 設定画面にガラス効果を適用

- **対象**: `QuotaWatch/Views/SettingsView.swift`
- **作業内容**:
  1. 設定セクションに `.glassEffect()` を適用
  2. トグル等のコントロールを確認
- **受入条件**:
  - [ ] 設定カードがガラス効果で表示される
  - [ ] トグル操作が正常に動作

---

### Phase 4: ポップアップ全体

#### [ ] T4-1: MenuBarPopupViewの統合
**目的**: ポップアップ全体をGlassEffectContainerで統合

- **対象**: `QuotaWatch/Views/MenuBarPopupView.swift`
- **作業内容**:
  1. 全体を `GlassEffectContainer` でラップ
  2. 適切な `spacing` を設定
  3. モーフィングアニメーションを確認
- **受入条件**:
  - [ ] 全要素が統一的なガラス効果を持つ
  - [ ] スクロール時の描画が正常

---

### Phase 5: テストと検証

#### [ ] T5-1: ビルド確認
**目的**: 全変更後もビルドが成功することを確認

- **作業内容**:
  1. `xcodebuild build` でビルド確認
  2. 警告があれば対応
- **受入条件**:
  - [ ] ビルド成功
  - [ ] エラーなし

#### [ ] T5-2: テスト実行
**目的**: 既存テストがパスすることを確認

- **作業内容**:
  1. `xcodebuild test` でテスト実行
  2. 失敗があれば対応
- **受入条件**:
  - [ ] 全テストパス

#### [ ] T5-3: 視覚確認
**目的**: 実際にアプリを起動して確認

- **作業内容**:
  1. アプリを起動
  2. メニューバーポップアップを確認
  3. 各カード、ボタンのガラス効果を確認
- **受入条件**:
  - [ ] 視覚的にLiquid Glass効果が確認できる
  - [ ] 動作に問題なし

---

## 🔧 API リファレンス

### 主要API

```swift
// 基本的なガラス効果
.glassEffect()

// カスタムシェイプとティント
.glassEffect(.regular.tint(.blue), in: .rect(cornerRadius: 12))

// インタラクティブなガラス
.glassEffect(.regular.interactive())

// ボタンスタイル
.buttonStyle(.glass)

// 複数要素の統合
GlassEffectContainer(spacing: 40) {
    // ガラス要素
}
```

### バリアント

| バリアント | 用途 |
|-----------|------|
| `.regular` | デフォルト（中程度の透明度） |
| `.clear` | 高透明度（メディア背景向け） |
| `.identity` | ガラス効果無効化 |

---

## 📊 優先度マトリックス

| タスク | 優先度 | 影響度 | 工数 |
|--------|--------|--------|------|
| T1-1 QuotaCard | **Required** | 高 | 小 |
| T1-2 PrimaryQuotaView | **Required** | 高 | 小 |
| T1-3 SecondaryQuotaView | Recommended | 中 | 小 |
| T1-4 StatusView | Recommended | 中 | 小 |
| T2-1 ActionsView | Recommended | 中 | 小 |
| T2-2 HeaderView | Optional | 低 | 小 |
| T3-1 SettingsView | Optional | 低 | 小 |
| T4-1 統合 | **Required** | 高 | 小 |
| T5-1〜3 検証 | **Required** | 高 | 中 |

---

## 📝 メモ

- 個人用アプリのため、後方互換性は不要
- Xcode 26.2, macOS 26 (Tahoe) 環境
- Liquid GlassはiOS 26/macOS 26のネイティブAPIを使用
