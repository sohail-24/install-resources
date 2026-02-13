#!/bin/bash
set -euo pipefail

echo "========== INITIALIZING CONTROL PLANE =========="

kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --upload-certs

echo "Setting up kubectl..."

mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

echo "Installing Calico CNI..."

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml

echo "Waiting for nodes..."
sleep 20
kubectl get nodes

echo "========== CONTROL PLANE READY =========="
echo "Now generate worker join command:"
echo "kubeadm token create --print-join-command"
