# stable · ajayshandbook · us-east-2 · mgmt-cluster

Kubernetes management cluster built with **kubeadm** on AWS Spot instances.

| | |
|---|---|
| **Environment** | `stable` (production) |
| **Project** | `ajayshandbook` |
| **Region** | `us-east-2` |
| **Cluster name** | `mgmt-cluster` |
| **Domain** | `ajayshandbook.com` |
| **AWS Profile** | `awsadmin` |

## Architecture

```
                        Internet
                            │
              ┌─────────────┴─────────────┐
              │        Public Subnets      │  10.0.1.0/24, 10.0.2.0/24
              │                           │
              │  ┌──────────────────────┐ │
              │  │  Public NLB :6443    │ │  api.mgmt-cluster.us-east-2.ajayshandbook.com
              │  └──────────────────────┘ │
              │  ┌──────────────────────┐ │
              │  │  Control Plane ASG   │ │  1 node (t3a.medium spot), max 3
              │  └──────────────────────┘ │
              │  ┌──────────────────────┐ │
              │  │   Worker Node ASG    │ │  2 nodes (t3a.medium spot), max 5
              │  └──────────────────────┘ │
              └───────────────────────────┘
```

All nodes are in public subnets with public IPs — SSH directly with the key pair.

**DNS pattern:** `<service>.mgmt-cluster.us-east-2.ajayshandbook.com`

---

## Prerequisites

| Tool | Version |
|---|---|
| Terraform | >= 1.6 |
| AWS CLI | v2 |
| kubectl | any recent |

### 1. Configure AWS profile

```bash
aws configure --profile awsadmin
# or SSO:
aws sso login --profile awsadmin
```

Verify:
```bash
aws sts get-caller-identity --profile awsadmin
```

### 2. Create EC2 key pair

```bash
aws ec2 create-key-pair \
  --key-name ajayshandbook-key \
  --region us-east-2 \
  --profile awsadmin \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/ajayshandbook-key.pem

chmod 600 ~/.ssh/ajayshandbook-key.pem
```

---

## Deploy

```bash
cd 03-infrastructure/stable_ajayshandbook_us-east-2_mgmt-cluster

terraform init
terraform plan
terraform apply
```

Note the outputs when apply completes:

```
nlb_dns_name             = "stable-ajbk-mgmt-api-xxxx.elb.us-east-2.amazonaws.com"
nat_bastion_public_ip    = "3.x.x.x"
nat_bastion_instance_id  = "i-xxxxxxxxxxxxxxxxx"
controlplane_asg_name    = "stable_us-east-2_ajayshandbook_controlplane-asg"
worker_asg_name          = "stable_us-east-2_ajayshandbook_worker-asg"
```

---

## Access Nodes

All nodes are in public subnets with public IPs — SSH directly.

```bash
# Get node public IPs
aws ec2 describe-instances \
  --region us-east-2 --profile awsadmin \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[PublicIpAddress,Tags[?Key==`Role`].Value|[0],InstanceId]' \
  --output table

# SSH directly to any node
ssh -i ~/.ssh/ajayshandbook-key.pem ubuntu@<public-ip>
```

---

## Configure kubectl

The control plane bootstrap takes ~5 minutes after the instance starts.

### 1. Wait for cluster to be ready

```bash
aws ssm get-parameter \
  --name "/stable_us-east-2_ajayshandbook/kubeadm/cluster-initialized" \
  --region us-east-2 \
  --profile awsadmin \
  --query 'Parameter.Value' \
  --output text
# Returns "true" when ready
```

### 2. Copy kubeconfig via bastion

```bash
scp -i ~/.ssh/ajayshandbook-key.pem \
  -o "ProxyJump ubuntu@<nat_bastion_public_ip>" \
  ubuntu@<controlplane-private-ip>:/etc/kubernetes/admin.conf \
  ~/.kube/ajayshandbook-mgmt.yaml
```

Or via SSM (copy-paste from the session):
```bash
aws ssm start-session --target <controlplane-instance-id> \
  --region us-east-2 --profile awsadmin
# Inside the session:
sudo cat /etc/kubernetes/admin.conf
```

### 3. Update the server address

Open `~/.kube/ajayshandbook-mgmt.yaml` and change the `server` field to the NLB DNS:

```yaml
# Before:
server: https://10.0.10.x:6443

# After:
server: https://api.mgmt-cluster.us-east-2.ajayshandbook.com:6443
```

### 4. Use the cluster

```bash
export KUBECONFIG=~/.kube/ajayshandbook-mgmt.yaml
kubectl get nodes
kubectl get pods -n kube-system
```

Expected output:
```
NAME            STATUS   ROLES           AGE   VERSION
ip-10-0-10-x    Ready    control-plane   10m   v1.31.x
ip-10-0-10-y    Ready    <none>          8m    v1.31.x
ip-10-0-11-z    Ready    <none>          8m    v1.31.x
```

---

## Adding Addon DNS Records

When you deploy an addon that exposes a LoadBalancer service (Grafana, Prometheus, ArgoCD, etc.):

### 1. Get the addon's AWS Load Balancer hostname

```bash
kubectl get svc -n monitoring grafana \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# → abc123.us-east-2.elb.amazonaws.com
```

### 2. Add the entry to `locals.tf`

```hcl
addon_dns_records = {
  "grafana" = "abc123.us-east-2.elb.amazonaws.com"
}
```

This creates: `grafana.mgmt-cluster.us-east-2.ajayshandbook.com`

### 3. Apply

```bash
terraform apply
```

The DNS record is live within seconds. Repeat for each addon.

**Naming pattern:**
```
<addon>.mgmt-cluster.us-east-2.ajayshandbook.com
```

| Addon | Example URL |
|---|---|
| Grafana | `grafana.mgmt-cluster.us-east-2.ajayshandbook.com` |
| Prometheus | `prometheus.mgmt-cluster.us-east-2.ajayshandbook.com` |
| AlertManager | `alertmanager.mgmt-cluster.us-east-2.ajayshandbook.com` |
| ArgoCD | `argocd.mgmt-cluster.us-east-2.ajayshandbook.com` |

---

## Scaling

**Scale workers manually:**
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name stable_us-east-2_ajayshandbook_worker-asg \
  --desired-capacity 4 \
  --region us-east-2 \
  --profile awsadmin
```

**Cluster Autoscaler** is pre-configured via ASG tags. Deploy it into the cluster to enable automatic scaling between `worker_min` and `worker_max` (defined in `locals.tf`).

---

## Resource Naming Convention

All AWS resources follow the pattern:

```
<environment>_<region>_<project>_<resource>
```

Examples:
```
stable_us-east-2_ajayshandbook_vpc
stable_us-east-2_ajayshandbook_controlplane-asg
stable_us-east-2_ajayshandbook_nat-bastion
```

---

## Spot Instance Notes

All nodes run on Spot instances (`t3a.medium`). If a spot instance is reclaimed:

- **Workers**: the ASG automatically replaces them; they re-join the cluster via SSM join command.
- **Control plane**: the replacement node re-joins using the SSM-stored join token. However, since etcd data lives on local disk, **a control plane replacement resets cluster state**. For production, attach a dedicated EBS volume to `/var/lib/etcd` and re-attach it on replacement.

---

## Troubleshooting

```bash
# View bootstrap logs on any node (via SSM session or bastion SSH)
sudo tail -f /var/log/k8s-bootstrap.log
sudo tail -f /var/log/kubeadm-init.log   # control plane only

# Check SSM bootstrap state
aws ssm get-parameter \
  --name "/stable_us-east-2_ajayshandbook/kubeadm/cluster-initialized" \
  --profile awsadmin --region us-east-2

# List all SSM parameters for this cluster
aws ssm get-parameters-by-path \
  --path "/stable_us-east-2_ajayshandbook/" \
  --profile awsadmin --region us-east-2 \
  --query 'Parameters[].Name'

# Re-generate a worker join token (if expired after 24h)
# Run inside a control plane node (via SSM or bastion):
kubeadm token create --print-join-command
# then update SSM:
aws ssm put-parameter \
  --name "/stable_us-east-2_ajayshandbook/kubeadm/worker-join-command" \
  --value "<new-join-command>" \
  --type SecureString --overwrite \
  --region us-east-2 --profile awsadmin
```

---

## Teardown

```bash
terraform destroy
```

> SSM parameters created by the bootstrap scripts are **not** managed by Terraform.
> Delete them manually if needed:
> ```bash
> aws ssm delete-parameters-by-path \
>   --path "/stable_us-east-2_ajayshandbook/" \
>   --region us-east-2 --profile awsadmin
> ```
