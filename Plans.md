# QuotaWatch リファクタリング計画

> 作成日: 2026-02-15
> 目的: コード整理・重複排除、アーキテクチャ改善、パフォーマンス改善

## 📋 タスク一覧

### Phase 1: コード整理・重複排除

#### [ ] T1-1: 円グラフ色分けロジックの統一（高優先度）
- **対象ファイル**:
  - `QuotaWatch/Utils/QuotaGauge.swift`
  - `QuotaWatch/Utils/MenuBarDonutIcon.swift`
  - `QuotaWatch/Views/DonutChartView.swift`
  - `QuotaWatch/Views/SecondaryQuotaView.swift`
  - `QuotaWatch/Utils/ColorExtensions.swift`
- **作業内容**:
  1. `QuotaColorCalculator` ユーティリティを作成
  2. 色分けロジック（緑/オレンジ/赤）を一元化
  3. 各コンポーネントから共通ロジックを呼び出し
- **受入条件**:
  - [ ] 色判定ロジックが1箇所に集約されている
  - [ ] 既存のテストがパスする
  - [ ] UI表示に変化がない

#### [ ] T1-2: 時間フォーマットロジックの統一（高優先度）
- **対象ファイル**:
  - `QuotaWatch/Views/StatusView.swift` (88-122行)
  - `QuotaWatch/Utils/TimeFormatter.swift`
- **作業内容**:
  1. `StatusView` の相対時間計算を `TimeFormatter` に移動
  2. `StatusView` から `TimeFormatter` を呼び出し
- **受入条件**:
  - [ ] 時間フォーマットロジックが `TimeFormatter` に集約されている
  - [ ] テストがパスする

#### [ ] T1-3: 数値フォーマットユーティリティの作成（中優先度）
- **対象ファイル**:
  - `QuotaWatch/Views/PrimaryQuotaView.swift` (100-110行)
- **作業内容**:
  1. `NumberFormatterUtil` を作成
  2. K/M簡略表示ロジックを汎用化
- **受入条件**:
  - [ ] 数値フォーマットが再利用可能になっている

---

### Phase 2: アーキテクチャ改善

#### [ ] T2-1: ContentViewModelの責任分離（高優先度）
- **対象ファイル**: `QuotaWatch/ViewModels/ContentViewModel.swift`
- **作業内容**:
  1. 通知管理を `NotificationService` に分離
  2. ダッシュボード操作を `DashboardService` に分離
  3. ViewModelは状態管理のみに特化
- **受入条件**:
  - [ ] ViewModelの責任が状態管理に限定されている
  - [ ] テストがパスする

#### [ ] T2-2: QuotaEngineProtocolの分離（高優先度）
- **対象ファイル**: `QuotaWatch/Engine/QuotaEngine.swift`
- **作業内容**:
  1. `QuotaEngineProtocol` からDEBUGビルド依存メソッドを分離
  2. `QuotaEngineDebugProtocol` を作成
- **受入条件**:
  - [ ] DEBUG/RELEASEで適切なプロトコルが使用されている
  - [ ] テストがパスする

#### [ ] T2-3: 円グラフコンポーネント階層の整理（中優先度）
- **対象ファイル**:
  - `QuotaWatch/Utils/QuotaGauge.swift`
  - `QuotaWatch/Views/DonutChartView.swift`
- **作業内容**:
  1. `BaseDonutChart` プロトコルを定義
  2. コンポーネント階層を整理
- **受入条件**:
  - [ ] コンポーネント階層が明確になっている
  - [ ] テストがパスする

#### [ ] T2-4: AppStateの分割（中優先度）
- **対象ファイル**: `QuotaWatch/Models/AppState.swift`
- **作業内容**:
  1. `FetchState`、`NotificationState` などに分割
  2. 機能ごとの状態管理に変更
- **受入条件**:
  - [ ] 状態が機能別に分割されている
  - [ ] テストがパスする

---

### Phase 3: パフォーマンス改善

#### [ ] T3-1: 円グラフ再計算の最適化（高優先度）
- **作業内容**:
  1. T1-1の `QuotaColorCalculator` で結果をキャッシュ
  2. 不要な再計算を防止
- **受入条件**:
  - [ ] 色計算結果がキャッシュされている
  - [ ] パフォーマンステストで改善が確認できる

#### [ ] T3-2: View更新頻度の最適化（中優先度）
- **対象ファイル**: `QuotaWatch/Views/MenuBarPopupView.swift`
- **作業内容**:
  1. `@State` / `@ObservableObject` の適切な使用範囲を検討
  2. 不要な再描画を防止
- **受入条件**:
  - [ ] スクロール時の再描画が最小化されている

#### [ ] T3-3: アイコン生成ロジックの統一（中優先度）
- **対象ファイル**: `QuotaWatch/Utils/MenuBarDonutIcon.swift`
- **作業内容**:
  1. NSBezierPathとSwiftUIの描画方式を統一（SwiftUI推奨）
- **受入条件**:
  - [ ] 描画方式が統一されている
  - [ ] テストがパスする

---

## 📊 進捗サマリー

| Phase | タスク数 | 完了 | 進捗 |
|-------|---------|------|------|
| Phase 1: コード整理 | 3 | 0 | 0% |
| Phase 2: アーキテクチャ | 4 | 0 | 0% |
| Phase 3: パフォーマンス | 3 | 0 | 0% |
| **合計** | **10** | **0** | **0%** |

---

## 🔗 関連ドキュメント

- [CLAUDE.md](./CLAUDE.md) - プロジェクトガイドライン
- [quota-watch-menubar-docs/](./quota-watch-menubar-docs/) - 設計ドキュメント
