#!/bin/bash
set -e

echo "=== Initializing Kubernetes Control Plane ==="

kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --upload-certs

echo "=== Setting up kubectl for root ==="

mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

unset KUBECONFIG

kubectl get nodes

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml


echo "=== Control Plane initialized ==="
echo "Now apply Calico usind this command manually."
