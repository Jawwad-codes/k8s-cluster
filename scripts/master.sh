#!/usr/bin/env bash
# Runs ONLY on master. Arg: <master_ip>
set -euo pipefail

MASTER_IP="$1"
POD_CIDR="10.244.0.0/16"

if [ -f /etc/kubernetes/admin.conf ]; then
  echo "==> [master] Already initialized, skipping kubeadm init"
else
  echo "==> [master] Running kubeadm init"
  kubeadm init \
    --apiserver-advertise-address="${MASTER_IP}" \
    --pod-network-cidr="${POD_CIDR}" \
    --node-name=k8s-master

  echo "==> [master] Setting up kubeconfig for vagrant user"
  mkdir -p /home/vagrant/.kube
  cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
  chown vagrant:vagrant /home/vagrant/.kube/config

  echo "==> [master] Setting up kubeconfig for root"
  mkdir -p /root/.kube
  cp -i /etc/kubernetes/admin.conf /root/.kube/config

  echo "==> [master] Installing Flannel CNI"
  export KUBECONFIG=/etc/kubernetes/admin.conf
  kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

  echo "==> [master] Generating join command for workers"
  kubeadm token create --print-join-command > /vagrant/join-command.sh
  chmod +x /vagrant/join-command.sh
fi

echo "==> [master] Cluster status:"
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl get nodes || true

echo "==> [master] Done. Join command saved to /vagrant/join-command.sh (shared with host + workers)"
