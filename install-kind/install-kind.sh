#!/bin/bash
set -e
set -o pipefail

echo "🚀 Starting installation of Docker, Kind, and kubectl..."

# ----------------------------
# Detect Architecture
# ----------------------------
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
  ARCH="arm64"
elif [ "$ARCH" = "x86_64" ]; then
  ARCH="amd64"
else
  echo "❌ Unsupported architecture: $ARCH"
  exit 1
fi
echo "🧠 Detected architecture: $ARCH"

# ----------------------------
# 1. Install Docker
# ----------------------------
if ! command -v docker &>/dev/null; then
  echo "📦 Installing Docker..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg lsb-release docker.io
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker "$USER"
  echo "✅ Docker installed and user added to docker group."
else
  echo "✅ Docker is already installed."
fi

# ----------------------------
# 2. Install Kind
# ----------------------------
if ! command -v kind &>/dev/null; then
  echo "📦 Installing Kind..."
  curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-${ARCH}"
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
  echo "✅ Kind installed successfully."
else
  echo "✅ Kind is already installed."
fi

# ----------------------------
# 3. Install kubectl
# ----------------------------
if ! command -v kubectl &>/dev/null; then
  echo "📦 Installing kubectl (latest stable version)..."
  VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  curl -LO "https://dl.k8s.io/release/${VERSION}/bin/linux/${ARCH}/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl
  echo "✅ kubectl installed successfully."
else
  echo "✅ kubectl is already installed."
fi

# ----------------------------
# 4. Verify Installations
# ----------------------------
echo
echo "🔍 Installed Versions:"
docker --version || echo "Docker not found!"
kind --version || echo "Kind not found!"
kubectl version --client || echo "kubectl not found!"

echo
echo "🎉 Installation complete!"
echo "👉 To create a cluster, run:"
echo "   kind create cluster --config kind-config.yaml --name my-kind-cluster"
echo "💡 Then verify with: kubectl get nodes"

