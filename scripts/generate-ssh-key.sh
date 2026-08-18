#!/usr/bin/env bash
# Generates a dedicated keypair for the cluster VMs (EC2-style: ssh -i key ip)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_PATH="$DIR/keys/k8s-key"

if [ -f "$KEY_PATH" ]; then
  echo "Key already exists at $KEY_PATH — skipping generation."
  exit 0
fi

mkdir -p "$DIR/keys"
ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "k8s-vagrant-cluster"
chmod 600 "$KEY_PATH"
echo ""
echo "✅ Keypair generated:"
echo "   Private key: $KEY_PATH"
echo "   Public key : $KEY_PATH.pub"
echo ""
echo "After 'vagrant up' finishes, connect like this (EC2 style):"
echo "   ssh -i $KEY_PATH vagrant@192.168.56.10   # master"
echo "   ssh -i $KEY_PATH vagrant@192.168.56.11   # worker1"
