#!/bin/bash
set -e

echo "🚀 Installing Kubernetes WORKER node..."

#--------------------------------------------------
# Root check
#--------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root: sudo -i"
  exit 1
fi

#--------------------------------------------------
# Update system
#--------------------------------------------------
apt update && apt upgrade -y

#--------------------------------------------------
# Disable swap
#--------------------------------------------------
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

#--------------------------------------------------
# Kernel modules & sysctl
#--------------------------------------------------
modprobe br_netfilter
echo br_netfilter >/etc/modules-load.d/br_netfilter.conf

cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

#--------------------------------------------------
# Install containerd
#--------------------------------------------------
apt install -y containerd
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
/etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

#--------------------------------------------------
# Install Docker
#--------------------------------------------------
apt install -y docker.io
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu || true

#--------------------------------------------------
# Install Kubernetes components
#--------------------------------------------------
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
> /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

echo "✅ Worker prerequisites installed"
echo "👉 Wait for kubeadm join command from master"
echo "sudo kubeadm join <MASTER-IP>:6443 --token <TOKEN> \
--discovery-token-ca-cert-hash sha256:<HASH>"
