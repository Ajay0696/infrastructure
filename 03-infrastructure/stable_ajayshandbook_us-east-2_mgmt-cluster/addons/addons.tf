terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

provider "helm" {
  kubernetes = {
    # config_path = "/home/ajay/work/github_repos/infrastructure/03-infrastructure/stable_ajayshandbook_us-east-2_mgmt-cluster/mgmt-cluster-kubeconfig.conf"
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = "traefik"
  create_namespace = true
  repository       = "https://helm.traefik.io/traefik"
  chart            = "traefik"
  version          = "39.0.2"

  values = [file("${path.module}/values/traefikexternal-values.yaml")]
}

resource "helm_release" "argo_cd" {
  name             = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.9.0"
  wait             = true

  values = [file("${path.module}/values/argocd-values.yaml")]
}
