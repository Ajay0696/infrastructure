To create VPC, EKS, navigate to 01-infra directory, and run tfm commands  

| tfm init  
| tfm plan  
| tfm apply --auto-approve  

To get kubeconfig

| aws eks update-kubeconfig --region ap-south-1 --name ajayshandbook-eks


helm install traefik-external traefik/traefik --namespace=traefik-exxternal --create-namespace -f values/traefikexternal-values.yaml

helm upgrade --install traefik-external traefik/traefik --namespace=traefik-external --create-namespace -f values/traefikexternal-values.yaml

helm install traefik-internal traefik/traefik --namespace=traefik-internal --create-namespace -f values/traefikinternal-values.yaml

helm upgrade --install traefik-internal traefik/traefik --namespace=traefik-internal --create-namespace -f values/traefikinternal-values.yaml



Remember:

ports.web.exposedPort: 80 and ports.websecure.exposedPort: 443 are the Service ports.

ports.web.nodePort: 32080 and ports.websecure.nodePort: 32443 are the NodePorts you access on the node IPs.