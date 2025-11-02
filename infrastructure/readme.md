To create VPC, EKS, navigate to 01-infra directory, and run tfm commands  

| tfm init  
| tfm plan  
| tfm apply --auto-approve  

To get kubeconfig

| aws eks update-kubeconfig --region ap-south-1 --name ajayshandbook-eks

