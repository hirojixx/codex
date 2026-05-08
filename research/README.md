# research ディレクトリ運用ガイド

## 目的
このディレクトリは、プログラミング調査を「収集 → 正規化 → 検証 → 参照資産化」するための中核です。

## 使い方（最短）
1. 作業前に `./scripts/preplan.sh` を実行し、計画を記録。
2. 調査メモを `00_inbox` に追加。
3. テンプレートを用いて `01_active` に昇格。
4. 検証済みになったら `02_reference` へ移動。
5. 旧版は `03_archive` で履歴保持。
6. 担当ステージのインデックスだけを `./scripts/reindex.sh <stage>` で更新する。
7. ファイル編集後は `./scripts/self_review.sh` を実行し、自己レビュー記録を残す。

## KPI 例
- Inbox滞留日数: 2日以内
- `review_due` 超過ノート: 0件
- 重複ノート件数: 月次で減少
- プランニング未実施の変更: 0件
- 自己レビュー未実施の変更: 0件

## インデックス更新ルール
- 通常作業では `research/_meta/index.md` を直接編集しません。このファイルはCIや最終統合時だけ `./scripts/reindex_all.sh` で再生成する集約インデックスです。
- 日常更新では `research/_meta/index/` 配下のステージ別シャードを更新します。例: inbox担当は `./scripts/reindex.sh 00_inbox`、active担当は `./scripts/reindex.sh 01_active`。
- 4並列作業時は、原則として担当ステージまたは担当テーマのシャードだけを更新し、他担当のシャードと集約インデックスには触れません。
- 複数ステージをまたぐ移動をした場合だけ、移動元と移動先のシャードを明示して再生成します。例: `./scripts/reindex.sh 00_inbox 01_active`。
