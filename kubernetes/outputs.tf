output "kube_context" {
  description = "Contexto Kubernetes usado neste deploy."
  value       = var.kube_context
}

output "acessar_aplicacao" {
  description = "Comando para expor a URL do frontend (Minikube)."
  value       = "minikube service frontend --url"
}

output "acessar_argocd" {
  description = "Comando para expor a URL do ArgoCD (Minikube)."
  value       = "minikube service -n argocd argocd-server --url"
}
