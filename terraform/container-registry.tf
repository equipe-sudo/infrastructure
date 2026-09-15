# ============================================
# Container images — GitHub Container Registry (GHCR)
# ============================================
# As imagens são publicadas pelos workflows do GitHub Actions.
# O Terraform não tenta criar repositórios de container na OCI.

locals {
  ghcr_registry = "ghcr.io/equipe-sudo"

  legacy_container_repos = {
    backend  = "equipe-sudo-backend"
    frontend = "equipe-sudo-frontend"
  }
}

# Mantidos no estado para evitar recriação ou destruição acidental. As imagens
# da aplicação são publicadas no GHCR pelos workflows de CI/CD.
resource "oci_artifacts_container_repository" "repos" {
  for_each       = local.legacy_container_repos
  compartment_id = var.oci_tenancy_ocid
  display_name   = "${var.tag_project}/${each.value}"
  is_immutable   = false
  is_public      = false

  lifecycle {
    prevent_destroy = true
  }

  freeform_tags = local.common_tags
}

# Outputs para uso em CI/CD e deploy
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
