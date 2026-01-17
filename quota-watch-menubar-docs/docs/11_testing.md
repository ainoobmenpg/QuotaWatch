# 11. テスト計画

## 単体テスト（XCTest）
- nextResetTime の parse
  - epoch秒 / epochミリ秒 / ISO文字列 / 空
- 使用率計算
  - percentage優先 / usage-number計算
- バックオフ計算
  - factor更新、上限クリップ、ジッター範囲
- ロールバック防止
  - lastKnownResetEpoch から大きく戻る候補は無視

## 結合テスト（手動）
- APIキー未設定
  - UIが設定導線を提示
- 通知許可
  - テスト通知が表示され、通知設定から制御できる
- レート制限模擬
  - QuotaClientをモックし、429/1302等でバックオフが動く
- スリープ復帰
  - 復帰後に状態が継続し、通知が重複しない

