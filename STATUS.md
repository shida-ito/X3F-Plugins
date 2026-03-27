# STATUS

更新日: 2026-03-27

## 現在の状態

- 作業ツリーの tracked ファイルは `HEAD` に戻っている。
- 緑かぶり調査で使ったサンプル入力と比較出力は `X3F_Sample/` に残してある。
- 実験コードは保持していない。再開時は安定版コードから始める。

## 目的

- Merrill の X3F を DNG に変換した際に Lightroom で出る全体的な緑/シアンかぶりを減らす。
- 同一シーンで Sigma Photo Pro により近い見た目にする。

## 試したこと

- 空間ゲインを切って、問題が周辺色かぶり主体かどうかを確認した。
- Merrill/TRUE の `WhiteBalanceColorCorrections` の解釈変更を試した。
- TIFF/プレビュー系の色変換補正を試した。
- DNG 側で `ForwardMatrix1` の調整を試した。
- DNG 側で `CameraCalibration1` の微調整を試した。
- DNG 側で `ColorMatrix1` と `ForwardMatrix1` の役割分離を試した。
- DNG 線形データへのモデル別補正焼き込みを試した。

## 分かったこと

- Lightroom の緑かぶりは周辺だけではなく画面全体に出る。
- 空間ゲインを切ると少し改善するが、Sigma Photo Pro には近づかない。
- TIFF/PNG 系はある程度改善できたので、問題は DNG メタデータだけではない。
- ただし DNG 側の調整だけでは Lightroom 上の見た目を十分には寄せられなかった。
- `CameraCalibration1` の調整は Lightroom 出力ではほぼ効かなかった。
- 強めの DNG プロファイル変更は Lightroom 非対応を起こし得る。
- 単純な行列調整だけで解決する問題ではない可能性が高い。

## 現時点の結論

- Merrill の Lightroom 問題は `ColorMatrix`、`ForwardMatrix`、`CameraCalibration`、小さな線形補正だけで解く方針をやめる。
- 次の有力な手段は、チャート撮影から作るカメラプロファイル化である。
- `ColorChecker Digital SG` を使った非線形補正込みのプロファイル設計が次の段階になる。

## 再開地点

- `ColorChecker Digital SG` の到着待ち。
- `X3F_Sample/` を比較用ベースラインとして維持する。
- 実装再開は安定版コードから行う。

## 主要パス

- 比較サンプル: `X3F_Sample/`
- 調査対象コード: `x3f_source/src/x3f_process.c`
- 調査対象コード: `x3f_source/src/x3f_output_dng.c`
- 再開準備: `TODO_DigitalSG.md`
