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

## 現行の DNG 出力メタデータ (DP2M0169 例)

```
WhiteLevel   : 16383 6828 3790  ← per-channel (Foveon 物理値)
BlackLevel   : 40.99 40.99 40.99
AsShotNeutral: 0.3626 0.8731 1.5807
Compression  : JPEG (LJPEG)  ← -ljpeg 指定時
```

## テスト用ファイル

- `/Users/ishida/github/X3F/DP2M0169.X3F` — DP2 Merrill テスト画像

```bash
# 変換
/Users/ishida/github/X3F-Plugins/x3f_source/bin/osx-x86_64/x3f_extract \
    -ljpeg -dng -o /Users/ishida/github/X3F \
    /Users/ishida/github/X3F/DP2M0169.X3F

# メタデータ確認
exiftool /Users/ishida/github/X3F/DP2M0169.X3F.dng | \
    grep -E "White Level|Black Level|As Shot Neutral|Compression"
```

## 試行して失敗したアプローチ（再実装しないこと）

### float DNG (`-float-dng`)
Capture One が 32bit float DNG を認識しなかったため廃止。

### `-normalize-wl` フラグ（削除済み）

**目的**: Capture One が per-channel WhiteLevel を無視して WL[0]=16383 を全チャンネルに
適用するバグを回避するため、各チャンネルを `[black[c], white[c]] → [0, white[0]]` に正規化。

**廃止理由**:
1. **Capture One のハイライトが黄色のまま**: ASN_B=1.5807 > 1.0 のため B チャンネルが
   ハイライトで飽和し、normalize-wl 後も改善しなかった
2. **LJPEG との非互換**: 正規化後の最初のピクセルが 0 になると LJPEG の初期 predictor
   32768 との差分が -32768 = カテゴリ 16 になる。Lightroom/DNG SDK がカテゴリ 16 を
   デコードできないため画像全体が破綻する

**normalize-wl と組み合わせて試みた追加アプローチ（すべて失敗）**:
- **K_scale 単独（WL スケールなし）**: pixels × K だが WL そのまま → 全アプリ黄色
- **normalize-wl + K_scale（FM 更新なし）**: ASN × K のみ → Mac Preview が赤になった
- **normalize-wl + K_scale + FM×K**: FM 行和 = K×D50 → LR/C1 が FM を内部正規化すると
  補正が無効になり画像全体が 1.58× 明るく白飛び
