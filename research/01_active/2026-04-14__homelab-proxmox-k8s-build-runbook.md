# 自宅Proxmox上 6VM構成 Kubernetes HAクラスタ構築手順書（Talos推奨）

- date: 2026-04-14
- domain: infra
- language: other
- status: active
- reliability: partially-verified
- review_due: 2026-05-14

## 1. 調査質問
- Proxmox VE上の6VM（Master 3 / Worker 3）で、将来拡張可能なKubernetes HAクラスタをどう設計・構築するか。
- Ubuntu 24.04 Server と Talos OSのどちらを選ぶべきか。
- ネットワーク / ストレージ / セキュリティ / 運用監視 / CI/CDまで含め、初期設定項目を漏れなく整理する。

## 2. 結論（先に短く）
- 本要件（メモリ効率、パフォーマンス、管理効率、将来のスクリプト展開）では **Talos OSを第一推奨**とする。
- 物理3台へMasterを1台ずつ分散し、Control Plane Endpoint（VIP or DNS）を初期設計で固定する。
- Proxmox側は「VLAN分離・VMテンプレート化・Cloud-Init/NoCloud・バックアップ/レプリケーション・FW最小開放」を最初に実装する。
- 導入順序は「クラスタ基盤→公開導線→ストレージ→監視→CI/CD→Istio/Kafka系」の順に段階導入する。

---

## 3. 前提・全体アーキテクチャ

### 3.1 ハードウェア前提
- minisforum UM780XTX（64GB RAM / 1TB）
- GMKtec M5 Plus 5825U（64GB RAM / 1TB）
- nipogi Ryzen 5 7430U（16GB RAM / 1TB）
- Proxmoxクラスタは作成済み

### 3.2 物理ホストへの推奨配置
> 原則: Masterを物理3台に1台ずつ配置（同時障害を最小化）

- Host-A(64GB): Master-1 + Worker-1
- Host-B(64GB): Master-2 + Worker-2
- Host-C(16GB): Master-3 + Worker-3（軽量運用前提）

### 3.3 VMサイズ（初期推奨）
- Master x3: 2–4 vCPU / 4–8GB RAM / 80–120GB Disk
- Worker-1,2: 6–8 vCPU / 24–32GB RAM / 300–600GB Disk
- Worker-3(16GBホスト): 2–4 vCPU / 6–10GB RAM / 200–400GB Disk

### 3.4 16GBホストの運用原則（重要）
- `node-role.kubernetes.io/infra-light=true` 等のラベル付与
- `NoSchedule` taintで重量級Podを制御
- Kafka / DB / ログ集約など高負荷ワークロードは原則非配置

---

## 4. OS選定比較（Ubuntu 24.04 vs Talos）

| 観点 | Ubuntu 24.04 Server | Talos OS |
|---|---|---|
| メモリ効率 | 汎用OSのため常駐要素は多め | 最小構成で有利 |
| パフォーマンス | 汎用、調整自由度高い | 不要要素が少なく安定 |
| 管理方式 | SSH + apt + Ansible等 | API駆動（talosctl） |
| 構成ドリフト耐性 | 運用次第 | 高い（immutable寄り） |
| トラブルシュート | Linux標準手段が豊富 | Talos流儀に慣れが必要 |
| 拡張性 | 何でも導入しやすい | 拡張はSystem Extension前提 |
| 自動化適性 | 高い（ただし構築設計必要） | 非常に高い（宣言的管理） |

### 推奨判断
- **推奨: Talos OS**
  - 理由: メモリ効率、更新一貫性、運用の再現性、将来増設時のスクリプト化適性。
- **Ubuntuを選ぶ条件**
  - ノードOSへ直接ツール導入（独自Agent、デバッグツール）が必須。
  - 既存運用がSSH/Ansible中心で、短期導入を優先する場合。

---

## 5. Proxmox側の構築手順（K8s前提）

## Step 0: 設計値を先に固定
1. K8sノードネットワーク（例: `192.168.50.0/24`, VLAN 50）
2. API Endpoint（例: `https://k8s-api.home.arpa:6443`）
3. Pod CIDR（例: `10.244.0.0/16`）
4. Service CIDR（例: `10.96.0.0/12`）
5. LB方式（MetalLB / kube-vip / Cilium L2）
6. 永続ストレージ方式（Longhorn / Local Path / OpenEBS）

## Step 1: Proxmoxネットワーク
1. `vmbr0`（管理）と `vmbr1`（K8s）を分離、可能ならVLAN-aware有効化。
2. VLAN設計（推奨）
   - VLAN-MGMT（Proxmox管理）
   - VLAN-K8S（ノード通信）
   - VLAN-STORAGE（レプリケーション/バックアップ）
3. MTU設計
   - 物理1500の場合、オーバレイCNI利用時はCNI MTUを1450前後で調整。
4. DNS/NTPを全ノードで共通化（証明書・ログ整合に必須）。

## Step 2: Proxmoxストレージ
1. ZFS利用時はARC消費を見込み、16GBホストは役割を限定。
2. バックアップ方針
   - VMバックアップ（世代保持）
   - etcdバックアップ（K8s状態）
   - PVバックアップ（アプリデータ）
3. レプリケーション方針（目安）
   - Master VM: 5〜15分間隔
   - Worker VM: 30〜60分間隔

## Step 3: VMテンプレート化（将来増設向け）
1. テンプレートVMを1台作る。
2. CPUタイプはまず `x86-64-v2-AES` で互換性優先。
3. VirtIO NIC、SCSI controller、QEMU Guest Agent有効化。
4. テンプレートからリンククローンで6台展開。

### `qm` の主なコマンド意味
- `qm create`: VM作成
- `qm set`: CPU/RAM/NIC/agent/cloud-init等の設定反映
- `qm importdisk`: イメージをVMディスクへ取り込み
- `qm clone`: テンプレートから複製
- `qm template`: VMをテンプレート化

---

## 6. Talos推奨ルート: 詳細構築手順

## Step 1: Talosイメージ準備
1. Talos Image FactoryでNoCloudイメージを取得。
2. 追加推奨Extension
   - `siderolabs/qemu-guest-agent`（Proxmox連携）
   - `siderolabs/iscsi-tools`（Longhorn想定）

## Step 2: ProxmoxにTalosテンプレートVM作成
> 以下は例。ストレージ名・VLANタグ・VMIDは環境に合わせて変更。

```bash
# テンプレート作成
qm create 9000 --name talos-template --memory 4096 --cores 2 \
  --net0 virtio,bridge=vmbr1,tag=50 --ostype l26 --agent enabled=1

# Talos NoCloud rawイメージを取り込み
qm importdisk 9000 ./nocloud-amd64.raw local-lvm

# boot disk設定（例: scsi0）
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Cloud-Initディスク追加
qm set 9000 --ide2 local-lvm:cloudinit

# 必要に応じてsnippet user-dataを紐付け
qm set 9000 --cicustom "user=local:snippets/talos-user-data.yaml"

# テンプレート化
qm template 9000
```

## Step 3: 6台クローン展開
```bash
# 例: Master 3台
qm clone 9000 101 --name k8s-master-1 --full 0
qm clone 9000 102 --name k8s-master-2 --full 0
qm clone 9000 103 --name k8s-master-3 --full 0

# 例: Worker 3台
qm clone 9000 201 --name k8s-worker-1 --full 0
qm clone 9000 202 --name k8s-worker-2 --full 0
qm clone 9000 203 --name k8s-worker-3 --full 0
```

## Step 4: `talosctl` でMachineConfig生成
```bash
# cluster endpointは将来も使い続けるURL（VIP/DNS）を指定
talosctl gen config home-k8s https://k8s-api.home.arpa:6443
# 生成物: controlplane.yaml / worker.yaml / talosconfig
```

## Step 5: ノード別差分の反映
- 方式A（推奨）: 共通テンプレート + ノード毎パッチ
- 方式B: ノード毎に個別config生成

パッチ対象例:
- hostname
- 固定IP / gateway / nameserver
- install disk
- node labels / taints

## Step 6: 設定適用→bootstrap
```bash
# 例: 初期適用（初回は --insecure を使うケースあり）
talosctl --talosconfig ./talosconfig apply-config --insecure \
  --nodes 192.168.50.11 --file ./controlplane.yaml
talosctl --talosconfig ./talosconfig apply-config --insecure \
  --nodes 192.168.50.12 --file ./controlplane.yaml
talosctl --talosconfig ./talosconfig apply-config --insecure \
  --nodes 192.168.50.13 --file ./controlplane.yaml

talosctl --talosconfig ./talosconfig apply-config --insecure \
  --nodes 192.168.50.21 --file ./worker.yaml
talosctl --talosconfig ./talosconfig apply-config --insecure \
  --nodes 192.168.50.22 --file ./worker.yaml
talosctl --talosconfig ./talosconfig apply-config --insecure \
  --nodes 192.168.50.23 --file ./worker.yaml

# etcd bootstrap（最初のMaster 1台で実施）
talosctl --talosconfig ./talosconfig bootstrap --nodes 192.168.50.11
```

## Step 7: kubeconfig取得と動作確認
```bash
talosctl --talosconfig ./talosconfig kubeconfig --nodes 192.168.50.11 --endpoints 192.168.50.11
kubectl get nodes -o wide
```

## Step 8: CNIとLB導入
1. まずCNI導入（Cilium or Calico）
2. Service公開はMetalLBを先行導入（安定重視）
3. API Endpoint HAにkube-vipを使う場合は早期導入

---

## 7. Ubuntu 24.04 代替ルート（簡略）

## Step 1: OS初期設定（全ノード）
1. 固定IP / DNS / NTP
2. `swapoff -a` とfstab無効化（K8s要件）
3. カーネルモジュールとsysctl
   - `overlay`, `br_netfilter`
   - `net.bridge.bridge-nf-call-iptables=1`
   - `net.ipv4.ip_forward=1`
4. containerd導入・設定
5. kubeadm / kubelet / kubectl導入

## Step 2: Control Plane初期化
```bash
kubeadm init --control-plane-endpoint "k8s-api.home.arpa:6443" \
  --pod-network-cidr=10.244.0.0/16
```

## Step 3: 追加Master/Worker参加
- `kubeadm token create --print-join-command` でjoinコマンド発行
- Control Plane追加は `--control-plane --certificate-key ...` を利用

## Step 4: CNI/LB/Storage導入
- Talosルートと同様に順次導入

---

## 8. 初期設定時に洗い出すべき項目（網羅チェックリスト）

## 8.1 ネットワーク
- [ ] ノードIP割当方式（DHCP予約 / 静的）
- [ ] API Endpoint（VIP/FQDN）
- [ ] DNS（内部ゾーン、逆引き、search domain）
- [ ] NTP同期
- [ ] CNI方式（Calico/Cilium）
- [ ] MTU値整合（物理〜VM〜CNI）
- [ ] NetworkPolicy適用方針（default deny含む）
- [ ] Ingress/Gateway方式
- [ ] LoadBalancer方式（MetalLB/kube-vip/Cilium L2）

## 8.2 ストレージ
- [ ] ストレージクラス選定（Longhorn / Local Path / OpenEBS）
- [ ] OSディスクとデータディスク分離
- [ ] IOPS/レイテンシ要件（Kafka/DB）
- [ ] スナップショット/バックアップ方式
- [ ] 障害時復旧手順（RTO/RPO）

## 8.3 セキュリティ
- [ ] Pod Security Admission（baseline/restricted）
- [ ] Secret暗号化（at-rest）
- [ ] 最小権限RBAC
- [ ] 管理面公開制限（Proxmox UI/Talos API/K8s API）
- [ ] イメージ署名/脆弱性スキャン
- [ ] 監査ログ保持方針

## 8.4 運用/可観測性
- [ ] Prometheus Operator導入
- [ ] Loki/Tempo/Pyroscope/Alloy設計
- [ ] Alertmanager通知経路
- [ ] Zabbix連携（agentless + 必要時DaemonSet）
- [ ] SLO/SLA指標定義
- [ ] Capacity監視（CPU/MEM/Disk/IOPS）

## 8.5 障害・更新
- [ ] OS更新手順（Talos API or Ubuntuパッチ）
- [ ] Kubernetes更新手順（段階更新）
- [ ] etcdバックアップ/リストア演習
- [ ] ノード喪失時の再参加手順
- [ ] 証明書更新計画

---

## 9. 推奨デプロイ順序（あなたの候補を反映）

1. **必須基盤**
   - CNI（Cilium/Calico）
   - MetalLB
   - Ingress Controller（Nginx系 or Istio Gateway）
   - cert-manager

2. **監視基盤**
   - Prometheus Operator
   - Grafana + Loki + Tempo + Pyroscope + Alloy
   - Zabbix連携

3. **CI/CD/GitOps**
   - Argo CD（推奨）またはFlux
   - イメージレジストリ/署名検証

4. **サービスメッシュ**
   - Istio
   - Kiali

5. **データ基盤**
   - Kafka（Strimzi推奨）
   - Redis
   - DB（PostgreSQL/MySQL系）

6. **アプリ層**
   - JavaScript APIサーバ
   - Nginx系Webホスト

---

## 10. 16GBホストを安全運用するための具体策
- Worker-3へ `NoSchedule` taintを付与し、軽量Podのみ許可。
- `PriorityClass` を導入し、CoreDNS/監視/Ingress等を優先維持。
- VPA/HPAより先に requests/limits を厳格化。
- Kafka/DBは anti-affinity + topologySpreadConstraints で64GB側へ寄せる。

---

## 11. VM増設を見据えたスクリプト化方針

## 11.1 管理対象の分離
- `infra/proxmox/`: qm作成・クローン・起動
- `infra/talos/`: MachineConfig生成/パッチ
- `infra/bootstrap/`: CNI, LB, Storage, Observability

## 11.2 最低限の自動化対象
1. `qm clone` + CPU/RAM/Disk/NIC設定
2. Talos config patch生成
3. apply-config一括実行
4. ノードラベル/taint投入
5. 共通アドオン（CNI/LB/monitoring）適用

## 11.3 擬似コード例
```bash
for node in master-1 master-2 master-3 worker-1 worker-2 worker-3; do
  create_or_clone_vm "$node"
  apply_vm_profile "$node"
  generate_talos_patch "$node"
  talosctl_apply "$node"
done
bootstrap_if_needed
install_cluster_addons
```

---

## 12. QEMU Guest Agent / Update / Zabbix / コンソール運用

## 12.1 QEMU Guest Agent
- ProxmoxのIP把握、シャットダウン連携、状態管理のため有効化。
- TalosはSystem Extension、Ubuntuは`qemu-guest-agent`パッケージで導入。

## 12.2 Update運用
- Talos: `talosctl upgrade`で段階更新、Control Plane→Worker順。
- Ubuntu: OS patch + kubeadm upgradeを分離し、drain/uncordonでローリング更新。

## 12.3 Zabbix監視
- 方針A: Kubernetes API/HTTPベース監視（agentless中心）
- 方針B: Helm Chartでproxy/agentを導入し詳細メトリクス取得
- Talos採用時はOS直接導入ではなく、Kubernetes上コンポーネントとして運用。

## 12.4 アクセス/コンソール操作
- 通常運用: `kubectl` + `talosctl` + Proxmox UI
- 障害時: ProxmoxコンソールからTalosメンテナンスモード確認
- 緊急時: etcdスナップショットから復旧手順をRunbook化

---

## 13. セキュリティ特記事項
- Proxmox管理UIはインターネット非公開、管理VLANのみに限定。
- K8s APIは内部ネットワーク限定 + 必要時VPN経由。
- Secret暗号化、RBAC最小権限、NetworkPolicy default denyを初期導入。
- イメージ取得元を制限し、署名検証（cosign等）を将来的に導入。
- バックアップデータ（etcd/PV/VM）の暗号化とリストア演習を定期実施。

---

## 14. 最終推奨（実行順）
1. Talos NoCloudテンプレートを作成し、qmで6VMを自動展開。
2. API Endpoint（VIP/DNS）を固定したMachineConfigでクラスタ起動。
3. CNI + MetalLB + Ingress + cert-managerを先行導入。
4. Longhorn等のストレージを導入後、監視（Prometheus/Grafana/Zabbix）を実装。
5. その後にIstio/Kiali、Kafka/Redis/DB、アプリ群を段階投入。
6. 最後に「更新・復旧・増設」のRunbookをCIで検証可能な形にする。

## 15. 制約・未解決
- ルータ機種/スイッチ機能（Jumbo Frame, VLAN trunk可否）により最適MTU設計は変わる。
- Kafka/DBの性能要件次第で、64GBノードでも追加ディスクやNVMe分離が必要。
- Zabbixの監視粒度はagentless運用の要件で差が出るため、PoCが必要。

## 16. 次アクション
1. 確定すべき設計値（VLAN, API Endpoint, CIDR, LB方式）を決裁。
2. TalosテンプレートVM + qm自動展開スクリプトを作成。
3. 6VMの最小クラスタを構築し、CNI/LB/Storageまで導入。
4. 観測スタックとZabbix併用をPoCし、保持期間と容量を確定。

## 17. 変更履歴
- 2026-04-14: 初版（要件整理、Talos推奨構成、手順・チェックリスト・運用項目を統合）
