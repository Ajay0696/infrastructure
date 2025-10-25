To create EKS infra in public subnets, it takes `09` minutes for eks and `03` minutes for node groups. Destruction will take `` minutes
```
tfm init
tfm apply --auto-approve
```

To get kubeconfig to local device
```
aws eks update-kubeconfig --region ap-south-1 --name development-eks-dev
```

Verify you have access to read-write `k auth can-i "*" "*"` it will respond `yes`
```
k get nodes
```

**********************************************************************************


