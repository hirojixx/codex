# バックエンドAPI信頼性プレイブック（再構成版 / Web調査反映）

この資料は、詳細チェックリスト（`backend-api-100-checklist-ja.md`）を**人間が運用で使いやすい形**に再構成したものです。  
まずはこのプレイブックで全体を掴み、詳細項目は原本（1〜258）を参照してください。

---

## 0. 使い方（3ステップ）
1. **初回導入**: 「1. 最優先30項目（P0）」だけを実装する。  
2. **安定化**: 「2. 障害パターン別チェック」で自分のシステムの弱点を埋める。  
3. **継続運用**: 「3. 障害発生時のデバッグ導線」をRunbook化し、四半期ごとに演習する。

---

## 1. 最優先30項目（P0）

> ここだけ先にやれば、重大障害の発生率と復旧時間を大きく下げやすい。

### A. 設計・契約
- 境界づけられたコンテキスト、集約境界、トランザクション境界を一致させる。
- APIエラーを標準化（`code`, `message`, `traceId` + Problem Details）。
- 互換性ルールを定義（破壊的変更禁止、deprecation期間）。
- ページネーションはcursorを優先し、安定ソートキーを固定。
- 時刻はUTC保存・表示時変換で統一。

### B. セキュリティ
- BOLA/BFLA（オブジェクト・機能レベル認可）を全APIで検証。
- JWTの`aud/iss/exp`検証、`alg`固定、鍵ローテーション手順。
- SSRF対策（送信先allowlist、内部メタデータ遮断）。
- レート制限 + 429/Retry-After + ブルートフォース対策。
- 秘密情報のログ流出防止（mask/redaction）。

### C. データ整合性
- 更新APIに冪等キー（Idempotency-Key）導入。
- 楽観ロック（version）で競合更新を検知。
- 一意制約違反・デッドロック時の再試行ポリシー。
- Outbox/Sagaで「DB更新と外部連携」の不整合を防止。
- マイグレーションはExpand/Contractで無停止化。

### D. Node.js運用安全性
- CPUバウンド処理をWorker Threads/別プロセスへ分離。
- `stream.pipeline()`を使ってbackpressureとエラー伝播を担保。
- `AbortController`で切断/タイムアウト時に処理を止める。
- `headersTimeout/requestTimeout/keepAliveTimeout`を明示設定。
- graceful shutdown（SIGTERM→新規受付停止→完了待機）を実装。

### E. 可観測性・障害対応
- ログ・メトリクス・トレースを`trace_id`で相互参照可能にする。
- RED指標（Rate/Errors/Duration）とSLO（p95/エラーレート）を定義。
- 依存先（DB, Redis, 外部API）のタイムアウト率を監視。
- Feature Flagで緊急遮断できるようにする。
- ポストモーテムの再発防止策に期限と責任者を付与。

---

## 2. 障害パターン別チェック（原因→検知→初動）

| 障害パターン | 典型原因 | まず見るメトリクス/ログ | 初動アクション |
|---|---|---|---|
| レイテンシ急増 | イベントループ詰まり、外部API遅延、DBロック | p95/p99, event loop lag, downstream timeout | 依存先timeout短縮、重処理遮断、レート制限強化 |
| 5xx急増 | リトライ暴走、設定ミス、接続枯渇 | 5xx率, retry回数, pool使用率 | リリース差し戻し、circuit open、上限QPS制御 |
| 二重処理/重複課金 | 冪等性欠落、再送・再試行競合 | 同一request key重複、DB重複レコード | 冪等キー導入、重複排除ジョブ、補償処理 |
| データ不整合 | Tx境界不一致、イベント重複・順序逆転 | outbox遅延, DLQ件数, version競合 | 書込停止→整合性検査→再処理手順実行 |
| OOM/再起動ループ | メモリリーク、大量レスポンス全展開 | RSS, heap usage, GC pause | 一時縮退、heap snapshot採取、リーク箇所隔離 |
| 認可事故 | BOLA/BFLA漏れ、ロール設定不整合 | 認可失敗ログ、監査ログ差分 | 該当API遮断、監査、キー/トークン再発行 |
| デプロイ直後障害 | 破壊的変更、移行順序ミス | デプロイ相関、migration失敗率 | 即時ロールバック、互換モード復帰 |

---

## 3. 障害発生時のデバッグ導線（60分版）

### 0〜10分: 影響封じ込め
- 影響範囲（ユーザー、テナント、主要API）を把握。
- Feature Flag / レート制限 / 一時的ReadOnly化で被害拡大を止める。

### 10〜30分: 原因領域の特定
- 直前変更（デプロイ、設定、依存先変更）を時系列で確認。
- 依存先エラー率、タイムアウト率、キュー滞留、DBロックを比較。
- trace_idで失敗リクエストを横断追跡。

### 30〜60分: 復旧と恒久対策の準備
- 最小変更で復旧（ロールバック、機能縮退、再処理停止）。
- 復旧後に再処理計画（順序・重複排除・監査証跡）を作成。
- 事後レビューの仮説（技術原因/運用原因）を記録。

---

## 4. 役割別の担当境界（抜け漏れ防止）

- **アーキテクト**: コンテキスト境界、整合性モデル、互換性ポリシー。
- **API実装者**: バリデーション、認可、冪等性、タイムアウト、リトライ。
- **SRE/Platform**: SLO、監視、アラート、デプロイ戦略、K8s健全性。
- **Security**: 脅威モデリング、秘密情報管理、監査証跡、脆弱性対応。
- **オンコール**: 初動Runbook、連絡体制、復旧判断、ポストモーテム運用。

---

## 5. 参照標準（どの設計判断に効くか）

| 領域 | まず見る一次情報 | この資料での使いどころ |
|---|---|---|
| HTTP意味論/ステータス | RFC 9110 | メソッド意味、条件付き更新、エラー設計 |
| エラー形式標準 | RFC 9457 | Problem Detailsでエラー統一 |
| レート制御 | RFC 9333 | RateLimitヘッダ運用方針 |
| JWT安全運用 | RFC 8725 | alg固定、claim検証、鍵運用 |
| OAuth強化 | RFC 8705 / RFC 9449 | mTLS/DPoPによるトークン悪用耐性 |
| API脆弱性分類 | OWASP API Top 10 (2023) | BOLA/BFLA/SSRFなどの優先監査 |
| 可観測性標準 | OpenTelemetry SemConv | 属性命名統一、相関分析 |
| Node障害解析 | Node.js Diagnostic Report | 本番障害時の証跡採取 |
| K8s健全性設計 | K8s probes docs | readiness/liveness/startup分離 |
| インシデント運用 | NIST SP 800-61r3 / Google SRE | 体制設計、訓練、再発防止 |

---

## 6. 詳細チェックリストへの導線
- フル項目（1〜258）: `docs/backend-api-100-checklist-ja.md`
- まず確認すべき範囲:
  - 設計段階: 1〜30, 151〜174
  - 実装段階: 31〜100, 175〜234
  - 運用/障害対応: 91〜100, 199〜246

---

## 7. Web調査参照先（一次情報）
- OWASP API Security Top 10 2023: https://owasp.org/API-Security/editions/2023/en/0x11-t10/
- RFC 9110 HTTP Semantics: https://datatracker.ietf.org/doc/html/rfc9110
- RFC 9457 Problem Details: https://www.ietf.org/rfc/rfc9457.html
- RFC 9333 RateLimit Headers: https://www.rfc-editor.org/rfc/rfc9333
- RFC 8725 JWT BCP: https://datatracker.ietf.org/doc/html/rfc8725
- RFC 8705 OAuth mTLS: https://datatracker.ietf.org/doc/html/rfc8705
- RFC 9449 DPoP: https://www.rfc-editor.org/rfc/rfc9449
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- OpenTelemetry HTTP SemConv: https://opentelemetry.io/docs/specs/semconv/http/http-spans/
- Node.js Diagnostic Report: https://nodejs.org/api/report.html
- Kubernetes Probes: https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- NIST SP 800-61r3: https://csrc.nist.gov/pubs/sp/800/61/r3/final
- Google SRE Incident Response: https://sre.google/workbook/incident-response/
