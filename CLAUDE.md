# X3F-Plugins — Claude 向けプロジェクトメモ

## プロジェクト概要

SIGMA X3F (Foveon センサー) RAW ファイルを DNG に変換するツール群。

- `x3f_source/` — C/C++ 変換ライブラリ・CLI (`x3f_extract`)
- `CaptureOne/` — Capture One 向け AppleScript + シェルスクリプト
- `Lightroom/X3FforLrC.lrplugin/` — Lightroom 向け Lua プラグイン

## ビルド手順

```bash
cd x3f_source/src && make
# 出力: x3f_source/bin/osx-x86_64/x3f_extract
# プラグインへのコピー:
cp x3f_source/bin/osx-x86_64/x3f_extract CaptureOne/X3F_Resources/bin/x3f_extract
cp x3f_source/bin/osx-x86_64/x3f_extract Lightroom/X3FforLrC.lrplugin/bin/x3f_extract
```

## 主要ファイル

| ファイル | 役割 |
|---------|------|
| `x3f_source/src/x3f_output_dng.c` | DNG 出力コアロジック |
| `x3f_source/src/x3f_output_dng.h` | 関数シグネチャ |
| `x3f_source/src/x3f_extract.c` | CLI エントリポイント |
| `CaptureOne/X3F_Resources/convert.sh` | Capture One 変換スクリプト |
| `CaptureOne/X3F Converter.applescript` | Capture One UI |
| `Lightroom/X3FforLrC.lrplugin/X3FConvert.lua` | Lightroom UI・変換ロジック |

## 実装済み機能: `-normalize-wl`

### 背景・問題

Foveon センサー (DP2 Merrill 等) の DNG 出力には以下の問題がある:

- **物理的な per-channel WhiteLevel**: R=16383, G=6828, B=3790
- **AsShotNeutral[B] = 1.5807 > 1.0**: B チャンネルの中性点が物理 WL を超えている
  （中性グレーでは B が飽和する）
- **Capture One のバグ**: per-channel WL を読まず WL[0]=16383 を全チャンネルに適用
  → G・B が実際より暗く扱われ、ハイライトが黄色になる

### 解決策

`-normalize-wl` フラグで各チャンネルのピクセル値を正規化する:

```
normalized[c] = (raw[c] - black[c]) / (white[c] - black[c]) × white[0]
WhiteLevel    = white[0] + 1  (= 16384)  ← どのチャンネルも WL に達しない
BlackLevel    = 0 0 0
AsShotNeutral = 変更なし (0.3626, 0.8731, 1.5807)
```

**WL を `white[0] + 1` にする理由**:
ピクセル最大値は 16383 だが WL = 16384 に設定することで、いかなるチャンネルも
「飽和」と判定されない。これにより Capture One のハイライトリカバリが誤動作せず、
B=0 や異常値が発生しない。

### 変更ファイル一覧

1. **`x3f_output_dng.h`** — 関数シグネチャに `int normalize_wl` を追加
2. **`x3f_output_dng.c`** — ピクセル正規化ループ、BlackLevel/WhiteLevel 設定
3. **`x3f_extract.c`** — `-normalize-wl` CLI フラグ
4. **`CaptureOne/X3F_Resources/convert.sh`** — 第8引数 `USE_NORMALIZE_WL` で渡す
5. **`CaptureOne/X3F Converter.applescript`** — ダイアログで Yes/No 選択
6. **`Lightroom/X3FforLrC.lrplugin/X3FConvert.lua`** — `useNormalizeWL` チェックボックス

### 変換後 DNG メタデータ (normalize-wl あり)

```
WhiteLevel   : 16384 16384 16384
BlackLevel   : 0 0 0
AsShotNeutral: 0.3626 0.8731 1.5807
BitsPerSample: 16 16 16
```

## 既知の問題・挙動

### Lightroom / Capture One のプレビューが黄色に見える

**原因**: DNG に埋め込まれたプレビュー JPEG は normalize-wl を適用していない
オリジナルデータから生成されているため、初期表示は黄色になる場合がある。

**各アプリの動作**:
- Lightroom: 初期プレビューは黄色 → 現像を開始すると正しい白飛びに変わる ✓
- Capture One: 初期プレビューは黄色 → セッションキャッシュ構築後に正しくなる（はず）
- Mac Preview: サムネイル・表示ともに正しく白飛び ✓

**将来の改善候補**: DNG に書き込む埋め込みプレビューにも normalize-wl を適用すれば
初期プレビューも正しくなる（`x3f_output_dng.c` のプレビュー書き込み部分を修正）。

### AsShotNeutral[B] = 1.5807 > 1.0

Foveon の物理特性。normalize-wl では変更しない（変更すると WB 乗数の比率が崩れ
全アプリでハイライトが黄色になる）。

## テスト用ファイル

- `/Users/ishida/github/X3F/DP2M0169.X3F` — DP2 Merrill テスト画像

```bash
# 変換
./x3f_extract -normalize-wl -dng -o /Users/ishida/github/X3F \
    /Users/ishida/github/X3F/DP2M0169.X3F

# メタデータ確認
exiftool /Users/ishida/github/X3F/DP2M0169.X3F.dng | \
    grep -E "White Level|Black Level|As Shot Neutral"
# 期待値: WL=16384 16384 16384, BL=0 0 0, ASN=0.3626 0.8731 1.5807
```

## 試行して失敗したアプローチ（再実装しないこと）

### float DNG (`-float-dng`)
Capture One が 32bit float DNG を認識しなかったため廃止。

### K_scale (ASN × 1/max(ASN)、ピクセル × K_scale)
ASN[B]=1.5807 を 1.0 に正規化する意図だったが、R・G の WB 乗数が増大し
全アプリでハイライトが黄色になった。廃止。
