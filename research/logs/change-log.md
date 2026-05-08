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
- `scripts/check_review_due.sh` を追加し、active/reference/archive/inbox 形式の research ノートに対する `review_due` 欠落・期限切れ・7日以内警告を検査できるようにした。
- `scripts/self_review.sh` から review_due 検査を呼び出し、自己レビュー記録に警告内容を残すようにした。
- `research/01_active/2026-04-14__vscode-architecture-patterns.md` の先頭メタデータをテンプレート形式へ正規化した。
