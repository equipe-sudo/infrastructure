# ============================================
# Terraform — OCI Container Registry (OCIR)
# ============================================
# OCIR é GRATUITO no Always Free — armazena imagens Docker
# Namespace: grhkdi3glvat (obtido via: oci os ns get --profile KOLPZS)
# URL: gru.ocir.io/grhkdi3glvat/<repo>:<tag>

locals {
  ocir_namespace = "grhkdi3glvat"
  ocir_region    = "gru"

  container_repos = {
    backend  = "equipe-sudo-backend"
    frontend = "equipe-sudo-frontend"
  }
}

resource "oci_artifacts_container_repository" "repos" {
  for_each       = local.container_repos
  compartment_id = var.oci_tenancy_ocid
  display_name   = "${var.tag_project}/${each.value}"
  is_immutable   = false
  is_public      = false

  freeform_tags = local.common_tags
}

# Outputs para uso em CI/CD
output "ocir_registry_url" {
  description = "URL base do OCIR"
  value       = "${local.ocir_region}.ocir.io/${local.ocir_namespace}"
}

output "ocir_backend_image" {
  description = "Imagem completa do backend"
  value       = "${local.ocir_region}.ocir.io/${local.ocir_namespace}/${var.tag_project}/equipe-sudo-backend:latest"
}

output "ocir_frontend_image" {
  description = "Imagem completa do frontend"
  value       = "${local.ocir_region}.ocir.io/${local.ocir_namespace}/${var.tag_project}/equipe-sudo-frontend:latest"
}
