terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
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

resource "kubernetes_namespace" "nginx_namespace" {
  metadata {
    name = "ingress-nginx"
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
# ARGOCD CONFIG
##############################################################
resource "kubectl_manifest" "argocd_install" {
  for_each            = data.kubectl_file_documents.argocd_install_config.manifests
  yaml_body           = each.value
  override_namespace  = "argocd"

  depends_on = [
    kubernetes_namespace.argocd_namespace,
    kubernetes_namespace.nginx_namespace,
    kubernetes_namespace.argo_namespace
  ]
}

// Create nginx project
resource "kubectl_manifest" "nginx_project" {
  yaml_body = file("./applications/argocd/projects/nginx.yaml")

  depends_on = [
    kubectl_manifest.argocd_install
  ]
}

// Create nginx application
resource "kubectl_manifest" "nginx_app" {
  yaml_body = file("./applications/argocd/applications/nginx.yaml")

  depends_on = [
    kubectl_manifest.nginx_project
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