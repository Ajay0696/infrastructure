#!/bin/bash
set -euo pipefail
exec >> /var/log/k8s-bootstrap.log 2>&1

# ── Variables injected by Terraform templatefile() ────────────────────────────
NAME_PREFIX="${name_prefix}"
REGION="${region}"
NLB_DNS="${nlb_dns}"
K8S_VERSION="${k8s_version}"
POD_CIDR="${pod_cidr}"
SVC_CIDR="${service_cidr}"
API_PORT="${api_server_port}"

echo "=== k8s control plane bootstrap started at $(date) ==="

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

# ── IMDSv2 metadata ───────────────────────────────────────────────────────────
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)
NODE_HOSTNAME=$(hostname)
K8S_FULL=$(kubelet --version | awk '{print $2}')

# ── Check if cluster already initialized ──────────────────────────────────────
INITIALIZED=$(aws ssm get-parameter \
  --name "/$NAME_PREFIX/kubeadm/cluster-initialized" \
  --region "$REGION" 2>/dev/null \
  | jq -r '.Parameter.Value' || echo "false")

if [ "$INITIALIZED" = "true" ]; then
  echo "Cluster exists – joining as additional control plane..."

  CERT_KEY=$(aws ssm get-parameter \
    --name "/$NAME_PREFIX/kubeadm/certificate-key" \
    --with-decryption --region "$REGION" \
    | jq -r '.Parameter.Value')

  JOIN_CMD=$(aws ssm get-parameter \
    --name "/$NAME_PREFIX/kubeadm/controlplane-join-command" \
    --with-decryption --region "$REGION" \
    | jq -r '.Parameter.Value')

  eval "$JOIN_CMD --certificate-key $CERT_KEY --node-name $NODE_HOSTNAME"

  mkdir -p /root/.kube
  cp /etc/kubernetes/admin.conf /root/.kube/config
else
  echo "Initializing cluster for the first time..."

  cat > /tmp/kubeadm-config.yaml <<KCFG
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $PRIVATE_IP
  bindPort: $API_PORT
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  name: $NODE_HOSTNAME
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: $K8S_FULL
controlPlaneEndpoint: "$NLB_DNS:$API_PORT"
networking:
  podSubnet: "$POD_CIDR"
  serviceSubnet: "$SVC_CIDR"
apiServer:
  certSANs:
    - "$NLB_DNS"
    - "$PRIVATE_IP"
    - "127.0.0.1"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
KCFG

  kubeadm init --config /tmp/kubeadm-config.yaml --upload-certs \
    2>&1 | tee /var/log/kubeadm-init.log

  mkdir -p /root/.kube
  cp /etc/kubernetes/admin.conf /root/.kube/config

  # Generate fresh cert upload key (the one from init expires in 2h)
  CERT_KEY=$(kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1)
  JOIN_CMD=$(kubeadm token create --print-join-command 2>/dev/null)

  # Store bootstrap data in SSM (SecureString for sensitive values)
  aws ssm put-parameter \
    --name "/$NAME_PREFIX/kubeadm/cluster-initialized" \
    --value "true" --type String --overwrite --region "$REGION"

  aws ssm put-parameter \
    --name "/$NAME_PREFIX/kubeadm/certificate-key" \
    --value "$CERT_KEY" --type SecureString --overwrite --region "$REGION"

  aws ssm put-parameter \
    --name "/$NAME_PREFIX/kubeadm/worker-join-command" \
    --value "$JOIN_CMD" --type SecureString --overwrite --region "$REGION"

  aws ssm put-parameter \
    --name "/$NAME_PREFIX/kubeadm/controlplane-join-command" \
    --value "$JOIN_CMD --control-plane" --type SecureString --overwrite --region "$REGION"

  # ── Install Calico CNI (pod CIDR must be 192.168.0.0/16) ──────────────────
  kubectl apply -f \
    https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

  echo "=== Cluster initialization complete at $(date) ==="
fi
