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
- planning/self-review の記録先を単一ログからタスク別ログディレクトリへ変更。
- 旧 `planning-log.md` / `self-review-log.md` を `research/logs/archive/` に移動して過去ログとして保持。
- `codex.md` と関連テンプレート/README のログ運用説明をタスク別ログに更新。
- conflict resolution として、ステージ別インデックス運用とタスク別ログ運用を同時に維持する形へ統合。
- master 取り込み時の衝突を、ステージ別インデックス運用とハッシュ付きタスク別ログ運用を両立する形で解消。

## 2026-05-08 - task log review fixes
- `preplan.sh` / `self_review.sh` の slug 生成で ASCII 化後に空になるタスク名へ安定ハッシュ付き fallback を追加し、日本語タスク名同士の同日衝突を防止。
- `preplan.sh` / `self_review.sh` の slug 生成で全タスク名に安定ハッシュ suffix を追加し、`foo/bar` と `foo bar` のような非空 slug 衝突を防止。
- `self_review.sh` は `<task_title>` を必須化し、当日最新 planning ログへの暗黙 fallback を廃止して誤ったタスクへのレビュー紐付きを防止。
- `reindex.sh` から Bash 4 専用の associative array を除去し、macOS 標準 Bash 3.2 互換の `case` に変更。
- ドキュメント、テンプレート、mandatory skill、maintainer skill の self-review 手順を `<task_title>` 必須の運用へ更新。
