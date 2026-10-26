# じぶん日めくり iOSアプリ（Capacitor + WidgetKit）

Webアプリ本体（`../index.html`）をネイティブiOSアプリとして同梱し、ホーム画面・ロック画面のウィジェットを Swift で足したプロジェクトです。

- **申請・アップロードは岩崎さんが実施** → 手順は [`岩崎さんへの引き渡し手順.md`](岩崎さんへの引き渡し手順.md)
- このREADMEは開発側（アプリを作る人）向けのメモです

---

## 現在の状態

| 項目 | 状態 |
|------|------|
| Capacitorプロジェクト | 構築済み（`work.ltv.himekuri` / じぶん日めくり） |
| Xcodeプロジェクト生成 | 済み（`ios/App/App.xcworkspace`） |
| Webアプリ同梱 | 済み（`ios/App/App/public/`） |
| アイコン・起動画面の元画像 | `assets/icon.png` `assets/splash.png` `assets/splash-dark.png`（`npm run icons` で生成する。**未実行**） |
| ネイティブ通知・触覚・ネイティブ保存 | 組み込み済み（`index.html` 側で `NATIVE` 分岐） |
| ウィジェット拡張（`HimekuriWidget`） | Xcodeプロジェクトに組み込み済み（`ios/App/Widget/`） |
| App Group（`group.work.ltv.himekuri`） | App と Widget の entitlements に設定済み |
| `pod install` | **未実行**（この Mac に Xcode が無いため。Xcode のある環境で `npx cap sync ios`） |
| ビルド確認 | **未実施**。GitHub に push すると `.github/workflows/ios-build.yml` が macOS ランナーで確認する |

---

## 構成

```
ios-app/
├── package.json              npm設定（Capacitor + プラグイン）
├── capacitor.config.json     アプリID・名前・プラグイン設定
├── sync-web.sh               ../のWebアプリを www/ にコピー（sw.js は除く）
├── assets/                   アイコン・起動画面の元画像
├── tools/add-widget-target.rb  Xcodeプロジェクトにウィジェット拡張を組み込むスクリプト（実行済み）
├── www/                      同梱するWeb資産（自動生成・git管理外）
└── ios/App/
    ├── App.xcworkspace       ← これを開く（pod install 後にできる）
    ├── App.xcodeproj         App と HimekuriWidget の2ターゲット
    ├── App/
    │   ├── WidgetBridgePlugin.swift   JS→App Group の橋渡し（setData / saveImage / removeImage / clear / reload）
    │   ├── AppViewController.swift    上のプラグインを Capacitor に登録する ViewController
    │   ├── App.entitlements           App Group
    │   └── Base.lproj/Main.storyboard customClass を AppViewController に変更済み
    └── Widget/
        ├── HimekuriWidget.swift   ウィジェットの見た目（今日の1枚 / この日のひとこと）
        ├── HimekuriData.swift     JSONを読み、JSと同じ手順でその日のカードを選ぶ
        ├── Info.plist             NSExtensionPointIdentifier = com.apple.widgetkit-extension
        └── Widget.entitlements    App Group
```

## よく使うコマンド

```bash
npm install        # 依存取得（初回のみ）
npm run sync       # ../index.html の変更をiOSプロジェクトへ反映（cap sync = copy + pod install）
npm run icons      # アイコン・起動画面を生成（assets/ から）
npm run open       # Xcodeで開く（要Xcode）
```

## データの流れ（ウィジェット）

1. `index.html` の `save()` → `syncWidget()` が、カード・ひとこと・設定を JSON にして `WidgetBridge.setData` に渡す
2. `WidgetBridgePlugin.swift` が App Group の共有フォルダに `himekuri.json` を書き、`WidgetCenter.reloadAllTimelines()` を呼ぶ
3. 写真は `putImage()` → `WidgetBridge.saveImage`（長辺600pxのJPEG）→ `img_<カードID>.jpg`
4. `HimekuriData.swift` の `HK.pick(for:data:)` が、JS の `pickFor()` と同じ手順（記念日 → 曜日 → いつでも、FNV-1aハッシュ、前日と同じなら1つずらす）でその日のカードを選ぶ。だからアプリを開かなくてもウィジェットは翌日の1枚を出せる

## メモ

- `Podfile` のターゲットは `App` だけ。ウィジェットは Capacitor を使わないので Pods は不要
- App Groups は「Automatically manage signing」なら Xcode が自動で登録する。署名のチームを変えたら App と HimekuriWidget の両方で Signing を確認する
- `node_modules/` `www/` `Pods/` `public/` はgit管理外
