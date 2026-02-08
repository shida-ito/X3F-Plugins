# X3F for Lightroom (X3FforLr)

SIGMA Merrill / Quattro シリーズのX3Fファイルを、Adobe Lightroom Classicで扱えるDNG形式に一括変換するためのプラグインです。
Kalpanika プロジェクトの `x3f_extract` ツール（DNG変換）と `exiftool`（メタデータコピー）を内部で使用し、スムーズなワークフローを提供します。

## 特徴
- Lightoom Classicの「プラグイン エクストラ (Plug-in Extras)」メニューから直接呼び出し可能
- 指定したフォルダ内のX3Fファイルを一括でDNGに変換
- **DNGの出力先フォルダを任意に選択可能**（デフォルトは元画像と同じ場所）
- `exiftool` を使用して、撮影日時・ISO感度・絞り・シャッタースピードなどのEXIF情報をDNGに自動コピー
- **Merrillシリーズ（DP1M/DP2M/DP3M）特有のグリーンノイズ（右端の色被り）を修正するパッチを適用済み**
- macOS用バイナリ（`x3f_extract` および `exiftool`）を同梱済みのため、別途ツールのインストールは不要

## 動作環境
- **OS**: macOS (Apple Silicon / Intel)
  - 同梱の `x3f_extract` は Apple Silicon (arm64) 環境での動作を確認しています。
- **Host App**: Adobe Lightroom Classic

## インストール方法
1. このリポジトリをダウンロード（またはClone）します。
2. フォルダ内の `X3FforLr.lrplugin` を任意の場所（例: `~/Documents/Plugins/`）に保存します。
3. Lightroom Classic を起動し、メニューから **「ファイル」 > 「プラグインマネージャー」** を開きます。
4. 左下の **「追加」** ボタンをクリックし、先ほど保存した `X3FforLr.lrplugin` フォルダを選択します。
5. プラグインがリストに追加され、正常に「有効」となっていることを確認して「完了」をクリックします。

## 使い方
1. Lightroom Classic の「ライブラリ」モジュールを開きます。
2. メニューバーの **「ファイル」 > 「プラグイン エクストラ」 > 「Convert X3F (Kalpanika)」** を選択します。
3. ファイル選択ダイアログが表示されるので、**X3Fファイルが保存されているフォルダ** を選択します。
4. 次に、**DNGファイルの保存先** を尋ねられます。
   - 「Yes (Default)」を選ぶと、元のX3Fと同じフォルダに保存されます。
   - 「Select Different Folder」を選ぶと、保存先フォルダを選択できます。
5. 自動的に変換処理が開始されます。
   - 変換の進捗は左上のプログレスバーに表示されます。
   - 変換済みのDNGファイルが既に存在する場合は、処理をスキップします。
   - 変換完了後、DNGファイルにEXIF情報がコピーされます。
6. 処理が完了するとダイアログが表示されます。生成されたDNGファイルをLightroomに読み込んで編集を行ってください。

## 開発者向け情報: バンドルについて
本リポジトリには `exiftool` の実行ファイルだけでなく、必要なPerlライブラリ（`lib` フォルダ）も同梱しています。
これにより、Perlがインストールされている環境であれば、追加の依存関係なしに `exiftool` が動作します。
万が一動作しない場合は、システムにインストールされた `/usr/local/bin/exiftool` をフォールバックとして使用します。

## トラブルシューティング
- **エラーが発生する場合**:
  - ダイアログに表示されるパス（通常は `~/Library/Logs/Adobe/Lightroom/LrClassicLogs/X3FConvert.log`）のログファイルを確認してください。
  - 外部ドライブ上のファイルを変換する場合、ドライブのアクセス権限を確認してください。

## ライセンスとクレジット
本プラグイン自体は **MIT ライセンス** の下で提供されています。詳細は `LICENSE` ファイルをご確認ください。

本プラグインは、以下の優れたオープンソース・ソフトウェアを同梱・使用しています。各ツールのライセンス条項に基づき再配布を行っています。

### x3f_extract (Kalpanika)
- **Project**: [https://github.com/kalpanika/x3f](https://github.com/kalpanika/x3f)
- **License**: BSD-style License
- **Copyright**: (c) 2015, Roland Karlsson, Erik Karlsson, Mark Roden and contributors.

### ExifTool
- **Project**: [https://exiftool.org/](https://exiftool.org/)
- **License**: Perl Artistic License / GNU GPL
- **Copyright**: (c) 2003-2025, Phil Harvey

## メンテナンスと免責
本プロジェクトは、個人の趣味として作成・公開されたものです。
**機能追加の要望、バグ報告、Pull Request等は受け付けておりません**ので、あらかじめご了承ください。
ソースコードはMITライセンスの下で公開されていますので、必要に応じてForkしてご自由にお使いください。
本ソフトウェアの使用により生じたいかなる損害についても、作者は責任を負いません。
