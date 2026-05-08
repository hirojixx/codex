# Codex Research Operating System

## 0. 作業前プランニング（必須）
1. **Prompt定義**: 「目的・成功条件・制約」を1行ずつ明文化する。
2. **事前検索**: 最低2件の検索語を作成し、既存ノート/外部ソースの確認対象を決める。
3. **計画記録**: `./scripts/preplan.sh <task_title> <query1> <query2> ...` を実行して、タスク別ログ `research/logs/planning/YYYY-MM-DD__<task-slug>.md` に記録する。
4. **実装開始条件**: 当日のタスク別 planning ログへの記録完了後にのみ編集を開始する。

## 1. 目的
- 主にプログラミング関連の調査を、**再利用可能な知識資産**として蓄積する。
- 「古い情報を放置しない」ことを最優先にし、**定期的な最新化・再分類・重複統合**を運用の標準にする。

## 2. 最重要原則
1. **Capture first**: まず `research/00_inbox` に素早く保存する。
2. **Standardize fast**: 24時間以内にテンプレートへ正規化する。
3. **Review on schedule**: 期限ベースで最新化チェックを行う。
4. **One source of truth**: 同じ主張は1ノートへ集約し、リンクで再利用する。
5. **Archive aggressively**: 古いノートは消さず `03_archive` へ移動して履歴管理する。

## 3. フォルダ規約
- `research/00_inbox`: 未整理メモ・URL・断片ログ。
- `research/01_active`: 現在調査中のテーマ。
- `research/02_reference`: 検証済みの定常知識。
- `research/03_archive`: 廃止・旧版・履歴保持。
- `research/_meta`: タクソノミー・運用ルール・レビュー設定。
- `research/_meta/index/`: ステージ別インデックスのシャード。担当ステージのファイルだけを更新する。
- `research/_templates`: 調査ノートのテンプレート。
- `research/logs`: 更新履歴・再整理記録・プランニング記録・自己レビュー記録。
- `research/logs/planning`: タスク別の作業前プランニングログ（`YYYY-MM-DD__<task-slug>.md`）。
- `research/logs/self-review`: タスク別の自己レビューログ（`YYYY-MM-DD__<task-slug>.md`）。
- `research/logs/archive`: 旧形式の単一ログなど、履歴保持用の過去ログ。

## 4. 命名規則
- ノート名: `YYYY-MM-DD__topic-slug.md`
- 例: `2026-04-14__python-asyncio-timeout-patterns.md`
- タグは本文ヘッダで管理: `domain`, `language`, `status`, `review_due`

## 5. 運用サイクル
### Daily (毎日)
- Inbox triage（未整理の分類）
- 進行中ノートの最小1件更新

### Weekly (毎週)
- 重要ノートのリンク整備
- 重複ノート統合
- `review_due` 到来ノートを再検証

### Monthly (毎月)
- タクソノミー見直し
- アーカイブ移動
- 先月の調査成果サマリを作成

## 6. 最新化ポリシー
- 変更頻度が高い領域（ライブラリ、クラウド、CI/CD）は `review_due` を短く設定（7〜30日）。
- 安定領域（アルゴリズム、言語仕様）は長めに設定（90〜180日）。
- 検証時は「前回主張が今も正しいか」を必ず再判定し、結果を変更履歴に残す。

## 7. 実行手順（初期導入）
1. `research/_templates/research-note.md` を使って最初の3ノートを作成。
2. `research/_meta/taxonomy.md` のカテゴリに沿って分類。
3. `research/logs/change-log.md` に更新履歴を記録。
4. 通常作業では `scripts/reindex.sh <stage>` で担当ステージのインデックスシャードだけを再生成。
5. CIや最終統合時のみ `scripts/reindex_all.sh` で集約インデックス `research/_meta/index.md` を再生成。
6. 作業前に `scripts/preplan.sh` を実行し、ハッシュ付きタスク別 planning ログを作成。
7. ファイル編集後は必ず `scripts/self_review.sh <task_title>` を実行し、対応するハッシュ付きタスク別 self-review ログを作成。

## 8. インデックス運用
- `research/_meta/index.md` は手編集・頻繁更新対象から外し、CIや最終統合で再生成する集約インデックスとして扱う。
- 日常の調査・整理では `research/_meta/index/00_inbox.md`、`01_active.md`、`02_reference.md`、`03_archive.md` のうち担当ステージのシャードだけを更新する。
- 複数人または4並列作業では、担当ステージまたは担当テーマのシャードに変更範囲を限定し、集約インデックスの更新競合を避ける。

## 9. 品質ゲート
- 根拠のない断定をしない（必ず source を明記）。
- 「結論」「制約」「次アクション」が空欄のノートは `active` 扱いに戻す。
- `review_due` が過去日のノートを0件に維持する。

## 10. 自己レビュープロセス（必須）
1. **構成レビュー**: 追加/変更ファイルが規約ディレクトリに配置されているか確認。
2. **内容レビュー**: テンプレートの必須項目（結論・根拠・制約・次アクション）が欠落していないか確認。
3. **整合レビュー**: `taxonomy.md` / `update-policy.md` と矛盾がないか確認。
4. **自動チェック実行**: `scripts/self_review.sh <task_title>` を実行し、対応する当日の planning ログだけを確認して `research/logs/self-review/YYYY-MM-DD__<task-slug>.md` に結果を追記する。
5. **最終判定**: 問題が1つでも残る場合はコミットしない。
