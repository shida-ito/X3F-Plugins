# X3F Plugins (Lightroom & Capture One)

> [English](README.md) | **日本語**

SIGMA Merrill / Quattro シリーズのX3Fファイルを、DNG形式に一括変換するためのプラグイン群です。
Kalpanika プロジェクトの `x3f_extract` ツール（DNG変換）と `exiftool`（メタデータコピー）を内部で使用し、各現像ソフトとのスムーズなワークフローを提供します。

## 主な特徴
- **マルチプロセスによる高速変換**: CPUのマルチコアを活かした並列処理で、大量のファイルを高速に処理
- **Lossless JPEG (LJPEG) 圧縮**: DNGファイルをロスレス圧縮し、画質を一切損なわずにファイルサイズを約60%に削減（デフォルトで有効）
- **サブフォルダの自動再帰処理**: サブフォルダ内のX3Fファイルも自動的に検出して一括変換
- **デノイズのオン/オフ切替**: 変換時のデノイズ処理を無効にして、現像ソフト側でノイズ処理を行うことも可能
- **Exif情報の完全コピー**: 撮影日時・ISO感度・絞り・シャッタースピードなどの情報をDNGに自動コピー
- **Merrillシリーズの補正**: DP1M/DP2M/DP3M特有のグリーンノイズ（右端の色被り）を修正するパッチを適用済み
- **ホワイトレベル正規化（Capture One ハイライト補正）**: Capture One で Foveon RAW を開いたときにハイライトが黄色になる問題を解消します。詳細は後述。
- **macOS用バイナリ同梱**: `x3f_extract` および `exiftool` を同梱済みのため、別途インストールは不要

## 動作環境
- **OS**: macOS (Apple Silicon / Intel)
  - 同梱の `x3f_extract` は Apple Silicon (arm64) 環境での動作を確認しています。
- **対応ソフト**: 
  - Adobe Lightroom Classic
  - Capture One (macOSのみ)

---

## Adobe Lightroom Classic で使う

### 1. インストール
1. [Releases ページ](https://github.com/shida-ito/X3F-Plugins/releases) から最新版をダウンロードして展開します。
2. ターミナルで展開した `Lightroom` フォルダに移動し、インストールスクリプトを実行します：
   ```bash
   cd Lightroom
   bash install.sh
   ```
   隔離フラグの解除と Apple Silicon Mac で必要なコードサインを自動的に処理します。
3. Lightroom Classic を起動し、**「ファイル」 > 「プラグインマネージャー」** を開きます。
4. **「追加」** ボタンをクリックし、スクリプト出力の最後に表示された `X3FforLrC.lrplugin` フォルダを選択します。
5. ステータスが「有効」となっていることを確認して「完了」をクリックします。

### 2. 使い方
1. メニューバーの **「ファイル」 > 「プラグイン エクストラ」 > 「Convert X3F (Kalpanika)」** を選択します。
2. **X3Fファイルが保存されているフォルダ** を選択します。
3. **変換設定（X3F Conversion Settings）** ダイアログで設定を確認し「OK」をクリックします。
   - **Parallel Processing**: 並列処理の有効化
   - **Concurrent Jobs**: 同時実行プロセス数（CPUコア数に応じて自動設定）
   - **Compression**: Lossless JPEG（LJPEG）圧縮でファイルサイズを約60%に削減（デフォルトで有効）
   - **Denoise**: 変換時にデノイズを適用（現像ソフト側で処理する場合は無効化）
   - **Output Folder**: DNGファイルの保存先（任意に選択可能）
4. プログレスバーが表示され、変換が開始されます。完了後、生成されたDNGファイルを読み込んでください。

> **初回実行時の注意**: macOS が同梱バイナリをブロックする場合があります。セキュリティ警告が表示された場合は、後述の「[初回実行時のセキュリティ許可](#初回実行時のセキュリティ許可-macos)」を参照してください。警告ダイアログは**ファイル1枚ごとに表示される**ため、最初は1枚だけでテストしてから大量処理を行うことをお勧めします。

---

## Capture One で使う

### 1. インストール方法
ターミナルを使用して、スクリプトと必要なリソースを一括で配置します。
1. [Releases ページ](https://github.com/shida-ito/X3F-Plugins/releases) から最新版をダウンロードして展開し、ターミナルで `CaptureOne` フォルダに移動して実行します：
   ```bash
   cd CaptureOne
   bash install_fix.sh
   ```
2. Capture One を起動し、メニューバーの **「スクリプト」 > 「Update Scripts Menu」** を実行します。

### 2. 使い方
1. メニューバーの **「スクリプト」 > 「X3F Converter」** を選択します。
2. 処理したい **X3Fファイルが入ったフォルダ** を選択します。
3. **[X3F Conversion Settings]** ダイアログで各設定を確認・編集し「OK」をクリックします：
   - **Jobs**: 同時並列処理数（デフォルト: 4）
   - **LJPEG**: Lossless JPEG 圧縮 — `yes` でファイルサイズを約60%削減（デフォルト: yes）
   - **Denoise**: 変換時にデノイズを適用 — `no` で現像ソフト側で処理（デフォルト: yes）
   - **Normalize WL**: ホワイトレベル正規化（Capture One のハイライト黄色補正）（デフォルト: no、推奨: yes）
4. 変換がバックグラウンドで開始されます。進行状況は通知センターに表示されます。
5. 変換完了後、自動的に Capture One のインポート画面が開くので、DNGファイルをインポートしてください。

> **初回実行時の注意**: macOS が同梱バイナリをブロックする場合があります。セキュリティ警告が表示された場合は、後述の「[初回実行時のセキュリティ許可](#初回実行時のセキュリティ許可-macos)」を参照してください。警告ダイアログは**ファイル1枚ごとに表示される**ため、最初は1枚だけでテストしてから大量処理を行うことをお勧めします。

---

## ホワイトレベル正規化 — Capture One ハイライト補正

### 背景
Foveon センサーはチャンネルごとに異なる物理的なホワイトレベルを持っています（例: DP2M は R=16383、G=6828、B=3790）。B チャンネルが最も早く飽和するため、Capture One が per-channel ホワイトレベルを無視して R チャンネルの値を全チャンネルに適用すると、B チャンネルが Capture One から見て「まだ余裕がある」状態になり、**ハイライト部分が黄色く**なる問題が発生します。

### 処理内容
**ホワイトレベル正規化**オプション（`-normalize-wl`）は DNG 書き出し前に以下の処理を行います：

1. **K スケール正規化**: `K = 1/max(ASN)` を各チャンネルに適用し、最も早く飽和するチャンネルが `AsShotNeutral` で 1.0 になるよう揃えます。ホワイトレベルを均一化します。
2. **ハイライトクランプ**: 飽和チャンネル（B）が物理的な上限に近づいたとき、他のチャンネルをスムースステップ曲線でニュートラルグレーの上限値に向けてブレンドします。極端なハイライトでも黄色が出ないようにします。
3. **露出補正**: `BaselineExposure` に `+log2(1/K)` EV を加算し、正規化なしの場合と同じ明るさで LR/C1 に表示されるよう補正します。

LJPEG 圧縮との組み合わせ（`-ljpeg -normalize-wl`）にも対応しています。

### 有効にする方法
- **Capture One**: 変換中に表示される「ホワイトレベル正規化（Normalize WL）を適用しますか？」ダイアログで **「適用する (Yes)」** を選択します。

> **注意**: このオプションは Capture One 専用です。Lightroom は per-channel ホワイトレベルを正しく処理するため不要であり、有効にするとハイライトの諧調が若干失われます。Lightroom プラグインにはこのオプションは表示されません。

---

## 共通の注意事項

### 初回実行時のセキュリティ許可 (macOS)
- **Capture One**: `install_fix.sh` が隔離フラグの削除とコードサインを自動的に処理します。手動操作は不要です。
- **Lightroom**: `install.sh` が隔離フラグの削除とコードサインを自動的に処理します。手動操作は不要です。

### ⚠️ DNGプレビューの表示制限
macOSの「プレビュー」や「クイックルック」で変換後のDNGを見ると **画像が赤っぽく表示される** ことがありますが、これはmacOS側の制限です。**LightroomやCapture One等の対応ソフトで開けば、正常な色で表示・編集できます。**

### SDカードからの直接変換について
SDカードの転送速度がボトルネックとなるため、高速に処理したい場合は一旦内蔵SSD等の高速ストレージにコピーしてから実行することをお勧めします。

## 開発者向け情報

### x3f_extract のビルド
`x3f_extract` をビルドする前に OpenCV のビルドが必要です。cmake の設定はリポジトリに含まれているため、ビルドステップのみ実行してください。

```bash
# Step 1: OpenCV をビルド（初回のみ。10〜30分かかります）
cd x3f_source/deps/src/osx-x86_64/opencv_build
make -j$(sysctl -n hw.logicalcpu) install

# Step 2: x3f_extract をビルド
cd x3f_source/src && make

# コマンドラインからの使用例
./bin/osx-x86_64/x3f_extract -dng -ljpeg -o /output/dir input.X3F
./bin/osx-x86_64/x3f_extract -dng -ljpeg -normalize-wl -o /output/dir input.X3F
```

**出力形式** — いずれか1つを指定：

| フラグ | 説明 |
|--------|------|
| `-dng` | DNG（Linear RAW）として出力 — Lightroom / Capture One で推奨 |
| `-tiff` | 16bit sRGB TIFF として出力 — ホワイトバランスが焼き込まれた現像済み画像 |
| `-jpg` | JPEG として出力 |
| `-ppm` | PPM として出力 |

**圧縮** — DNG 出力時に使用：

| フラグ | 説明 |
|--------|------|
| `-ljpeg` | ✅ *本プロジェクトで追加* — Lossless JPEG 圧縮（約60%サイズ削減、画質劣化なし） |

**処理オプション**：

| フラグ | 説明 |
|--------|------|
| `-normalize-wl` | ✅ *本プロジェクトで追加* — チャンネルごとのホワイトレベルを正規化。Capture One のハイライト黄色問題を解消。Capture One ユーザーに推奨。 |
| `-no-denoise` | 変換時のデノイズを無効化（現像ソフト側でノイズ処理する場合に使用） |
| `-no-crop` | センサークロップを無効化（マスク領域を含む） |
| `-wb <mode>` | ホワイトバランスモードを指定（例: `auto`、`sunlight`） |

**出力先**：

| フラグ | 説明 |
|--------|------|
| `-o <dir>` | 出力ディレクトリの指定 |

ビルド後はバイナリをプラグインにコピーし、コードサインを適用してください：
```bash
cp x3f_source/bin/osx-x86_64/x3f_extract CaptureOne/X3F_Resources/bin/x3f_extract
cp x3f_source/bin/osx-x86_64/x3f_extract Lightroom/X3FforLrC.lrplugin/bin/x3f_extract

# Capture One: install_fix.sh を実行 — codesign を自動処理
cd CaptureOne && bash install_fix.sh

# Lightroom: 手動で codesign を適用
codesign -s - --force Lightroom/X3FforLrC.lrplugin/bin/x3f_extract
```

> **注意**: Apple Silicon（macOS Sequoia 以降）では、arm64 バイナリの実行に最低限の ad-hoc コードサインが必要です。Capture One は `install_fix.sh` が自動処理します。Lightroom は上記の `codesign` コマンドを手動で実行してください。

### バンドルについて
本リポジトリには `exiftool` の実行ファイルだけでなく、必要な Perl ライブラリ（`lib` フォルダ）も同梱しています。万が一動作しない場合は、システムにインストールされた `/usr/local/bin/exiftool` にフォールバックします。

## トラブルシューティング
- **エラーが発生する場合**: Lightroom のログ（`~/Library/Logs/Adobe/Lightroom/LrClassicLogs/X3FforLrC.log`）を確認してください。
- **外部ドライブ上のファイル**: アクセス権限を確認してください。

## ライセンスとクレジット
本プラグイン自体は **MIT ライセンス** の下で提供されています。

### x3f_extract (Kalpanika)
- **Project**: [https://github.com/kalpanika/x3f](https://github.com/kalpanika/x3f)
- **License**: BSD-style License
- **Copyright**: (c) 2015, Roland Karlsson, Erik Karlsson, Mark Roden and contributors.

### ExifTool
- **Project**: [https://exiftool.org/](https://exiftool.org/)
- **License**: Perl Artistic License / GNU GPL
- **Copyright**: (c) 2003-2025, Phil Harvey

## 免責事項
個人作成のプロジェクトにつき、機能追加要望やPRは受け付けておりません。本ツールの使用による損害について作者は責任を負いません。
