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

variable "enable_argocd" {
  description = "Instala o ArgoCD e cria a Application. Com false, os manifestos são aplicados apenas pelo Terraform (a aplicação sobe igual)."
  type        = bool
  default     = true
}

variable "argocd_repo_url" {
  description = "URL do repositório Git usado pelo ArgoCD. Aponte para o seu fork caso não tenha acesso ao repositório da equipe."
  type        = string
  default     = "https://github.com/equipe-sudo/infrastructure"
}

variable "argocd_repo_username" {
  description = "Usuário do Git para o ArgoCD (para PAT do GitHub, use o seu usuário)."
  type        = string
  default     = "kolpzs"
}

variable "argocd_repo_token" {
  description = "Token (PAT) de leitura do repositório privado, usado pelo ArgoCD para clonar o Git. Opcional."
  type        = string
  sensitive   = true
  default     = ""
}
