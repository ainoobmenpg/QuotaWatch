# 10. 常駐（ログイン時起動）

## 方針
- `SMAppService.mainApp.register()` を使用
- 初回起動時に UI でトグルを提供（ON/OFF）

## 注意
- Login Item 登録は、アプリが /Applications 配下にある方が安定
- 署名・公証をしない場合でも、自分用運用なら許容

