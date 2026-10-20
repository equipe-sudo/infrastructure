# ============================================================
# Terraform — deploy do CyberVegas no Kubernetes (portável)
# ============================================================
# Para rodar local: kube_context = "minikube".
# Para ir à nuvem: troque kube_context (e kubeconfig_path) para o
# contexto do cluster (OKE/EKS/etc.) e aponte as imagens para o
# registry. Nenhum manifest precisa mudar.
terraform {
  required_version = ">= 1.5"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

provider "kubectl" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context
  }
}
