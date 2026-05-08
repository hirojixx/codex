# Change Log

## 2026-04-14
- 初期フォルダ構成を作成。
- `codex.md` を追加し、調査運用原則と実行手順を定義。
- タクソノミー、更新ポリシー、ノートテンプレートを作成。
- 自己レビュープロセスを `codex.md` に追加。
- `scripts/self_review.sh` と自己レビュー用テンプレートを追加。
- 作業前プランニングを必須化し、`scripts/preplan.sh` と planning ログ運用を追加。
- self-review で当日 planning-log の存在確認を行うゲートを追加。

## 2026-05-08
- `00_inbox`、`02_reference`、`03_archive` をGit管理対象として追加。
- `research/README.md` の使い方に各ステージへ入れるファイル例を追記。
- `research/_meta/index.md` をCI・最終統合向けの集約インデックスとして扱う方針を追加。
- `research/_meta/index/` にステージ別インデックスシャードを追加。
- `scripts/reindex.sh` をステージ別シャード更新に変更し、集約再生成用に `scripts/reindex_all.sh` を追加。
- 4並列作業時は担当ステージまたは担当テーマのシャードだけを更新する運用を明記。
