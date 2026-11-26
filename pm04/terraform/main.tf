# ============================================
# Terraform — Provider e Backend (PM-04 / Smart Construction)
# ============================================

terraform {
  # O backend nativo do OCI (backend "oci") exige Terraform >= 1.12.
  required_version = ">= 1.12.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }

  # ============================================
  # Estado remoto — OCI Object Storage (nativo)
  # ============================================
  # Guarda o terraform.tfstate no mesmo bucket da infra principal, mas em
  # chave própria (`pm04/terraform.tfstate`) para não conflitar com o estado
  # de `terraform/terraform.tfstate`. LOCKING de estado nativo, permitindo que
  # o apply rode no GitHub Actions sem depender do estado local de uma máquina.
  #
  # As credenciais vêm do perfil OCI (~/.oci/config) e da chave configurada no
  # provider. Localmente, informe o perfil se não for o DEFAULT:
  #   terraform init -backend-config="config_file_profile=KOLPZS"
  backend "oci" {
    bucket    = "equipe-sudo-tfstate"
    key       = "pm04/terraform.tfstate"
    namespace = "grhkdi3glvat"
    region    = "sa-saopaulo-1"
  }
}

provider "oci" {
  tenancy_ocid     = var.oci_tenancy_ocid
  user_ocid        = var.oci_user_ocid
  private_key_path = var.oci_private_key_path
  fingerprint      = var.oci_fingerprint
  region           = var.oci_region
}
