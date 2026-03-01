#!/bin/bash
set -euo pipefail
exec >> /var/log/k8s-bootstrap.log 2>&1

# ── Variables injected by Terraform templatefile() ────────────────────────────
NAME_PREFIX="${name_prefix}"
REGION="${region}"
K8S_VERSION="${k8s_version}"

echo "=== k8s worker bootstrap started at $(date) ==="

# ── SSM agent ─────────────────────────────────────────────────────────────────
# Ubuntu 22.04 on AWS ships the SSM agent as a snap; ensure it is running.
snap start amazon-ssm-agent || true
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true

# ── Kernel modules ────────────────────────────────────────────────────────────
cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# ── Packages ──────────────────────────────────────────────────────────────────
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gpg awscli jq conntrack

# ── containerd ────────────────────────────────────────────────────────────────
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y containerd.io

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# ── kubeadm / kubelet / kubectl ───────────────────────────────────────────────
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/Release.key" \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

NODE_HOSTNAME=$(hostname)

# ── Wait for cluster and retrieve join command from SSM ───────────────────────
echo "Waiting for control plane to publish join command..."
JOIN_CMD=""
for i in $(seq 1 40); do
  JOIN_CMD=$(aws ssm get-parameter \
    --name "/$NAME_PREFIX/kubeadm/worker-join-command" \
    --with-decryption --region "$REGION" 2>/dev/null \
    | jq -r '.Parameter.Value') && [ -n "$JOIN_CMD" ] && break
  echo "  Attempt $i/40: not ready, retrying in 15s..."
  sleep 15
done

if [ -z "$JOIN_CMD" ]; then
  echo "ERROR: Could not retrieve join command after 40 attempts."
  exit 1
fi

eval "$JOIN_CMD --node-name $NODE_HOSTNAME"

echo "=== Worker joined cluster at $(date) ==="
