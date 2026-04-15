# DB設計上の考慮項目・ER図形式・DDD/イベントソーシング観点まとめ（日本語）

- date: 2026-04-14
- domain: architecture
- language: sql
- status: active
- reliability: partially-verified
- review_due: 2026-05-14

## 1. 調査質問
- DB設計時に考慮すべき項目を、ER図表現・データ構造・制約・正規化・DDD・イベントソーシング・実装容易性まで含めて体系化できるか。
- すべての項目について、前提・解説・必要に応じたサンプル・起こりうる問題と深刻度を明示できるか。

## 2. 結論（先に短く）
- 実務DB設計は「整合性」「柔軟性」「性能」「実装容易性」の4軸最適化。
- 基本方針は 3NF中心 + 計測根拠付きの限定的非正規化。
- 境界内は制約で強く守り、境界間は契約とイベントで整合を設計する。

## 3. 根拠
- PostgreSQL docs（constraints/view/range）
  - https://www.postgresql.org/docs/current/ddl-constraints.html
  - https://www.postgresql.org/docs/current/sql-createview.html
  - https://www.postgresql.org/docs/current/rangetypes.html
- MySQL FK docs
  - https://dev.mysql.com/doc/mysql/8.0/en/create-table-foreign-keys.html
- SQL Server temporal tables
  - https://learn.microsoft.com/en-us/sql/relational-databases/tables/temporal-tables
- Microsoft Architecture（Event Sourcing / CQRS / DDD）
  - https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing
  - https://learn.microsoft.com/en-us/azure/architecture/patterns/cqrs
  - https://learn.microsoft.com/en-us/azure/architecture/microservices/model/domain-analysis
- Fowler（Bounded Context / Event Sourcing）
  - https://martinfowler.com/bliki/BoundedContext.html
  - https://www.martinfowler.com/eaaDev/EventSourcing.html
- IBM normalization
  - https://www.ibm.com/think/topics/database-normalization

## 4. 実務設計チェックリスト（66項目、全項目に前提/解説/問題/深刻度）

> 深刻度: 致命 / 高 / 中 / 低

### A. モデリング・境界設計
1. ユビキタス言語を固定する
- 前提: 部門間で同義語・多義語がある。
- 解説: 用語の不一致はER分割ミスを誘発する。
- サンプル: 用語集を先に作成し、テーブル名と列名に反映。
- 問題/深刻度: 同義語乱立で重複テーブルが発生（中）。

2. 集約単位で整合境界を定義する
- 前提: 同時更新が頻発する。
- 解説: 1トランザクションで守る範囲を限定。
- サンプル: Order + OrderLine は同一集約。
- 問題/深刻度: 複数集約横断更新で不整合（高）。

3. Bounded Contextを先に切る
- 前提: 同じ顧客概念が業務ごとに異なる。
- 解説: 巨大単一モデルを避ける。
- サンプル: SalesCustomer と SupportCustomer を分離。
- 問題/深刻度: 変更が全体に波及し開発停止（高）。

4. Context間はAPI/イベント契約で連携
- 前提: マイクロサービス構成。
- 解説: サービス間FKを避け、疎結合にする。
- サンプル: customer_registered イベントを配信。
- 問題/深刻度: 直結依存で同時リリース必須化（高）。

5. 同期整合が必要なもののみ同一境界
- 前提: 性能と一貫性の両立が必要。
- 解説: なんでも同期整合にしない。
- サンプル: 在庫は同期、レコメンドは非同期。
- 問題/深刻度: 過剰同期で性能劣化（中）。

6. マスタ/トランザクション/履歴/監査を分離
- 前提: 要件が混在するシステム。
- 解説: ライフサイクル単位で表を分ける。
- サンプル: orders と order_events を分離。
- 問題/深刻度: 単一表肥大化で運用困難（中）。

7. 監査要件を初期要件化
- 前提: 追跡責任がある業務。
- 解説: 後付け監査は欠損が出る。
- サンプル: created_by / updated_by / audit_log。
- 問題/深刻度: 原因追跡不能（高）。

8. 削除方針を先に決める
- 前提: 個人情報・法令保持あり。
- 解説: 物理/論理/匿名化を使い分け。
- サンプル: deleted_at + バックグラウンド物理削除。
- 問題/深刻度: 規制違反や復旧不能（致命）。

9. 利用者別（OLTP/分析/監査）にモデル分離
- 前提: 参照用途が多様。
- 解説: 1モデルで全部賄わない。
- サンプル: OLTP DB + DWH。
- 問題/深刻度: 本番負荷過多で性能事故（高）。

10. 変更容易属性の拡張点を明示
- 前提: 仕様変更が多い領域。
- 解説: 先に拡張戦略を決める。
- サンプル: profile_json を限定用途で導入。
- 問題/深刻度: 頻繁なDDLで障害誘発（中）。

### B. ER図形式とデータ構造
11. Crow's Footを業務説明に使う
- 前提: 非エンジニア共有が必要。
- 解説: 多重度が直感的。
- サンプル: 顧客1:N注文。
- 問題/深刻度: 多重度誤解で実装齟齬（中）。

12. Chen記法を概念整理に使う
- 前提: 初期要件定義段階。
- 解説: 属性・関係の意味整理に向く。
- サンプル: エンティティ関係の概念図。
- 問題/深刻度: 物理設計への落とし漏れ（低）。

13. IDEF1Xをキー厳密設計に使う
- 前提: 識別関係が複雑。
- 解説: 主キー継承関係を明確化できる。
- サンプル: 識別子依存子表の定義。
- 問題/深刻度: キー設計の曖昧化（中）。

14. UMLをドメインモデル連携に使う
- 前提: アプリ設計と同期したい。
- 解説: クラス/関連で実装接続しやすい。
- サンプル: Entity/ValueObject 併記。
- 問題/深刻度: DB観点不足で制約漏れ（中）。

15. 概念→論理→物理の3層分離
- 前提: 中長期開発。
- 解説: 変更を局所化できる。
- サンプル: 3種類のER成果物を管理。
- 問題/深刻度: 変更時に全図改修が必要（中）。

16. 物理ERにPK/FK/UK/Indexを明示
- 前提: 実装前レビューをする。
- 解説: DDL差分検出が容易。
- サンプル: ERにインデックス凡例を追加。
- 問題/深刻度: 性能/整合事故の見落とし（高）。

17. N:Nを関連実体化する
- 前提: 多対多関係。
- 解説: 直結不可、必ず中間表。
- サンプル: user_roles。
- 問題/深刻度: 重複・削除不整合（高）。

18. 関連に属性があれば中間表へ
- 前提: 関係自体に意味がある。
- 解説: 関連を1級モデルとして扱う。
- サンプル: assigned_at, priority を中間表に保持。
- 問題/深刻度: 属性の置き場不明で欠損（中）。

19. 期間を持つ関係は有効期間列を持つ
- 前提: 契約/価格に有効期間がある。
- 解説: 時点参照を可能にする。
- サンプル: valid_from, valid_to。
- 問題/深刻度: 過去再現不能（高）。

20. 多態関連は意図を明示
- 前提: 複数親型へ関連。
- 解説: 型列+整合検証を設計。
- サンプル: owner_type + owner_id。
- 問題/深刻度: 孤児データ大量発生（中）。

### C. 制約方針
21. NOT NULLを基本ON
- 前提: 必須属性がある。
- 解説: 欠損をDBで阻止。
- サンプル: email TEXT NOT NULL。
- 問題/深刻度: 欠損で表示/通知不能（高）。

22. UNIQUEで業務キー重複防止
- 前提: 一意性が必要。
- 解説: 重複登録はアプリだけで防ぎきれない。
- サンプル: UNIQUE(email)。
- 問題/深刻度: 二重課金・本人同定失敗（致命）。

23. FKで参照整合を担保
- 前提: 親子関係がある。
- 解説: 孤児レコードを防止。
- サンプル: order.user_id REFERENCES users(id)。
- 問題/深刻度: 集計不一致・削除不整合（高）。

24. CHECKで値域制限
- 前提: 取り得る値が限定される。
- 解説: 異常値の流入を防ぐ。
- サンプル: CHECK (amount >= 0)。
- 問題/深刻度: 下流処理崩壊（中〜高）。

25. DEFERRABLEを相互参照更新で活用
- 前提: 一括更新で一時不整合が出る。
- 解説: commit時評価に遅延可能。
- サンプル: DEFERRABLE INITIALLY DEFERRED。
- 問題/深刻度: 更新手順複雑化（中）。

26. 高競合ではversion列追加
- 前提: 同一行を多者更新。
- 解説: ロストアップデートを検出。
- サンプル: WHERE id=? AND version=?。
- 問題/深刻度: 上書き事故（高）。

27. 境界内は強制約、境界外は契約整合
- 前提: サービス境界がある。
- 解説: FKは境界内のみ強く使う。
- サンプル: outboxイベントで連携。
- 問題/深刻度: クロス境界障害連鎖（高）。

28. FKを外すなら非同期整合チェック必須
- 前提: 高スループットログ等。
- 解説: 代替統制を実装。
- サンプル: nightly orphan checker。
- 問題/深刻度: 静かにデータ崩壊（高）。

29. 例外運用Runbookを用意
- 前提: 手修正が発生し得る。
- 解説: 復旧手順を標準化。
- サンプル: 補正SQL + 監査記録。
- 問題/深刻度: 復旧作業の属人化（中）。

30. 崩すのは計測根拠がある箇所のみ
- 前提: 最適化要求がある。
- 解説: 体感で制約を外さない。
- サンプル: p95遅延を根拠に判断。
- 問題/深刻度: 不要な複雑化（中）。

### D. View / Materialized View
31. Viewで参照契約固定
- 前提: 基表変更が多い。
- 解説: 参照側互換を維持。
- サンプル: v_active_users。
- 問題/深刻度: 参照破壊的変更（中）。

32. 権限制御をView経由で簡素化
- 前提: 列単位秘匿が必要。
- 解説: 生テーブルへの直接権限を絞る。
- サンプル: mask済みView配布。
- 問題/深刻度: 情報漏えい（高）。

33. 更新系は原則ベーステーブル
- 前提: 複雑View。
- 解説: 更新可能条件が限定される。
- サンプル: write APIはテーブル直書き。
- 問題/深刻度: 更新失敗・予期せぬ挙動（中）。

34. 集計にはMV検討
- 前提: 重い集計クエリがある。
- 解説: 前計算で参照高速化。
- サンプル: 日次売上MV。
- 問題/深刻度: 生データとの差異（中）。

35. MV更新タイミング明記
- 前提: freshness要件がある。
- 解説: SLAに合う更新頻度を設定。
- サンプル: 5分毎refresh。
- 問題/深刻度: 古いデータ参照（中）。

36. CQRS Read Model実装に利用
- 前提: 読み取り要件が多様。
- 解説: 書き込みモデルから分離。
- サンプル: read_model_orders。
- 問題/深刻度: 同期遅延による誤認（中）。

37. Viewを互換レイヤとして活用
- 前提: スキーマ移行中。
- 解説: 旧API互換を維持。
- サンプル: 旧列名をViewで提供。
- 問題/深刻度: 移行時の大規模障害（高）。

### E. 正規化と非正規化
38. 3NFを初期基準にする
- 前提: OLTP中心。
- 解説: 更新異常を減らす。
- サンプル: 参照マスタ分離。
- 問題/深刻度: 更新異常常態化（高）。

39. 1NF/2NF/3NFを段階確認
- 前提: 複合キーや繰返し属性あり。
- 解説: 手戻りを防ぐ。
- サンプル: 配列列を子表化。
- 問題/深刻度: 重複/矛盾データ蓄積（中）。

40. BCNFは中核領域で検討
- 前提: 高整合が必要。
- 解説: さらに従属関係を厳密化。
- サンプル: 複雑業務キーの分解。
- 問題/深刻度: 過剰分解で性能低下（中）。

41. 読み取り偏重では派生列を許可
- 前提: JOIN多段で遅い。
- 解説: 計測根拠付き非正規化。
- サンプル: total_amountキャッシュ列。
- 問題/深刻度: 更新漏れによる不一致（高）。

42. 非正規化責務を1箇所に固定
- 前提: 複数更新経路がある。
- 解説: 同期元を単一化。
- サンプル: DB trigger かイベント投影に統一。
- 問題/深刻度: 値の漂流（高）。

43. 再計算ジョブを用意
- 前提: 非正規化あり。
- 解説: 破損時に再構築可能にする。
- サンプル: nightly rebuild job。
- 問題/深刻度: 永続不一致（中）。

44. 正規化度は件数/JOIN/SLAで決定
- 前提: 要件が定量化可能。
- 解説: 感覚設計を避ける。
- サンプル: p95<100ms達成で判断。
- 問題/深刻度: 不適切設計固定化（中）。

### F. N:N / 1:1 / 排他
45. N:N中間表に一意制約
- 前提: 関係重複を防ぎたい。
- 解説: 同じ組み合わせ重複を禁止。
- サンプル: UNIQUE(user_id, role_id)。
- 問題/深刻度: 二重権限付与（高）。

46. 中間表属性の主語を定義
- 前提: 付帯属性あり。
- 解説: 何に属する属性か明確化。
- サンプル: assigned_atは関係の属性。
- 問題/深刻度: 更新責務不明（中）。

47. 1:1は限定用途
- 前提: 機密分離/疎属性分離。
- 解説: 無闇な分割は避ける。
- サンプル: user_profiles分離。
- 問題/深刻度: JOIN増加で性能悪化（中）。

48. 1:1はFK+UNIQUEかShared PK
- 前提: 厳密1:1保証が必要。
- 解説: アプリ保証のみは脆弱。
- サンプル: user_id PRIMARY KEY REFERENCES users。
- 問題/深刻度: 多重レコード混入（高）。

49. ロック順序を統一
- 前提: 複数表更新あり。
- 解説: デッドロック予防。
- サンプル: users→orders固定順。
- 問題/深刻度: 瞬断/リトライ嵐（高）。

50. トランザクション短時間化
- 前提: 高負荷環境。
- 解説: ロック保持時間を短縮。
- サンプル: 外部API呼出をTx外へ。
- 問題/深刻度: スループット低下（中）。

### G. 状態分岐
51. 原則は単一表+state列
- 前提: 列構造がほぼ同じ。
- 解説: 実装単純性が高い。
- サンプル: users.state。
- 問題/深刻度: 状態ごとの条件漏れ（中）。

52. 列差が大きい時のみ分割
- 前提: 状態で保持属性が激変。
- 解説: NULLだらけを回避。
- サンプル: applications_pending / approved。
- 問題/深刻度: 遷移時データ移送ミス（高）。

53. 状態遷移ログを別表保持
- 前提: 監査要件あり。
- 解説: 現在値と履歴を分離。
- サンプル: user_state_transitions。
- 問題/深刻度: 変更経緯消失（高）。

54. 承認WFは現在値+履歴分離
- 前提: 多段承認。
- 解説: 誰がどの判断をしたか保持。
- サンプル: approvals + approval_events。
- 問題/深刻度: 内部統制不備（高）。

55. セッション状態は別管理
- 前提: ログイン/ログアウトの短期状態。
- 解説: ユーザマスタに混在させない。
- サンプル: sessionsテーブル。
- 問題/深刻度: 清掃漏れで肥大化（中）。

56. Hot/Cold分離を判断材料にする
- 前提: アクセス偏りが強い。
- 解説: 頻繁アクセスのみホットに残す。
- サンプル: active_users / archived_users。
- 問題/深刻度: 誤分離で検索漏れ（中）。

### H. バージョン/スナップショット/期間
57. version列で楽観ロック
- 前提: 同時編集可能性あり。
- 解説: 更新競合を検出。
- サンプル: version +1 更新。
- 問題/深刻度: ロストアップデート（高）。

58. append-only履歴を検討
- 前提: 監査厳格。
- 解説: 改ざん耐性を高める。
- サンプル: updateせず新規insert。
- 問題/深刻度: 追跡不能（高）。

59. スナップショットで再生短縮
- 前提: イベント件数増大。
- 解説: 途中状態を保存。
- サンプル: 100イベントごとsnapshot。
- 問題/深刻度: 復元遅延（中）。

60. 間隔はRTOから逆算
- 前提: 復旧目標が定義済み。
- 解説: 保存コストと復元時間を最適化。
- サンプル: RTO5分なら間隔短縮。
- 問題/深刻度: 目標未達（高）。

61. 期間は半開区間を採用
- 前提: 連続期間管理。
- 解説: 境界重複を避けやすい。
- サンプル: [2026-01-01, 2026-02-01)。
- 問題/深刻度: 二重適用/欠落（高）。

62. 期間重複禁止を実装
- 前提: 同一対象で排他的期間。
- 解説: ルールをDBで強制。
- サンプル: exclusion相当制約。
- 問題/深刻度: 価格矛盾適用（高）。

63. bitemporalを検討
- 前提: 業務時点と登録時点が異なる。
- 解説: 過去訂正にも対応。
- サンプル: valid_time + system_time。
- 問題/深刻度: 監査矛盾（中〜高）。

64. As-of参照要件を明示
- 前提: 「当時の値」参照が必要。
- 解説: 後付け困難。
- サンプル: AS OF timestamp query。
- 問題/深刻度: 再現不能（高）。

### I. DDD / Event Sourcing導入判断
65. CRUDで足りるなら通常RDB優先
- 前提: 監査要件が中程度。
- 解説: 複雑性を抑える。
- サンプル: 単純トランザクション設計。
- 問題/深刻度: 過剰設計で開発遅延（中）。

66. 監査/再計算重視ならEvent Sourcing
- 前提: 事実履歴が価値を持つ。
- 解説: イベントを真実源にし、Read Modelで参照最適化。
- サンプル: events + projections。
- 問題/深刻度: 導入時の運用複雑化（中）、未導入時の追跡不能（高）。

## 5. 最小サンプルDDL（抜粋）

```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  state TEXT NOT NULL,
  version BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE roles (
  id BIGINT PRIMARY KEY,
  code TEXT NOT NULL UNIQUE
);

CREATE TABLE user_roles (
  user_id BIGINT NOT NULL REFERENCES users(id),
  role_id BIGINT NOT NULL REFERENCES roles(id),
  assigned_at TIMESTAMP NOT NULL,
  PRIMARY KEY (user_id, role_id)
);

CREATE TABLE user_profiles (
  user_id BIGINT PRIMARY KEY REFERENCES users(id),
  legal_name TEXT NOT NULL,
  birth_date DATE NOT NULL
);

CREATE TABLE user_state_transitions (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  from_state TEXT NOT NULL,
  to_state TEXT NOT NULL,
  changed_at TIMESTAMP NOT NULL,
  changed_by TEXT NOT NULL
);

CREATE TABLE subscription_terms (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  valid_from TIMESTAMP NOT NULL,
  valid_to TIMESTAMP NOT NULL,
  CHECK (valid_from < valid_to)
);
```

## 6. 実装順序（再掲）
1. 境界定義（DDD）
2. 3NF論理設計
3. 制約実装
4. 排他設計
5. 履歴/期間
6. 性能計測後の非正規化
7. 必要時CQRS/Event Sourcing

## 7. 制約・未解決
- ベンダー差により、同じ設計意図でもDDL実装が異なる。
- 深刻度は業務影響（法令/金銭/顧客影響）で最終判断が必要。

## 8. 次アクション
- 66項目それぞれについて、PostgreSQL/MySQL/SQL ServerのDDL差分サンプルを追加。
- Event Sourcingのスキーマ進化（versioning）設計を具体化。

## 9. 変更履歴
- 2026-04-14: 初版
- 2026-04-14: 項目ごとの前提/解説/サンプル、制約欠如時の問題・深刻度を追加
- 2026-04-14: 全66項目に問題と深刻度を付与し再編集

## 10. 教育用ケーススタディ（別ファイル）
- バイク製造管理/BOMの教育用ケーススタディは次の専用ノートへ分離。
- `research/01_active/2026-04-14__bike-bom-db-design-case-study-ja.md`

## 11. 変更履歴（追記）
- 2026-04-14: 教育用ケーススタディを別ファイルへ分離
