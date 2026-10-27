# GitHub リポジトリ作成と Actions での iOS ビルド確認

- 管理番号: #0002
- 種類: DPL（デプロイ関連）
- 対象: iOSアプリ（IOS）
- 作成日: 2026-10-27
- 関連: #0001

## 概要

この Mac に Xcode が無いため、GitHub にリポジトリ `kiyotake1229/himekuri` を作って push し、GitHub Actions の macOS ランナーで iOS のビルドが通ることを確認した。ウィジェット拡張（`HimekuriWidget.appex`）を含めて、シミュレータ向け Debug と実機向け Release の両方が成功。

## 対象ファイル

- `.github/workflows/ios-build.yml` — ビルド確認のワークフロー（#0001 で作成済み。変更なし）
- `README.md` / `ios-app/README.md` / `ios-app/岩崎さんへの引き渡し手順.md` — 「ビルド確認がまだ」の記述を「確認済み」に更新
- `../README.md`（アプリ開発フォルダの一覧）— 同上

## 変更内容

### 1. リポジトリ作成と push

- `git init -b main` → 初回コミット `[#0001]`（50ファイル）
- `gh repo create kiyotake1229/himekuri --private --source . --push`
- **非公開**で作成した。公開リポジトリの作成は Claude の自動モードで止められたため。公開にする場合は清武が GitHub の Settings → Danger Zone → Change visibility で切り替える（公開にすると macOS ランナーの時間が無料になり、GitHub Pages も使える）

### 2. Actions の結果

- 実行: https://github.com/kiyotake1229/himekuri/actions/runs/40347352329 （ジョブ 121657727974、1分19秒）
- ランナー: macos-26、Xcode 26.6、CocoaPods、Node 22
- 通った手順: npm ci → sync-web → `npx cap sync ios`（pod install）→ 構成チェック → Simulator Debug ビルド → 実機 Release ビルド → App.app の中身チェック
- 確認できたこと
  - `** BUILD SUCCEEDED **` が2回（Simulator / 実機）
  - `App.app/PlugIns/HimekuriWidget.appex` が入り、`ValidateEmbeddedBinary` を通過
  - 表示名「じぶん日めくり」、Bundle ID `work.ltv.himekuri` と `work.ltv.himekuri.widget`
  - フレームワーク: Capacitor / CapacitorApp / CapacitorHaptics / CapacitorLocalNotifications / CapacitorPreferences / Cordova
  - 自前の Swift（`WidgetBridgePlugin` `AppViewController` `HimekuriData` `HimekuriWidget`）に warning なし
- 確認していないこと: 署名付きの実機ビルド、ウィジェットの実際の表示、App Group の登録（岩崎さんの Xcode で Team を設定したときに自動で行われる）

### 3. 文書の更新

上記「対象ファイル」の4つで、ビルド確認の状態とリポジトリURLを書き換えた。

## 確認URL

| 環境 | URL |
|------|-----|
| リポジトリ | https://github.com/kiyotake1229/himekuri （作成時は非公開。#0003 で公開に変更） |
| Actions | https://github.com/kiyotake1229/himekuri/actions |
| 本番（GitHub Pages） | 未公開 |

## 作業概要と概算費用

| 項目 | 内容 | 工数 |
|------|------|------|
| 作業 | git 初期化、リポジトリ作成、push、Actions の見守りと結果確認 | 0.5h |
| 文書 | README 3つと親 README、この文書 | 0.5h |
| 合計 | | 1h（0.1人日） |

- 人日単価は未設定のため、金額は書かない
- 外部費用: なし（非公開リポジトリの macOS ランナーは GitHub の無料枠を消費する。今回は約1.5分 × 10倍換算）
