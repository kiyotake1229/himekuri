# じぶん日めくり

自分で作る日めくりカレンダー。言葉や写真をカードにしておくと、毎朝1枚めくれる。1行だけ書くと、来週・来月・来年の今日に届く。

| 項目 | 内容 |
|---|---|
| 状態 | **Web版・PWA版は完成。iOS版はプロジェクト構築済み（ビルド確認はまだ）** |
| 動作確認URL | https://claude.ai/artifact/Q6EnVGFaVE8Y4HtQcZW8vF （Claude Artifact。共有設定した人だけ開ける） |
| GitHub Pages | 未作成（リポジトリを作ったら `https://kiyotake1229.github.io/himekuri/` の予定） |
| 本体 | `index.html`（約78KB） |
| 通信 | なし（完全オフライン） |
| データ | 端末内のみ（localStorage。写真は IndexedDB。iOS版はネイティブ保存と App Group にも複製） |
| PWA | 対応（`manifest.json` / `sw.js` / アイコン一式） |
| iOS | Capacitor 7 + WidgetKit → [`ios-app/`](ios-app/) |
| Bundle ID | `work.ltv.himekuri`（ウィジェットは `work.ltv.himekuri.widget`、App Group は `group.work.ltv.himekuri`） |

---

## いまの到達点と残作業

できていること

- Web版の全機能（下記）。ブラウザで動作確認済み
- PWA（ホーム画面に追加してオフラインで動く）
- iOS プロジェクト一式。Capacitor 本体＋ウィジェット拡張（Swift）を Xcode プロジェクトに組み込み済み

残っていること

1. **iOS のビルド確認**。この Mac には Xcode が無い。GitHub にリポジトリを作って push すれば `.github/workflows/ios-build.yml` が macOS ランナーで確認する（他のアプリと同じやり方）
2. `ios-app/` で `npm run icons`（アイコン・起動画面の生成）と `npx cap sync ios`（pod install）。Xcode のある環境で
3. 実機でウィジェットの表示を確認（ホーム画面 小・中・大、ロック画面 長方形・1行・丸）
4. GitHub Pages の公開（App Store のサポートURL用）
5. App Store 用スクリーンショット

---

## 開発ドキュメント

開発の記録は `docs/` で管理している。命名規則・連番のルールは [docs/README.md](docs/README.md)。

- 現状の仕様と構成（最初の1本）: [docs/20261027_DOC_0001_ALL_現状の仕様と構成.md](docs/20261027_DOC_0001_ALL_現状の仕様と構成.md)
- 機能追加・バグ修正・改善をしたら、1件ごとに文書を足して `bash docs/manager/generate_docs_json.sh` を実行する（一覧: `docs/manager/docs.json`）

---

## 岩崎さんへ

iOS 版のビルド・申請手順は **[ios-app/岩崎さんへの引き渡し手順.md](ios-app/岩崎さんへの引き渡し手順.md)** にまとめてあります。
ただし、**ビルドが通ることの確認がまだ**です（上記「残っていること」の1）。確認が済んだらこの README を更新します。

---

## 主な機能

- **カード** — 言葉・写真・出典を1枚にする。「いつでも」「記念日（毎年その日）」「曜日（毎週その曜日）」の3種類。まとめて追加（1行＝1枚）、見本13枚
- **今日の1枚** — 毎日1枚が決まって出る（おまかせ＝日付から決まる乱数 / 順番）。前日と同じカードは出ない。紙を上に引くか右上のボタンで「もう1枚」
- **めくる演出** — 日付が変わって開くと、前の日の紙が破れて今日の紙が出る。紙の音（WebAudioで生成）と振動
- **ひとこと** — 1日1行（100字まで）。書いた1行は「去年の今日」「先月の今日」「先週の今日」「きのう」として今日の画面に戻ってくる
- **きろく** — 書いた日・連続・めくった日、月カレンダー、最近のひとこと。過去の日をタップして後から書ける
- **見た目** — 紙6種（白紙・和紙・クラフト・空・桜・墨）、差し色6色、ゴシック／明朝／丸ゴシック、大きさ、縦書き、明るい／暗い／自動
- **データ** — バックアップの保存／復元（写真込み）、見本の再投入、全消去
- **iOS版だけ** — 朝の通知（7日分、その日のカードの言葉が届く）、ホーム画面ウィジェット「今日の1枚」（小・中・大）、ロック画面ウィジェット（長方形・1行・丸）、「この日のひとこと」ウィジェット

## ファイル構成

```
あなたのアプリ/
  index.html                アプリ本体
  manifest.json / sw.js     PWA用
  icon.svg                  アイコン元データ
  icon-192.png / icon-512.png / icon-512-maskable.png / apple-touch-icon.png
  docs/                     開発ドキュメント
  ios-app/                  iOSプロジェクト（Capacitor + WidgetKit）
    岩崎さんへの引き渡し手順.md
    README.md               開発者向けメモ
  .github/workflows/ios-build.yml   GitHub でのビルド確認（push で動く）
```

## 修正したいとき

`index.html` を直す → `ios-app/` で `npm run sync` → Xcode で再ビルド。
Artifact は Claude から同じファイルを公開し直す。
