terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubectl" {
  config_path       = "~/.kube/config"
  load_config_file  = true
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "argocd"
  }
}

##############################################################
# ARGOCD CONFIG
##############################################################
resource "helm_release" "argocd_install" {
  namespace        = "argocd"
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  timeout          = 800

  set {
    name  = "configs.params.server\\.insecure"
    value = true
  }

  depends_on = [
    kubernetes_namespace.argocd_namespace
  ]
}

// Create root-cluster project
resource "kubectl_manifest" "root_cluster_project" {
  yaml_body = file("./applications/argocd/projects/root-cluster.yaml")

  depends_on = [
    helm_release.argocd_install
  ]
}

// Create aroot-cluster application
resource "kubectl_manifest" "root_cluster_application" {
  yaml_body = file("./applications/argocd/applications/root-cluster.yaml")

  depends_on = [
    kubectl_manifest.root_cluster
  ]
}

// Create argo workflow project
resource "kubectl_manifest" "garden_monitor_project" {
  yaml_body = file("./applications/argocd/projects/garden-monitor.yaml")

  depends_on = [
    helm_release.argocd_install
  ]
}

// Create argo workflow application
resource "kubectl_manifest" "garden_monitor_application" {
  yaml_body = file("./applications/argocd/applications/garden-monitor.yaml")

  depends_on = [
    kubectl_manifest.garden_monitor_project
  ]
}