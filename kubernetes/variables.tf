variable "kubeconfig_path" {
  description = "Caminho do kubeconfig. Aponte para o kubeconfig do cluster na nuvem quando migrar."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Contexto kubectl a usar (ex.: 'minikube' local; o nome do contexto OKE/EKS na nuvem)."
  type        = string
  default     = "minikube"
}

variable "argocd_repo_token" {
  description = "Token (PAT) de leitura do repositório privado, usado pelo ArgoCD para clonar o Git. Opcional."
  type        = string
  sensitive   = true
  default     = ""
}
