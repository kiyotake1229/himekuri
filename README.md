# じぶん日めくり

自分で作る日めくりカレンダー。言葉や写真をカードにしておくと、毎朝1枚めくれる。1行だけ書くと、来週・来月・来年の今日に届く。

| 項目 | 内容 |
|---|---|
| 状態 | **Web版は GitHub Pages で公開中。iOS版は GitHub Actions（Xcode 26.6）でビルド確認済み** |
| Web公開（サポートURL） | https://kiyotake1229.github.io/himekuri/ |
| 開発中の確認 | https://claude.ai/artifact/Q6EnVGFaVE8Y4HtQcZW8vF （Claude Artifact。共有設定した人だけ開ける） |
| GitHub | https://github.com/kiyotake1229/himekuri （公開リポジトリ。`main` のルートを GitHub Pages で配信） |
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

- iOS のビルド確認（2026-10-27、GitHub Actions の macOS ランナー、Xcode 26.6）。シミュレータ向け Debug と実機向け Release の両方が通り、`App.app/PlugIns/HimekuriWidget.appex` が入ることまで確認済み（https://github.com/kiyotake1229/himekuri/actions/runs/40347352329 ）

残っていること

1. `ios-app/` で `npm run icons`（アイコン・起動画面の生成）。Xcode のある環境で
2. 実機でウィジェットの表示を確認（ホーム画面 小・中・大、ロック画面 長方形・1行・丸）
3. App Store 用スクリーンショット

---

## 開発ドキュメント

開発の記録は `docs/` で管理している。命名規則・連番のルールは [docs/README.md](docs/README.md)。

- 現状の仕様と構成（最初の1本）: [docs/20261027_DOC_0001_ALL_現状の仕様と構成.md](docs/20261027_DOC_0001_ALL_現状の仕様と構成.md)
- 機能追加・バグ修正・改善をしたら、1件ごとに文書を足して `bash docs/manager/generate_docs_json.sh` を実行する（一覧: `docs/manager/docs.json`）

---

## 岩崎さんへ

iOS 版のビルド・申請手順は **[ios-app/岩崎さんへの引き渡し手順.md](ios-app/岩崎さんへの引き渡し手順.md)** にまとめてあります。
ビルドが通ることは GitHub Actions（Xcode 26.6）で確認済みです。

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
Web版（GitHub Pages）は `index.html` を push すれば数十秒で更新される。`sw.js` のキャッシュ名（`himekuri-v1`）も上げると、入れ替わりが確実になる。
Artifact は Claude から同じファイルを公開し直す。
