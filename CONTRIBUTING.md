# Contributing to QuotaWatch

貢献していただきありがとうございます。このドキュメントでは、QuotaWatchプロジェクトへの貢献方法を説明します。

## 開発フロー

1. **Issueを確認**: 既存のIssueを確認し、作業したいタスクを選択します
2. **ブランチを作成**: Issueに対応するブランチを作成します
3. **実装**: コードを実装し、テストを追加します
4. **テスト**: すべてのテストがパスすることを確認します
5. **Pull Request**: 変更内容を説明するPRを作成します

## ブランチ命名規約

```
feature/ISSUE_NUMBER-brief-description
```

例: `feature/7-create-zai-provider-network-layer`

## コーディング規約

### Swift

- **Swift 6** で実装
- **OSLog** でカテゴリ別ロギング
- **async/await** を優先
- **actor** による競合回避
- 可能な限りネイティブ実装（外部ライブラリ依存なし）

### コードスタイル

- SwiftAPIガイドラインに従う
- 適切なアクセス修飾子を使用
- 複雑なロジックにはコメントを追加

### テスト

- XCTestを使用
- 単体テストは以下を対象:
  - `nextResetTime` のパース（秒/ミリ秒/ISO文字列）
  - 使用率計算ロジック
  - バックオフ計算
  - ロールバック防止ロジック

## テスト方法

```bash
# すべてのテストを実行
xcodebuild test -scheme QuotaWatch -destination 'platform=macOS'

# 特定のテストを実行
xcodebuild test -scheme QuotaWatch -destination 'platform=macOS' -only-testing:QuotaWatchTests/UsageSnapshotTests
```

## プル Requestの作成

PRを作成する際は、以下を含めてください:

1. **関連Issue**: `Fixes #ISSUE_NUMBER` または `Closes #ISSUE_NUMBER`
2. **変更内容の説明**: 何を変更し、なぜ変更したか
3. **テスト方法**: 手動テストした内容
4. **スクリーンショット**: UI変更の場合はBefore/After

## 受け入れ基準

すべてのPRは以下を満たす必要があります:

- [ ] すべてのテストがパスする
- [ ] コードがSwift 6モードでコンパイルされる
- [ ] 新機能にはテストが含まれている
- [ ] 設計ドキュメントの仕様に従っている
- [ ] APIキーがKeychainのみで管理されている

## Issueの報告

バグや機能リクエストは、GitHub Issueで報告してください:

1. タイトルに簡潔な説明
2. 再現手順（バグの場合）
3. 期待する動作
4. 実際の動作
5. 環境情報（macOSバージョン）

## 設計ドキュメント

アーキテクチャと詳細仕様については `docs-archive/` を参照してください。
