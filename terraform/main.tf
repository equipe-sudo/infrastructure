# ============================================
# Terraform — Provider e Locals
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
  # Guarda o terraform.tfstate em um bucket do OCI Object Storage, com
  # LOCKING de estado, permitindo que o apply rode no GitHub Actions (e por
  # qualquer pessoa do time) sem depender do estado local de uma máquina.
  #
  # É o backend NATIVO do OCI (não é o backend S3-compatível, que a Oracle
  # deprecou): autentica com a própria API key OCI, sem credenciais S3/AWS.
  #
  # As credenciais vêm do perfil OCI (~/.oci/config) e do arquivo de chave
  # configurados para o provider. Localmente, informe o perfil se não for
  # o DEFAULT:
  #   terraform init -backend-config="config_file_profile=KOLPZS"
  #
  # Bucket criado com versionamento habilitado (recuperação do estado).
  backend "oci" {
    bucket    = "equipe-sudo-tfstate"
    key       = "terraform/terraform.tfstate"
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
