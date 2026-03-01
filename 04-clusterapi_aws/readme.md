
# Cluster API (CAPA) - AWS Quick Reference

Docs: https://cluster-api.sigs.k8s.io/user/quick-start

---

## One-time Setup

### Install clusterctl
```bash
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.12.3/clusterctl-linux-amd64 -o clusterctl
sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
clusterctl version
```

### Install clusterawsadm
```bash
curl -L https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/v2.10.1/clusterawsadm-linux-amd64 -o clusterawsadm
chmod +x clusterawsadm
sudo mv clusterawsadm /usr/local/bin
clusterawsadm version
```

### Bootstrap IAM (run once per AWS account)
```bash
aws-export
clusterawsadm bootstrap iam create-cloudformation-stack
```
Output:
```
❯ clusterawsadm bootstrap iam create-cloudformation-stack
Attempting to create AWS CloudFormation stack cluster-api-provider-aws-sigs-k8s-io
SDK 2026/03/01 21:00:07 DEBUG attempting waiter request, attempt count: 1
SDK 2026/03/01 21:00:37 DEBUG attempting waiter request, attempt count: 2
SDK 2026/03/01 21:01:14 DEBUG attempting waiter request, attempt count: 3
SDK 2026/03/01 21:02:08 DEBUG attempting waiter request, attempt count: 4
SDK 2026/03/01 21:03:49 DEBUG attempting waiter request, attempt count: 5

Following resources are in the stack: 

Resource                  |Type                                                                                  |Status
AWS::IAM::InstanceProfile |control-plane.cluster-api-provider-aws.sigs.k8s.io                                    |CREATE_COMPLETE
AWS::IAM::InstanceProfile |controllers.cluster-api-provider-aws.sigs.k8s.io                                      |CREATE_COMPLETE
AWS::IAM::InstanceProfile |nodes.cluster-api-provider-aws.sigs.k8s.io                                            |CREATE_COMPLETE
AWS::IAM::ManagedPolicy   |arn:aws:iam::156041413322:policy/control-plane.cluster-api-provider-aws.sigs.k8s.io   |CREATE_COMPLETE
AWS::IAM::ManagedPolicy   |arn:aws:iam::156041413322:policy/nodes.cluster-api-provider-aws.sigs.k8s.io           |CREATE_COMPLETE
AWS::IAM::ManagedPolicy   |arn:aws:iam::156041413322:policy/controllers.cluster-api-provider-aws.sigs.k8s.io     |CREATE_COMPLETE
AWS::IAM::ManagedPolicy   |arn:aws:iam::156041413322:policy/controllers-eks.cluster-api-provider-aws.sigs.k8s.io |CREATE_COMPLETE
AWS::IAM::Role            |control-plane.cluster-api-provider-aws.sigs.k8s.io                                    |CREATE_COMPLETE
AWS::IAM::Role            |controllers.cluster-api-provider-aws.sigs.k8s.io                                      |CREATE_COMPLETE
AWS::IAM::Role            |eks-controlplane.cluster-api-provider-aws.sigs.k8s.io                                 |CREATE_COMPLETE
AWS::IAM::Role            |nodes.cluster-api-provider-aws.sigs.k8s.io                                            |CREATE_COMPLETE


```

---

## Create Cluster

```bash
# 1. Start kind management cluster
kind create cluster

# 2. Export AWS credentials
aws-export

# 3. Initialize CAPA on the management cluster
clusterctl init --infrastructure aws

Output:

```
❯ k get ns
NAME                 STATUS   AGE
default              Active   121d
kube-node-lease      Active   121d
kube-public          Active   121d
kube-system          Active   121d
local-path-storage   Active   121d
❯ clusterctl init --infrastructure aws
Fetching providers
Installing cert-manager version="v1.19.3"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int32"
Waiting for cert-manager to be available...
spec.privateKey.rotationPolicy: In cert-manager >= v1.18.0, the default value changed from `Never` to `Always`.
Installing provider="cluster-api" version="v1.12.3" targetNamespace="capi-system"
spec.privateKey.rotationPolicy: In cert-manager >= v1.18.0, the default value changed from `Never` to `Always`.
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int32"
unrecognized format "int64"
Installing provider="bootstrap-kubeadm" version="v1.12.3" targetNamespace="capi-kubeadm-bootstrap-system"
spec.privateKey.rotationPolicy: In cert-manager >= v1.18.0, the default value changed from `Never` to `Always`.
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int32"
Installing provider="control-plane-kubeadm" version="v1.12.3" targetNamespace="capi-kubeadm-control-plane-system"
spec.privateKey.rotationPolicy: In cert-manager >= v1.18.0, the default value changed from `Never` to `Always`.
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int32"
Installing provider="infrastructure-aws" version="v2.10.2" targetNamespace="capa-system"
spec.privateKey.rotationPolicy: In cert-manager >= v1.18.0, the default value changed from `Never` to `Always`.
unrecognized format "int32"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int32"
unrecognized format "int32"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int32"
unrecognized format "int64"
unrecognized format "int64"
unrecognized format "int32"
unrecognized format "int32"
unrecognized format "int32"
spec.template.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].key: node-role.kubernetes.io/master is use "node-role.kubernetes.io/control-plane" instead

Your management cluster has been initialized successfully!

You can now create your first workload cluster by running the following:

  clusterctl generate cluster [name] --kubernetes-version [version] | kubectl apply -f -

❯ k get ns
NAME                                STATUS   AGE
capa-system                         Active   17s
capi-kubeadm-bootstrap-system       Active   18s
capi-kubeadm-control-plane-system   Active   17s
capi-system                         Active   18s
cert-manager                        Active   34s
default                             Active   121d
kube-node-lease                     Active   121d
kube-public                         Active   121d
kube-system                         Active   121d
local-path-storage                  Active   121d
╭─ ~/work/learn/clusterapi ▓▒░                                                                                                                      ░▒▓ ✔  at 21:09:11 
╰─ 

```


# 4. Set cluster variables
export AWS_SSH_KEY_NAME=ajayshandbook-key
export AWS_CONTROL_PLANE_MACHINE_TYPE=t3a.medium
export AWS_NODE_MACHINE_TYPE=t3a.medium

# 5. Generate cluster manifest
clusterctl generate cluster capi-quickstart \
  --kubernetes-version v1.29.0 \
  --control-plane-machine-count=1 \
  --worker-machine-count=1 \
  > capi-quickstart.yaml

# 6. (Optional) Use public subnets only to avoid NAT Gateway costs
# Edit capi-quickstart.yaml — find the AWSCluster resource and add/replace the network section:
#
# spec:
#   network:
#     subnets:
#       - availabilityZone: us-east-2a
#         cidrBlock: 10.0.0.0/24
#         isPublic: true
#
# Only defining public subnets (isPublic: true) tells CAPA not to create NAT Gateways.
# Nodes will get public IPs directly. Fine for dev/learning, not recommended for production.

kubectl apply -f capi-quickstart.yaml

# 6. Watch cluster status
clusterctl describe cluster capi-quickstart
kubectl get cluster
kubectl get kubeadmcontrolplane
```

```
# 1. Get fresh SSO credentials
aws-export

# 2. Encode them
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile)

# 3. Patch the CAPA credentials secret
kubectl -n capa-system patch secret capa-manager-bootstrap-credentials \
  --type='json' \
  -p="[{\"op\": \"replace\", \"path\": \"/data/credentials\", \"value\": \"${AWS_B64ENCODED_CREDENTIALS}\"}]"

# 4. Restart the CAPA controller to pick up new credentials
kubectl -n capa-system rollout restart deployment capa-controller-manager

# 5. Watch it recover
clusterctl describe cluster capi-quickstart

```


### Access the workload cluster
```bash
clusterctl get kubeconfig capi-quickstart > workload-kubeconfig.yaml
```

---

## Delete Cluster (follow order to avoid orphaned AWS resources)

```bash
# 1. Delete workload cluster FIRST — this cleans up all AWS resources (EC2, VPC, ELB)
kubectl delete cluster capi-quickstart

# 2. Confirm all AWS resources are gone
kubectl get cluster   # should return "No resources found"

# 3. Verify no EC2 instances remain in AWS
aws ec2 describe-instances \
  --filters "Name=tag:sigs.k8s.io/cluster-api-provider-aws/cluster/capi-quickstart,Values=owned" \
  --query "Reservations[*].Instances[*].InstanceId"

# 4. Delete the kind management cluster last
kind delete cluster

# 5. Unset AWS credentials
aws-unset
```

> WARNING: Never delete the kind cluster before running `kubectl delete cluster`.
> The CAPA controller will be gone and AWS resources will be orphaned, costing you money.

---

## Aliases (in ~/.zshrc)
- `aws-export` — SSO login + export all AWS credentials
- `aws-unset`  — unset all AWS credentials
