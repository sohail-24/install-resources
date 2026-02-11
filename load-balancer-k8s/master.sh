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

echo "=== Control Plane initialized ==="
echo "Now apply Calico manually."
