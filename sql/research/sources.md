# SQL / Oracle 26ai 調査ログ

調査日: 2026-06-02

方針: SQL標準はISO/IEC 9075:2023を基準に、Oracle前提はOracle AI Database 26ai（ドキュメントURL上は `/23/` パスだが26ai版として公開されているページを含む）を中心に確認。SQL構文、データ型、DDL/DML、制約、チューニング、オプティマイザ、初期化パラメータ、実行計画、ヒント、DB設計に観点を分散。

| # | 観点グループ | 出典/ページ | URL |
|---:|---|---|---|
| 1 | Oracle SQL Language Reference 26ai | Selecting from the DUAL Table | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Selecting-from-the-DUAL-Table.html#GUID-0AB153FC-5238-4E79-8522-C9E2A04AB5E4 |
| 2 | Oracle SQL Language Reference 26ai | SELECT | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/SELECT.html#GUID-CFA006CA-6FF1-4972-821E-6996142A51C6 |
| 3 | Oracle SQL Tuning Guide 26ai | Selectivity | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/query-optimizer-concepts.html#GUID-60B12417-9E06-4F3F-B796-DF86549A5B21 |
| 4 | Oracle SQL Tuning Guide 26ai | Plan Selection | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/overview-of-sql-plan-management.html#GUID-67A76171-62CB-49A5-B5BD-CFFE26511E90 |
| 5 | Oracle Database Reference 26ai | 10.67 V$SQL_CS_SELECTIVITY | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-SQL_CS_SELECTIVITY.html#GUID-36D64D0A-B56F-4550-A58F-BB0DEBAAC649 |
| 6 | Oracle Concepts 26ai | SELECT Statements | https://docs.oracle.com/en/database/oracle/oracle-database/23/cncpt/sql.html#GUID-702909E1-B214-4D30-A0F9-5A4335C2BA4A |
| 7 | Oracle SQL Language Reference 26ai | INSERT | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/INSERT.html#GUID-903F8043-0254-4EE9-ACC1-CB8AC0AF3423 |
| 8 | Oracle SQL Tuning Guide 26ai | Global Statistics During Inserts into Partitioned Tables | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/optimizer-statistics-concepts.html#GUID-0B027A47-087D-4D7B-ABD4-2210D4C37ECB |
| 9 | Oracle Database Reference 26ai | 2.127 DST_UPGRADE_INSERT_CONV | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/DST_UPGRADE_INSERT_CONV.html#GUID-806A8F78-8170-43BC-8C14-42A6D5C24157 |
| 10 | Oracle Concepts 26ai | Example: Insertion of a Value in a Foreign Key Column When No Parent Key Value Exists | https://docs.oracle.com/en/database/oracle/oracle-database/23/cncpt/data-integrity.html#GUID-6A309B2D-42B1-4886-AAAF-DD51760A8103 |
| 11 | Oracle Concepts 26ai | Read Consistency and Deferred Inserts | https://docs.oracle.com/en/database/oracle/oracle-database/23/cncpt/data-concurrency-and-consistency.html#GUID-ED6AFF56-F998-4E80-9D6B-105B2610ECAC |
| 12 | Oracle Concepts 26ai | Large Pool Buffers for Deferred Inserts | https://docs.oracle.com/en/database/oracle/oracle-database/23/cncpt/memory-architecture.html#GUID-07D4439A-8E4E-4FBC-A403-1B0F0B9E0058 |
| 13 | Oracle SQL Language Reference 26ai | 19 SQL Statements: MERGE to UPDATE | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/SQL-Statements-MERGE-to-UPDATE.html#GUID-07BBB875-6272-441A-893F-35E2F9CA58ED |
| 14 | Oracle SQL Language Reference 26ai | UPDATE | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/UPDATE.html#GUID-027A462D-379D-4E35-8611-410F3AC8FDA5 |
| 15 | Oracle SQL Language Reference 26ai | UPDATE END USER CONTEXT | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/update-end-user-context.html#GUID-17072C19-4156-4C05-BCDB-6072083F8033 |
| 16 | Oracle SQL Tuning Guide 26ai | Modifying a SQL Tuning Set Using UPDATE_SQLSET | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/managing-sql-tuning-sets.html#GUID-1C2E5289-B579-4AA9-8073-5F77358A8E62 |
| 17 | Oracle Database Reference 26ai | 1.1 Changes in Oracle AI Database 26ai, Release Update 23.26.2 | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/changes-this-release-oracle-database-reference.html#GUID-BCB30C90-08CC-4248-A164-55826AA2648C |
| 18 | Oracle Database Reference 26ai | 1.2 Changes in Oracle AI Database 26ai, Release Update 23.26.1 | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/changes-this-release-oracle-database-reference.html#GUID-061F72E7-A96C-4310-8A79-6AD2A3040243 |
| 19 | Oracle Database Reference 26ai | 1.3 Changes in Oracle AI Database 26ai, Release Update 23.26.0 | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/changes-this-release-oracle-database-reference.html#GUID-C7E223B1-B10D-42C0-83BD-62BBD1876C7E |
| 20 | Oracle Database Reference 26ai | 1.4 Changes in Oracle AI Database 26ai, Release Update 23.9 | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/changes-this-release-oracle-database-reference.html#GUID-E5EC3354-6804-45D2-8CFF-164C4C7B5A7D |
| 21 | Oracle Database Reference 26ai | 1.5 Changes in Oracle AI Database 26ai, Release Update 23.8 | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/changes-this-release-oracle-database-reference.html#GUID-04E793C6-59E9-4455-871C-4FFF34494B2E |
| 22 | Oracle Database Reference 26ai | 1.6 Changes in Oracle AI Database 26ai, Release Update 23.7 | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/changes-this-release-oracle-database-reference.html#GUID-9DF57CA0-9B6E-4247-991F-36F489424AF8 |
| 23 | Oracle Database Reference 26ai | 1.7 Changes in Oracle AI Database 26ai, Release Update 23.6 | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/changes-this-release-oracle-database-reference.html#GUID-A75CF9B8-E913-44B9-BAE9-1BEAE6C9FF98 |
| 24 | Oracle Database Reference 26ai | 1.8 Changes in Oracle AI Database 26ai, Release Update 23.4 | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/changes-this-release-oracle-database-reference.html#GUID-9BC2BB55-797B-4CC9-BEF8-DFFB63214886 |
| 25 | Oracle Database Reference 26ai | 9.163 V$RAC_TWO_STAGE_ROLLING_UPDATES | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-RAC_TWO_STAGE_ROLLING_UPDATES.html#GUID-365985C2-1CD2-4243-91ED-A2B6BE2B3021 |
| 26 | Oracle Database Reference 26ai | C.3.106 optimizer stats update retry | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/descriptions-of-wait-events.html#GUID-D171CBA6-E4A1-42F3-80D6-FFDDBDF35A73 |
| 27 | Oracle Database Reference 26ai | C.3.133 recovery file header update for checkpoint | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/descriptions-of-wait-events.html#GUID-28CD61A3-F7F9-4CCA-8818-5F5F4FDFF793 |
| 28 | Oracle Database Reference 26ai | C.3.134 recovery file header update for fuzziness | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/descriptions-of-wait-events.html#GUID-2D0ABC0D-208C-4D56-8773-250BE0A9A870 |
| 29 | Oracle Concepts 26ai | Example: Update of All Foreign Key and Parent Key Values | https://docs.oracle.com/en/database/oracle/oracle-database/23/cncpt/data-integrity.html#GUID-8AA33487-F1D7-4EC8-ADC1-04A4EEF7974B |
| 30 | Oracle SQL Language Reference 26ai | DELETE | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/DELETE.html#GUID-156845A5-B626-412B-9F95-8869B988ABD7 |
| 31 | Oracle Database Reference 26ai | 7.2 DBA_STREAMS_DELETE_COLUMN | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/DBA_STREAMS_DELETE_COLUMN.html#GUID-05907C20-1EB6-44FE-968B-1429E1DF4008 |
| 32 | Oracle Database Reference 26ai | 8.176 V$DELETED_OBJECT | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-DELETED_OBJECT.html#GUID-E9DE64C8-29F6-4928-9F64-565CA9A46FD0 |
| 33 | Oracle SQL Language Reference 26ai | MERGE Hint | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Comments.html#GUID-4E431B5D-F61B-4F66-B86C-E9C8660E2FE7 |
| 34 | Oracle SQL Language Reference 26ai | NO_MERGE Hint | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Comments.html#GUID-DAB72B9A-0141-4EC3-8877-348C53BCDC03 |
| 35 | Oracle SQL Language Reference 26ai | NO_USE_MERGE Hint | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Comments.html#GUID-9C16655C-150E-4DA1-88E0-0ED8CADCCBA5 |
| 36 | Oracle SQL Language Reference 26ai | USE_MERGE Hint | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Comments.html#GUID-BBBD2148-71AC-4CD7-80FA-F2ED3072A9A9 |
| 37 | Oracle SQL Language Reference 26ai | JSON_MERGEPATCH | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/JSON_MERGEPATCH.html#GUID-2004F536-BE60-4457-A1A8-AB908FFF5399 |
| 38 | Oracle SQL Language Reference 26ai | MERGE | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/MERGE.html#GUID-5692CCB7-24D9-4C0E-81A7-A22436DC968F |
| 39 | Oracle SQL Tuning Guide 26ai | Bitmap Merge | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/optimizer-access-paths.html#GUID-2FDE5904-B0BC-44DA-829B-94C89FA77D71 |
| 40 | Oracle SQL Tuning Guide 26ai | When the Optimizer Considers Bitmap Merge | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/optimizer-access-paths.html#GUID-BAFC38D5-C3A8-4100-A0E0-E4E0BF0413BA |
| 41 | Oracle SQL Tuning Guide 26ai | How Bitmap Merge Works | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/optimizer-access-paths.html#GUID-2B852AE5-DB31-42F6-A39D-DF058D5A8204 |
| 42 | Oracle SQL Tuning Guide 26ai | Bitmap Merge: Example | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/optimizer-access-paths.html#GUID-8CB7829F-D612-41D0-9870-1C40DF73C71B |
| 43 | Oracle SQL Tuning Guide 26ai | Sort Merge Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-5FCD34FE-ED04-4AB2-BC90-9752FED94F4F |
| 44 | Oracle SQL Tuning Guide 26ai | When the Optimizer Considers Sort Merge Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-3F935776-FE28-4350-9FA4-E6B47489156E |
| 45 | Oracle SQL Tuning Guide 26ai | How Sort Merge Joins Work | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-D96D76E3-3DA4-4354-9617-7DE8AFE00227 |
| 46 | Oracle SQL Tuning Guide 26ai | Sort Merge Join Controls | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-F6BCB3C1-6EE6-4A84-8B3D-659CAF9CBF4F |
| 47 | Oracle SQL Tuning Guide 26ai | Sort Merge Outer Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-538140BC-7F1D-43AE-AF4C-89539902B3FD |
| 48 | Oracle Database Reference 26ai | 2.36 BITMAP_MERGE_AREA_SIZE | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/BITMAP_MERGE_AREA_SIZE.html#GUID-C3501D3C-374D-4A09-83CF-366FF65FF532 |
| 49 | Oracle Database Reference 26ai | 7.169 DBA_XSTREAM_SPLIT_MERGE | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/DBA_XSTREAM_SPLIT_MERGE.html#GUID-816A329A-6543-41DA-9AC9-E1C6005F6F8A |
| 50 | Oracle Database Reference 26ai | 7.170 DBA_XSTREAM_SPLIT_MERGE_HIST | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/DBA_XSTREAM_SPLIT_MERGE_HIST.html#GUID-BB7CD7DD-EB1D-4E62-97D9-D82C1BDC9272 |
| 51 | Oracle Database Reference 26ai | C.3.136 recovery merge pending | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/descriptions-of-wait-events.html#GUID-BDD7C860-A3A4-4B3A-8DB6-0E88C91F097E |
| 52 | Oracle SQL Language Reference 26ai | CREATE TABLE | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html#GUID-F9CE0CC3-13AE-4744-A43C-EAC7A71AAAB6 |
| 53 | Oracle SQL Language Reference 26ai | CREATE TABLESPACE | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLESPACE.html#GUID-51F07BF5-EFAF-4910-9040-C473B86A8BF9 |
| 54 | Oracle SQL Language Reference 26ai | CREATE TABLESPACE SET | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLESPACE-SET.html#GUID-877951F1-B2A5-4907-9F0F-EF4F1884E8C4 |
| 55 | Oracle Concepts 26ai | Example: CREATE TABLE and ALTER TABLE Statements | https://docs.oracle.com/en/database/oracle/oracle-database/23/cncpt/tables-and-table-clusters.html#GUID-B0DFC5A7-E482-4E17-A6F5-FF476A92DC73 |
| 56 | Oracle SQL Language Reference 26ai | INDEX_JOIN Hint | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Comments.html#GUID-59A98AD5-94EE-48D6-BD84-CE8986E4BAE1 |
| 57 | Oracle SQL Language Reference 26ai | NATIVE_FULL_OUTER_JOIN Hint | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Comments.html#GUID-02071A47-C4B0-4139-B985-4ED6E13B78F2 |
| 58 | Oracle SQL Language Reference 26ai | NO_NATIVE_FULL_OUTER_JOIN Hint | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Comments.html#GUID-BEA2DE06-77C6-49AB-9EFB-8BD9469E8649 |
| 59 | Oracle SQL Language Reference 26ai | NO_PX_JOIN_FILTER Hint | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Comments.html#GUID-99A00ADE-9D5A-47C9-9C35-A5D95ACC5A3B |
| 60 | Oracle SQL Language Reference 26ai | PX_JOIN_FILTER Hint | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Comments.html#GUID-56AB4452-3578-4391-A3AE-86E5AD46D377 |
| 61 | Oracle SQL Language Reference 26ai | Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Joins.html#GUID-39081984-8D38-4D64-A847-AA43F515D460 |
| 62 | Oracle SQL Language Reference 26ai | Join Conditions | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Joins.html#GUID-A7F5091B-9C42-4FC3-8F2B-BB238518FA14 |
| 63 | Oracle SQL Language Reference 26ai | Equijoins | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Joins.html#GUID-3AA5EB23-2D84-4E19-BD7E-E66A3C59D888 |
| 64 | Oracle SQL Language Reference 26ai | Band Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Joins.html#GUID-568EC26F-199A-4339-BFD9-C4A0B9588937 |
| 65 | Oracle SQL Language Reference 26ai | Self Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Joins.html#GUID-B0F5C614-CBDD-45F6-966D-00BAD6463440 |
| 66 | Oracle SQL Language Reference 26ai | Inner Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Joins.html#GUID-794F7DD5-FB18-4ADC-9E46-ADDA8C30C3C6 |
| 67 | Oracle SQL Language Reference 26ai | Outer Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Joins.html#GUID-29A4584C-0741-4E6A-A89B-DCFAA222994A |
| 68 | Oracle SQL Language Reference 26ai | Antijoins | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Joins.html#GUID-D688F2E3-7F1E-4339-894F-01A73E62328C |
| 69 | Oracle SQL Language Reference 26ai | Semijoins | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Joins.html#GUID-E98C180E-8A17-469D-8E68-56245E28104B |
| 70 | Oracle SQL Language Reference 26ai | ALTER INMEMORY JOIN GROUP | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/ALTER-INMEMORY-JOIN-GROUP.html#GUID-AF24F413-BB14-4B5D-93BF-9EB31ACFEBEC |
| 71 | Oracle SQL Language Reference 26ai | CREATE INMEMORY JOIN GROUP | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-INMEMORY-JOIN-GROUP.html#GUID-87CA7034-4F80-4D46-8EE1-5CC865C2D676 |
| 72 | Oracle SQL Language Reference 26ai | DROP INMEMORY JOIN GROUP | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/DROP-INMEMORY-JOIN-GROUP.html#GUID-520D0E9A-B577-4BCD-B6CB-8EB448C0686D |
| 73 | Oracle SQL Tuning Guide 26ai | Adaptive Query Plans: Join Method Example | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/query-optimizer-concepts.html#GUID-FA5123F0-85A8-47A6-9706-E3FE67B54A50 |
| 74 | Oracle SQL Tuning Guide 26ai | Join Factorization | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/query-transformations.html#GUID-B47BEFB3-D72D-462A-9B96-C3B1F8F48C06 |
| 75 | Oracle SQL Tuning Guide 26ai | Purpose of Join Factorization | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/query-transformations.html#GUID-41FA8384-23FF-4683-B1FC-61853209565C |
| 76 | Oracle SQL Tuning Guide 26ai | How Join Factorization Works | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/query-transformations.html#GUID-253951D9-63D9-4989-86F6-FA4AC6AFF0BD |
| 77 | Oracle SQL Tuning Guide 26ai | Factorization and Join Orders: Scenario | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/query-transformations.html#GUID-E3AA79CC-74CA-44C0-A15B-1827FE27609D |
| 78 | Oracle SQL Tuning Guide 26ai | Factorization of Outer Joins: Scenario | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/query-transformations.html#GUID-FA012F21-6BEF-444A-89E4-4DCDBC9F0225 |
| 79 | Oracle SQL Tuning Guide 26ai | Examples of Partial Partition-Wise Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/generating-and-displaying-execution-plans.html#GUID-2D33B318-5E73-4D68-BCAE-FCB905B8490A |
| 80 | Oracle SQL Tuning Guide 26ai | Example of Full Partition-Wise Join | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/generating-and-displaying-execution-plans.html#GUID-C2D553C9-FDCF-4C0F-9CF8-112A7B5C7E5A |
| 81 | Oracle SQL Tuning Guide 26ai | Part IV SQL Operators: Access Paths and Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/sql-operators-access-paths-and-joins.html |
| 82 | Oracle SQL Tuning Guide 26ai | Index Join Scans | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/optimizer-access-paths.html#GUID-21258F63-7506-4019-9FB4-323E9D2DE087 |
| 83 | Oracle SQL Tuning Guide 26ai | When the Optimizer Considers Index Join Scans | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/optimizer-access-paths.html#GUID-EA936820-BBAC-4DB1-A3F8-050AC81A24E6 |
| 84 | Oracle SQL Tuning Guide 26ai | How Index Join Scans Work | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/optimizer-access-paths.html#GUID-0F989C52-262C-4237-9DE1-E14D7CF8EE1D |
| 85 | Oracle SQL Tuning Guide 26ai | Index Join Scans: Example | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/optimizer-access-paths.html#GUID-5472D2AD-8141-4017-B828-EE1050BA24CF |
| 86 | Oracle SQL Tuning Guide 26ai | Bitmap Join Indexes | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/optimizer-access-paths.html#GUID-1F859889-14BC-4F0B-90CE-8682737FB46F |
| 87 | Oracle SQL Tuning Guide 26ai | 9 Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-BD96F1B4-76D4-43DF-98B6-D07F46838C4A |
| 88 | Oracle SQL Tuning Guide 26ai | About Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-F47AB553-07F0-42E8-BF55-C31DCD5AAC81 |
| 89 | Oracle SQL Tuning Guide 26ai | Join Trees | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-31B0F249-A5AA-41E9-AE98-A484FC5C487C |
| 90 | Oracle SQL Tuning Guide 26ai | How the Optimizer Executes Join Statements | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-5435FC78-D572-4CEE-A733-CDB1DB8E544B |
| 91 | Oracle SQL Tuning Guide 26ai | How the Optimizer Chooses Execution Plans for Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-8621DCD7-6F70-4720-8049-BA630B58F26C |
| 92 | Oracle SQL Tuning Guide 26ai | Join Methods | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-54F957FB-3568-499A-BCD2-B242BFFF913D |
| 93 | Oracle SQL Tuning Guide 26ai | Nested Loops Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-A2DA6A1E-6180-4AB9-A777-586AF3953D53 |
| 94 | Oracle SQL Tuning Guide 26ai | When the Optimizer Considers Nested Loops Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-CEBC5D18-1857-4F6B-8FA7-B9EEA3442653 |
| 95 | Oracle SQL Tuning Guide 26ai | How Nested Loops Joins Work | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-C3D5CEA4-0AF4-4E15-8167-6C5D065A95D3 |
| 96 | Oracle SQL Tuning Guide 26ai | Current Implementation for Nested Loops Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-D83585A7-4ADB-48C9-958E-693374BF7A31 |
| 97 | Oracle SQL Tuning Guide 26ai | Original Implementation for Nested Loops Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-025483CA-9FC7-40A1-B907-FDA2B0BCAF04 |
| 98 | Oracle SQL Tuning Guide 26ai | Hash Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-91E61BDC-E5F2-49FA-99AE-DD88A2FBB4FB |
| 99 | Oracle SQL Tuning Guide 26ai | When the Optimizer Considers Hash Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-93D59774-BC0C-4BDF-88E3-0A2B346A0A62 |
| 100 | Oracle SQL Tuning Guide 26ai | How Hash Joins Work | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-5A801568-F4E2-45C5-940B-55D23761BFD7 |
| 101 | Oracle SQL Tuning Guide 26ai | Hash Join: Basic Steps | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-9EE5CD4C-B90C-4E61-83DC-BD585D79635C |
| 102 | Oracle SQL Tuning Guide 26ai | How Hash Joins Work When the Hash Table Does Not Fit in the PGA | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-0F295C4C-FF10-4BE8-BB0C-C8CD78545277 |
| 103 | Oracle SQL Tuning Guide 26ai | Hash Join Controls | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-E8076180-ABDD-47F4-B6CB-DDDB6887B131 |
| 104 | Oracle SQL Tuning Guide 26ai | Join Types | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-8E7760A6-48D6-4794-BF2F-290349C019B9 |
| 105 | Oracle SQL Tuning Guide 26ai | Inner Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-F93F1CCA-BD59-4D75-BE42-0E958CDB6E51 |
| 106 | Oracle SQL Tuning Guide 26ai | Equijoins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-90D3120E-1F5F-494C-9420-2E7F48337E3F |
| 107 | Oracle SQL Tuning Guide 26ai | Nonequijoins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-C9653D35-455F-44C9-91F4-82B18478B43A |
| 108 | Oracle SQL Tuning Guide 26ai | Band Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-24F34188-110F-4245-9DE7-43954092AFE0 |
| 109 | Oracle SQL Tuning Guide 26ai | Outer Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-2174C4BA-C852-4050-9269-353A3B40B355 |
| 110 | Oracle SQL Tuning Guide 26ai | Nested Loops Outer Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-1ACFF09D-C8E1-4272-97B9-900D2053B91E |
| 111 | Oracle SQL Tuning Guide 26ai | Hash Join Outer Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-278E01B5-9498-40EC-B0BD-CC415C18E078 |
| 112 | Oracle SQL Tuning Guide 26ai | Full Outer Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-9FAA29BF-B7E3-48CE-9B27-4276195F24D0 |
| 113 | Oracle SQL Tuning Guide 26ai | Multiple Tables on the Left of an Outer Join | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-C176D438-5532-4C3C-81E6-8C7EBAAED3DD |
| 114 | Oracle SQL Tuning Guide 26ai | Semijoins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-816CED08-10A7-4B39-9790-E68996782847 |
| 115 | Oracle SQL Tuning Guide 26ai | When the Optimizer Considers Semijoins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-44C2DD4F-8C1B-4EA5-867B-CF5A6B90A01B |
| 116 | Oracle SQL Tuning Guide 26ai | How Semijoins Work | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-B3DE9781-0579-44D1-A7B5-3132504590E2 |
| 117 | Oracle SQL Tuning Guide 26ai | Antijoins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-084D65F8-0517-4B85-960F-F1CDEE69C693 |
| 118 | Oracle SQL Tuning Guide 26ai | When the Optimizer Considers Antijoins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-4FBBDD86-2AC0-425F-B3A6-36E72A423876 |
| 119 | Oracle SQL Tuning Guide 26ai | How Antijoins Work | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-D20C1B6F-9CFF-4F4A-87F3-D1A2BEEBEFF3 |
| 120 | Oracle SQL Tuning Guide 26ai | How Antijoins Handle Nulls | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-78F90A8B-3638-47FF-AEFC-274790BE45D8 |
| 121 | Oracle SQL Tuning Guide 26ai | Cartesian Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-07D9388C-6DCB-4F88-BF59-AF223C10B8FC |
| 122 | Oracle SQL Tuning Guide 26ai | When the Optimizer Considers Cartesian Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-11E7100E-1316-4963-83C5-A85940BE9BB6 |
| 123 | Oracle SQL Tuning Guide 26ai | How Cartesian Joins Work | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-531732AA-D0B0-4DFA-A5B9-8EDC3359BE67 |
| 124 | Oracle SQL Tuning Guide 26ai | Cartesian Join Controls | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-10F781A7-4372-4042-AACA-6F67580789E8 |
| 125 | Oracle SQL Tuning Guide 26ai | Join Optimizations | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-C02C3673-75E2-4D92-AAEF-30AC58C32AD1 |
| 126 | Oracle SQL Tuning Guide 26ai | Partition-Wise Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-3932756E-EDFC-4D4D-93CD-9F9F2AE2C2D7 |
| 127 | Oracle SQL Tuning Guide 26ai | Purpose of Partition-Wise Joins | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-F22AB852-6377-4DB9-BACC-8D024616DC1E |
| 128 | Oracle SQL Tuning Guide 26ai | How Partition-Wise Joins Work | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-7DDACB80-9FFC-4B30-A80F-1C0615012C02 |
| 129 | Oracle SQL Tuning Guide 26ai | How a Full Partition-Wise Join Works | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-C3EAE02A-F6C6-4F7C-A368-F9F498738F76 |
| 130 | Oracle SQL Tuning Guide 26ai | How a Partial Partition-Wise Join Works | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-DB0AC6E5-6E59-4B61-9C96-480A8C8FBFAC |
| 131 | Oracle SQL Tuning Guide 26ai | In-Memory Join Groups | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/joins.html#GUID-D9A7B0F6-D2D4-4881-9A6C-8042DE627650 |
| 132 | Oracle SQL Tuning Guide 26ai | Guidelines for Join Order Hints | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/influencing-the-optimizer.html#GUID-5976D09A-257A-49F3-94E0-247B1247270A |
| 133 | Oracle Database Reference 26ai | 3.98 ALL_ATTRIBUTE_DIM_JOIN_PATHS | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_ATTRIBUTE_DIM_JOIN_PATHS.html#GUID-4B73DEE0-5EE0-4819-A90F-153D2807CBF1 |
| 134 | Oracle Database Reference 26ai | 3.149 ALL_CLUSTERING_JOINS | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_CLUSTERING_JOINS.html#GUID-CF36179A-6E71-4C41-A0D2-1A9869393DAD |
| 135 | Oracle Database Reference 26ai | 3.193 ALL_DIM_JOIN_KEY | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_DIM_JOIN_KEY.html#GUID-42A1DEA8-8BBC-4F2E-92C5-89D3EB6F4325 |
| 136 | Oracle Database Reference 26ai | 3.238 ALL_HIER_JOIN_PATHS | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_HIER_JOIN_PATHS.html#GUID-A70EFD71-8229-40BC-BD0C-A4364D8E3099 |
| 137 | Oracle Database Reference 26ai | 3.239 ALL_HIER_JOIN_PATHS_AE | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_HIER_JOIN_PATHS_AE.html#GUID-181516E0-58ED-48F7-9548-1EB95686869B |
| 138 | Oracle Database Reference 26ai | 3.285 ALL_JOIN_IND_COLUMNS | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_JOIN_IND_COLUMNS.html#GUID-11BFBA43-C4A8-46B6-9DED-64221FB1FD30 |
| 139 | Oracle Database Reference 26ai | 3.330 ALL_MVIEW_JOINS | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_MVIEW_JOINS.html#GUID-40810961-E077-417E-A207-2655906914DD |
| 140 | Oracle Database Reference 26ai | 5.162 DBA_ATTRIBUTE_DIM_JOIN_PATHS | https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/DBA_ATTRIBUTE_DIM_JOIN_PATHS.html#GUID-8611ECE3-7343-464F-8A15-36133EA66FF5 |
| 141 | SQL standard | ISO/IEC 9075-1:2023 SQL Framework | https://www.iso.org/standard/76583.html |
| 142 | SQL standard | ISO/IEC 9075-2:2023 SQL Foundation | https://www.iso.org/standard/76584.html |
| 143 | SQL standard | ISO/IEC 9075-4:2023 SQL/PSM | https://www.iso.org/standard/76585.html |
| 144 | SQL standard | ISO/IEC 9075-11:2023 SQL/Schemata | https://www.iso.org/standard/76590.html |
| 145 | SQL standard | ISO/IEC 9075-14:2023 SQL/XML | https://www.iso.org/standard/76593.html |
| 146 | SQL standard | ISO/IEC 9075-16:2023 SQL/PGQ | https://www.iso.org/standard/76595.html |
| 147 | Oracle release | Oracle AI Database 26ai announcement | https://www.oracle.com/database/ai-native-database-26ai/ |
| 148 | Oracle docs | Oracle AI Database 26ai SQL Tuning Guide | https://docs.oracle.com/en/database/oracle/oracle-database/23/tgsql/index.html |
| 149 | Oracle docs | Oracle AI Database SQL Language Reference | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/index.html |
| 150 | Oracle SQL Language Reference 26ai | Next | https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/Preface.html |
