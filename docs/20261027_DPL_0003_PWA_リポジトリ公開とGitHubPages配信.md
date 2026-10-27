# リポジトリの公開と GitHub Pages での配信

- 管理番号: #0003
- 種類: DPL（デプロイ関連）
- 対象: PWA（PWA）
- 作成日: 2026-10-27
- 関連: #0002

## 概要

`kiyotake1229/himekuri` を非公開から公開に切り替え、`main` ブランチのルートを GitHub Pages で配信した。Web版（PWA）の一般公開URLであり、App Store 申請のサポートURLとして使う。

## 対象ファイル

- `README.md` / `ios-app/岩崎さんへの引き渡し手順.md` / `../README.md` — 公開URLの記載
- `docs/20261027_DPL_0002_IOS_GitHubリポジトリ作成とActionsビルド確認.md` — 「非公開」の注記を更新
- （配信される側）`index.html` `manifest.json` `sw.js` `icon.svg` `icon-*.png` `apple-touch-icon.png` — 変更なし

## 変更内容

### 1. 公開に変更

```bash
gh repo edit kiyotake1229/himekuri --visibility public --accept-visibility-change-consequences
```

### 2. GitHub Pages を有効化

```bash
gh api -X POST repos/kiyotake1229/himekuri/pages -f "source[branch]=main" -f "source[path]=/"
```

- 配信元: `main` のルート（ビルド工程なし。リポジトリのファイルがそのまま出る）
- URL: https://kiyotake1229.github.io/himekuri/
- 以後は `index.html` を push するだけで更新される。Service Worker がキャッシュするので、確実に入れ替えたいときは `sw.js` の `CACHE` 名を上げる

### 3. 確認したこと

- `https://kiyotake1229.github.io/himekuri/` が 200 で返り、`<title>じぶん日めくり</title>`、`manifest.json` `sw.js` `icon-192.png` も 200
- 配信された `index.html` がローカルと同一

## 確認URL

| 環境 | URL |
|------|-----|
| 本番（GitHub Pages） | https://kiyotake1229.github.io/himekuri/ |
| 開発中の共有 | https://claude.ai/artifact/Q6EnVGFaVE8Y4HtQcZW8vF |
| リポジトリ | https://github.com/kiyotake1229/himekuri |

## 作業概要と概算費用

| 項目 | 内容 | 工数 |
|------|------|------|
| 作業 | 公開化、Pages 有効化、配信の確認 | 0.25h |
| 文書 | README 3つと DPL #0002 の注記、この文書 | 0.25h |
| 合計 | | 0.5h（0.06人日） |

- 人日単価は未設定のため、金額は書かない
- 外部費用: なし（公開リポジトリの Pages と Actions は無料）
