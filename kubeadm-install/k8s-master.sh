#!/bin/bash
set -e

echo "🚀 Kubernetes MASTER Node Setup Started"
echo "======================================="

#--------------------------------------------------
# Root check
#--------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script using:"
  echo "   sudo ./k8s-master.sh"
  exit 1
fi

echo "🖥️  Node Information"
echo "-------------------"
echo "Hostname : $(hostname)"
echo "IP Addr  : $(hostname -I | awk '{print $1}')"
echo



#==================================================
# STEP 1 — System Preparation
#==================================================
echo "🔹 STEP 1: System preparation"

apt update && apt upgrade -y

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

modprobe br_netfilter
echo br_netfilter >/etc/modules-load.d/br_netfilter.conf

cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

echo "✅ STEP 1 completed"
echo

#==================================================
# STEP 2 — Container Runtime (containerd + Docker)
#==================================================
echo "🔹 STEP 2: Installing container runtime"

apt install -y containerd
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
/etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

apt install -y docker.io
systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu || true

# 🔧 Docker group auto refresh (FIX)
echo "🔄 Applying docker group without logout..."
su - ubuntu -c "newgrp docker <<EOF
docker ps >/dev/null 2>&1
EOF"

echo "✅ STEP 2 completed"
echo

#==================================================
# STEP 3 — Kubernetes Components
#==================================================
echo "🔹 STEP 3: Installing Kubernetes components (v1.29)"

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
>/etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

echo "✅ STEP 3 completed"
echo

#==================================================
# NEXT STEPS (AUTOMATIC GUIDANCE)
#==================================================
echo "🎉 Master prerequisites installation completed!"
echo "==============================================="
echo
echo "👉 NEXT: Initialize Kubernetes control plane"
echo
echo "Run the following command on MASTER:"
echo
echo "  sudo kubeadm init --pod-network-cidr=192.168.0.0/16"
echo
echo "After init, run:"
echo
echo "  mkdir -p ~/.kube"
echo "  sudo cp /etc/kubernetes/admin.conf ~/.kube/config"
echo "  sudo chown \$(id -u):\$(id -g) ~/.kube/config"
echo
echo "Verify:"
echo
echo "  kubectl get nodes"
echo
echo "⚠️ Install Calico ONLY after kubeadm init:"
echo
echo "  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml"
echo
echo "📌 Save the 'sudo kubeadm join' command printed after init for worker nodes"
echo
echo "✅ Script finished successfully"
