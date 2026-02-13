#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: ./worker-join.sh '<kubeadm join command>'"
  exit 1
fi

echo "========== JOINING WORKER TO CLUSTER =========="

eval "$1"

echo "========== WORKER JOINED =========="
