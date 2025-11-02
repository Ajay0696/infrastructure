terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

locals {
  traefik_chart_version = "27.0.2"
  traefik_repo          = "https://traefik.github.io/charts"
}

# ---------------------------------
# Traefik External (Public)
# ---------------------------------
resource "helm_release" "traefik_external" {
  name             = "traefik-external"
  repository       = local.traefik_repo
  chart            = "traefik"
  namespace        = "traefik-external"
  version          = local.traefik_chart_version
  create_namespace = true

  values = [
    file("${path.module}/values/traefikexternal-values.yaml")
  ]
}

# ---------------------------------
# Traefik Internal (Private)
# ---------------------------------
resource "helm_release" "traefik_internal" {
  name             = "traefik-internal"
  repository       = local.traefik_repo
  chart            = "traefik"
  namespace        = "traefik-internal"
  version          = local.traefik_chart_version
  create_namespace = true

  values = [
    file("${path.module}/values/traefikinternal-values.yaml")
  ]
}
