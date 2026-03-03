apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  labels:
    ccm: external
    csi: external
  name: ${cluster_name}
  namespace: default
spec:
  clusterNetwork:
    pods:
      cidrBlocks:
      - 192.168.0.0/16
  controlPlaneRef:
    apiVersion: controlplane.cluster.x-k8s.io/v1beta1
    kind: KubeadmControlPlane
    name: ${cluster_name}-control-plane
  infrastructureRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1beta2
    kind: AWSCluster
    name: ${cluster_name}
---
apiVersion: infrastructure.cluster.x-k8s.io/v1beta2
kind: AWSCluster
metadata:
  name: ${cluster_name}
  namespace: default
spec:
  controlPlaneLoadBalancer:
    healthCheckProtocol: HTTPS
    loadBalancerType: nlb
  region: ${region}
  sshKeyName: ${ssh_key_name}
  network:
    vpc:
      id: ${vpc_id}
    subnets:
%{ for subnet_id in subnet_ids ~}
      - id: ${subnet_id}
%{ endfor ~}
---
apiVersion: controlplane.cluster.x-k8s.io/v1beta1
kind: KubeadmControlPlane
metadata:
  name: ${cluster_name}-control-plane
  namespace: default
spec:
  kubeadmConfigSpec:
    clusterConfiguration:
      apiServer:
        extraArgs:
          cloud-provider: external
      controllerManager:
        extraArgs:
          cloud-provider: external
    initConfiguration:
      nodeRegistration:
        kubeletExtraArgs:
          cloud-provider: external
        name: '{{ ds.meta_data.local_hostname }}'
    joinConfiguration:
      nodeRegistration:
        kubeletExtraArgs:
          cloud-provider: external
        name: '{{ ds.meta_data.local_hostname }}'
  machineTemplate:
    infrastructureRef:
      apiVersion: infrastructure.cluster.x-k8s.io/v1beta2
      kind: AWSMachineTemplate
      name: ${cluster_name}-control-plane
  replicas: ${control_plane_count}
  version: ${kubernetes_version}
---
apiVersion: infrastructure.cluster.x-k8s.io/v1beta2
kind: AWSMachineTemplate
metadata:
  name: ${cluster_name}-control-plane
  namespace: default
spec:
  template:
    spec:
      iamInstanceProfile: control-plane.cluster-api-provider-aws.sigs.k8s.io
      instanceType: ${control_plane_instance}
      sshKeyName: ${ssh_key_name}
      publicIP: true
---
apiVersion: cluster.x-k8s.io/v1beta1
kind: MachineDeployment
metadata:
  name: ${cluster_name}-md-0
  namespace: default
spec:
  clusterName: ${cluster_name}
  replicas: ${worker_count}
  selector:
    matchLabels: {}
  template:
    spec:
      bootstrap:
        configRef:
          apiVersion: bootstrap.cluster.x-k8s.io/v1beta1
          kind: KubeadmConfigTemplate
          name: ${cluster_name}-md-0
      clusterName: ${cluster_name}
      infrastructureRef:
        apiVersion: infrastructure.cluster.x-k8s.io/v1beta2
        kind: AWSMachineTemplate
        name: ${cluster_name}-md-0
      version: ${kubernetes_version}
---
apiVersion: infrastructure.cluster.x-k8s.io/v1beta2
kind: AWSMachineTemplate
metadata:
  name: ${cluster_name}-md-0
  namespace: default
spec:
  template:
    spec:
      iamInstanceProfile: nodes.cluster-api-provider-aws.sigs.k8s.io
      instanceType: ${worker_instance}
      sshKeyName: ${ssh_key_name}
      publicIP: true
---
apiVersion: bootstrap.cluster.x-k8s.io/v1beta1
kind: KubeadmConfigTemplate
metadata:
  name: ${cluster_name}-md-0
  namespace: default
spec:
  template:
    spec:
      joinConfiguration:
        nodeRegistration:
          kubeletExtraArgs:
            cloud-provider: external
          name: '{{ ds.meta_data.local_hostname }}'
