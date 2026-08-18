#!/usr/bin/env bash
# Runs on ALL nodes (master + workers). Args: <master_ip> <worker1_ip> <worker2_ip> <worker3_ip>
set -euo pipefail

MASTER_IP="$1"; shift
WORKER_IPS=("$@")
K8S_VERSION="1.30"

echo "==> [common] Disabling swap"
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "==> [common] Setting /etc/hosts for cluster nodes"
cat <<EOF >> /etc/hosts
${MASTER_IP} k8s-master
EOF
for i in "${!WORKER_IPS[@]}"; do
  echo "${WORKER_IPS[$i]} k8s-worker$((i+1))" >> /etc/hosts
done

echo "==> [common] Loading kernel modules"
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "==> [common] Setting sysctl params"
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system > /dev/null

echo "==> [common] Installing containerd"
apt-get update -y
apt-get install -y ca-certificates curl gnupg apt-transport-https

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y containerd.io

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

echo "==> [common] Installing kubeadm, kubelet, kubectl (v${K8S_VERSION})"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | \
  tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

echo "==> [common] Done on $(hostname)"
