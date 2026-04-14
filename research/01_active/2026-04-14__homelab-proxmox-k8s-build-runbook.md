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

---

## 18. インストールコマンドの意味・選択肢（不足しやすい点の補完）

## 18.1 `qm create` / `qm set`
- `--ostype l26`: Linux 2.6+系最適化を指定。
- `--net0 virtio,...`: paravirtualized NIC。e1000より性能効率が高い。
- `--scsihw virtio-scsi-pci`: Linuxゲストで扱いやすく、TRIMや拡張性面で有利。
- `--agent enabled=1`: QEMU Guest Agent連携を有効化（IP表示/シャットダウン連携）。
- `--full 0`（clone時）: linked clone。高速/省容量だが、親テンプレート依存の運用設計が必要。

## 18.2 `talosctl gen config`
- 第1引数はクラスタ名。
- 第2引数は **将来も固定運用するAPI endpoint URL**（`https://...:6443`）を指定。
- ここで誤ると、証明書SANやクライアント設定の再調整コストが大きくなる。

## 18.3 `talosctl apply-config` / `bootstrap`
- `apply-config`: ノードへMachineConfigを適用。
- 初回起動時のみ `--insecure` が必要なケースがある（初期信頼確立前）。
- `bootstrap`: etcd初期化。**最初の1ノードのみ実行**。

## 18.4 `kubeadm init`
- `--control-plane-endpoint`: HA構成で不変の入口（VIP/DNS）。
- `--pod-network-cidr`: CNI設計値と一致させる。
- `kubeadm join ... --control-plane`: 追加Master参加時に利用。

---

## 19. 構築時の重大注意事項（失敗を防ぐ観点）
1. **API Endpoint先決**: VIP/DNS確定前にクラスタ生成しない。
2. **時刻同期**: NTP不整合はTLS/etcd障害の原因になる。
3. **MTU不一致**: Pod間断続障害の典型。
4. **16GBノード過負荷**: taint未設定だと重量Pod流入で全体劣化。
5. **ストレージ未定義のまま本番投入**: Kafka/DBでI/O飽和が顕在化しやすい。
6. **バックアップ未演習**: バックアップがあっても復旧不能なケースを防げない。
7. **PSS/RBAC未適用**: 権限逸脱リスクが高い。
8. **監視未整備で導入拡大**: 原因追跡不能のまま障害が増える。

---

## 20. Web調査50件（公式ドキュメント中心）

> 方針: 公式一次情報を優先し、設計判断に必要な最小セットを50件に整理。

### A. Proxmox / 仮想化基盤
1. Proxmox VE Administration Guide — https://pve.proxmox.com/pve-docs/pve-admin-guide.pdf
2. Proxmox VE Firewall — https://pve.proxmox.com/pve-docs/chapter-pve-firewall.html
3. Proxmox `qm` manual — https://pve.proxmox.com/pve-docs/qm.1.html
4. Proxmox Cloud-Init Support — https://pve.proxmox.com/wiki/Cloud-Init_Support
5. Proxmox Storage Replication — https://pve.proxmox.com/wiki/Storage_Replication
6. Proxmox ZFS on Linux — https://pve.proxmox.com/wiki/ZFS_on_Linux
7. Proxmox QEMU/KVM Virtual Machines — https://pve.proxmox.com/wiki/Qemu/KVM_Virtual_Machines
8. QEMU CPU models (migration/perf観点) — https://www.qemu.org/docs/master/system/qemu-cpu-models.html

### B. Kubernetes コア / kubeadm
9. kubeadm HA cluster — https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
10. kubeadm install cluster — https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
11. Pod Security Admission — https://kubernetes.io/docs/concepts/security/pod-security-admission/
12. Pod Security Standards — https://kubernetes.io/docs/concepts/security/pod-security-standards/
13. Encrypt data at rest — https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
14. Taints and Tolerations — https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
15. PriorityClass — https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/
16. topologySpreadConstraints — https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/
17. Network Policies — https://kubernetes.io/docs/concepts/services-networking/network-policies/
18. Resource requests and limits — https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

### C. Talos
19. Talos Docs (main) — https://www.talos.dev/
20. Talos Getting Started — https://www.talos.dev/v1.11/introduction/getting-started/
21. talosctl CLI reference — https://www.talos.dev/v1.11/reference/cli/
22. Talos Image Factory — https://factory.talos.dev/
23. Talos System Extensions — https://www.talos.dev/v1.11/build-and-extend-talos/custom-images-and-development/system-extensions/
24. Talos NoCloud datasource — https://www.talos.dev/v1.11/talos-guides/install/cloud-platforms/nocloud/
25. Talos Disk Management — https://www.talos.dev/v1.11/talos-guides/configuration/disk-management/
26. Talos Upgrade guide — https://www.talos.dev/v1.11/talos-guides/upgrading-talos/
27. Talos + Proxmox guide — https://www.talos.dev/v1.11/talos-guides/install/virtualized-platforms/proxmox/
28. Talos Production Notes — https://www.talos.dev/v1.11/introduction/prodnotes/

### D. CNI / LB / Ingress
29. Cilium docs — https://docs.cilium.io/en/stable/
30. Cilium kube-proxy replacement — https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/
31. Cilium L2 Announcements — https://docs.cilium.io/en/stable/network/l2-announcements/
32. Calico docs — https://docs.tigera.io/calico/latest/getting-started/kubernetes/
33. MetalLB docs — https://metallb.io/
34. MetalLB installation — https://metallb.io/installation/
35. kube-vip docs — https://kube-vip.io/
36. ingress-nginx docs — https://kubernetes.github.io/ingress-nginx/

### E. ストレージ
37. Longhorn docs — https://longhorn.io/docs/
38. Longhorn prerequisites (open-iscsi) — https://longhorn.io/docs/latest/deploy/install/#installation-requirements
39. OpenEBS docs — https://openebs.io/docs
40. Local Path Provisioner — https://github.com/rancher/local-path-provisioner
41. Proxmox CSI plugin (project docs) — https://github.com/sergelogvinov/proxmox-csi-plugin

### F. 監視・可観測性
42. Prometheus Operator docs — https://prometheus-operator.dev/docs/
43. kube-prometheus-stack chart — https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
44. Grafana Loki docs — https://grafana.com/docs/loki/latest/
45. Grafana Tempo docs — https://grafana.com/docs/tempo/latest/
46. Grafana Pyroscope docs — https://grafana.com/docs/pyroscope/latest/
47. Grafana Alloy docs — https://grafana.com/docs/alloy/latest/
48. Zabbix Kubernetes monitoring blog/docs — https://blog.zabbix.com/kubernetes-monitoring-with-zabbix-part-1/25055/

### G. CI/CD・Service Mesh・データ基盤
49. Argo CD docs — https://argo-cd.readthedocs.io/en/stable/
50. Flux docs — https://fluxcd.io/docs/

（追加で検討推奨）
- Istio docs — https://istio.io/latest/docs/
- Kiali docs — https://kiali.io/docs/
- cert-manager docs — https://cert-manager.io/docs/
- Strimzi docs — https://strimzi.io/docs/operators/latest/

---

## 21. 簡単セットアップツール比較（実運用向けに再整理）

| ツール | 長所 | 注意点 | 推奨用途 |
|---|---|---|---|
| Talos + talosctl | 再現性・更新一貫性・省メモリ | Talos流儀の習熟必要 | 本件の第一候補 |
| Talos + talhelper | 設定テンプレート管理が容易 | 追加ツール習得が必要 | ノード増設頻度が高い環境 |
| Ubuntu + Kubespray | 汎用性と実績 | SSH/OSドリフト管理負荷 | 既存Ansible資産がある場合 |
| k0sctl | 導入が比較的簡単 | ディストリ依存を理解する必要 | PoC迅速化 |
| RKE2 | セットアップ容易・運用実績 | 配布版運用ポリシー確認必要 | Rancher連携前提 |

---

## 22. 改訂履歴
- 2026-04-14: Web調査50件を反映し、コマンド意味・失敗回避観点・ツール比較を強化。
