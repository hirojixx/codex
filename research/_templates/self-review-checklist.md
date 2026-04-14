# Self Review Checklist

- date: {YYYY-MM-DD}
- reviewer: {name}
- scope: {changed-files or feature}

## 0. Pre-Planning
- [ ] `./scripts/preplan.sh` を実行したか
- [ ] planning_prompt（目的・成功条件・制約）を記録したか
- [ ] 事前検索クエリを2件以上記録したか

## 1. Structure
- [ ] 変更ファイルは運用規約に沿った配置か
- [ ] 命名規則（`YYYY-MM-DD__topic-slug.md`）に違反していないか

## 2. Content Quality
- [ ] 結論が1〜3行で明確か
- [ ] 根拠（source）が2件以上あるか
- [ ] 制約・未解決が明示されているか
- [ ] 次アクションが実行可能な粒度か

## 3. Freshness & Consistency
- [ ] `review_due` が妥当な期限か
- [ ] taxonomy / update-policy と矛盾がないか
- [ ] 重複ノートの統合判断を行ったか

## 4. Verification
- [ ] `./scripts/reindex.sh` 実行
- [ ] `./scripts/self_review.sh` 実行
- [ ] 差分を目視確認し、不要ファイルが含まれていない

## 5. Decision
- [ ] Approve (all checks passed)
- [ ] Request changes (list issues)
