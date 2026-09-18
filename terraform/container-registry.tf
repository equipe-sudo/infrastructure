# ============================================
# Container images — GitHub Container Registry (GHCR)
# ============================================
# As imagens são publicadas pelos workflows do GitHub Actions em
# ghcr.io/equipe-sudo/. O Terraform não gerencia mais repositórios de
# container na OCI (OCIR).
#
# NOTA DE MIGRAÇÃO
# ----------------
# Os recursos `oci_artifacts_container_repository.repos["backend"|"frontend"]`
# (OCIR) foram removidos deste arquivo: a tenancy é Free Tier e o serviço
# Artifacts Container Registry não é suportado (erro 403 FREE_TIER_NOT_SUPPORTED),
# o que fazia o `terraform plan` falhar no refresh. Eles também não são mais
# necessários, pois as imagens passaram para o GHCR.
#
# Ajuste único necessário no estado (executar uma vez):
#
#   terraform state rm \
#     'oci_artifacts_container_repository.repos["backend"]' \
#     'oci_artifacts_container_repository.repos["frontend"]'
#
# Sem esse passo, o Terraform tentaria ler/remover recursos que a API recusa.

locals {
  ghcr_registry = "ghcr.io/equipe-sudo"
}

output "container_registry_url" {
  description = "URL base do GitHub Container Registry"
  value       = local.ghcr_registry
}

output "backend_image" {
  description = "Imagem completa do backend"
  value       = "${local.ghcr_registry}/equipe-sudo-backend:latest"
}

output "frontend_image" {
  description = "Imagem completa do frontend"
  value       = "${local.ghcr_registry}/equipe-sudo-frontend:latest"
}
