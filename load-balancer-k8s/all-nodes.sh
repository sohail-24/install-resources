#!/bin/bash
set -e

echo "=== Updating system ==="
apt update && apt upgrade -y

echo "=== Disabling swap ==="
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "=== Loading kernel modules ==="
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo "=== Setting sysctl params ==="
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

echo "=== Installing containerd ==="
apt install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

echo "=== Installing Kubernetes packages ==="
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
| tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl

apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet
systemctl start kubelet

echo "=== Common setup completed successfully ==="
