terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }

  backend "local" {
    path = "/mnt/usb/tfstate/terraform.tfstate"
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

data "kubectl_file_documents" "argocd_install_config" {
    content = file("./applications/argocd/deploy.yaml")
}

resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "traefik_namespace" {
  metadata {
    name = "traefik"
  }
}

resource "kubernetes_namespace" "argo_namespace" {
  metadata {
    name = "argo"
  }
}

resource "kubernetes_namespace" "kubegres_system_namespace" {
  metadata {
    name = "kubegres-system"
  }
}

resource "kubernetes_namespace" "gardenmonitor_namespace" {
  metadata {
    name = "gardenmonitor"
  }
}

##############################################################
# TRAEFIK CONFIG
##############################################################
resource "helm_release" "traefik" {
  name       = "traefik"

  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"

  set {
    name  = "namespace"
    value = "traefik"
  }
}

##############################################################
# ARGOCD CONFIG
##############################################################
resource "kubectl_manifest" "argocd_install" {
  for_each            = data.kubectl_file_documents.argocd_install_config.manifests
  yaml_body           = each.value
  override_namespace  = "argocd"

  depends_on = [
    kubernetes_namespace.argocd_namespace,
    kubernetes_namespace.argo_namespace
  ]
}

// Create argo workflow project
resource "kubectl_manifest" "argo_workflow_project" {
  yaml_body = file("./applications/argocd/projects/argo-workflow.yaml")

  depends_on = [
    kubectl_manifest.argocd_install
  ]
}

// Create argo workflow application
resource "kubectl_manifest" "argo_workflow_app" {
  yaml_body = file("./applications/argocd/applications/argo-workflow.yaml")

  depends_on = [
    kubectl_manifest.argo_workflow_project
  ]
}