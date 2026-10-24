# ============================================================
# ArgoCD — instalação (Helm) + credencial do repo + Application
# ============================================================
# 1. Instala o ArgoCD no namespace "argocd" (chart oficial argo-cd),
#    com o server exposto via NodePort para acesso local.
# 2. Registra a credencial do repositório privado (se o token for
#    informado via -var argocd_repo_token=...).
# 3. Cria a Application que sincroniza o diretório k8s/ do Git.

resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  # Acesso local por HTTP puro (sem TLS), para abrir a UI no Minikube sem
  # aviso de certificado. Em produção, remover e manter HTTPS.
  set {
    name  = "configs.params.server.insecure"
    value = "true"
  }
}

resource "kubectl_manifest" "argocd_repo_secret" {
  count = var.enable_argocd && var.argocd_repo_token != "" ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: repo-infrastructure
      namespace: argocd
      labels:
        argocd.argoproj.io/secret-type: repository
    stringData:
      type: git
      url: ${var.argocd_repo_url}
      username: ${var.argocd_repo_username}
      password: ${var.argocd_repo_token}
  YAML

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_application" {
  count = var.enable_argocd ? 1 : 0

  yaml_body = templatefile("${path.module}/../argocd/application.yaml", {
    repo_url = var.argocd_repo_url
  })

  depends_on = [kubectl_manifest.argocd_repo_secret]
}
