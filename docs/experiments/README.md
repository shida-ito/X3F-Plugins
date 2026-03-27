# Experiments

## 2026-03-27 DP2 Merrill Green Cast

- 対象: DP2 Merrill の X3F を DNG に変換した際の Lightroom 上の全体的な緑/シアンかぶり
- 状態: 保留

### 試した内容

- `WhiteBalanceColorCorrections` の解釈変更
- TIFF/プレビュー系の色変換補正
- DNG 側の `ColorMatrix1` / `ForwardMatrix1` / `CameraCalibration1` の調整
- DNG 3ch 線形データへのモデル別補正焼き込み

### 結果

- TIFF/プレビュー系では一定の改善が見えた。
- ただし Lightroom 上の DNG 表示は、行列系や小さな線形補正だけでは SPP に十分近づかなかった。
- 次段階は `ColorChecker Digital SG` を使ったプロファイル作成ワークフローに切り替える。

### 補足

- 実験コード自体は保持していない。
- 比較用の入力と出力は `X3F_Sample/` に残してある。
