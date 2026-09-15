# ============================================
# Terraform — Provider e Locals
# ============================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }

  # backend "s3" {
  #   bucket   = var.tf_bucket_name
  #   key      = "${var.tf_object_prefix}terraform.tfstate"
  #   region   = var.oci_region
  #   endpoint = "https://${var.oci_namespace}.compat.objectstorage.${var.oci_region}.oraclecloud.com"
  #   skip_region_validation      = true
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   force_path_style            = true
  # }
}

provider "oci" {
  tenancy_ocid     = var.oci_tenancy_ocid
  user_ocid        = var.oci_user_ocid
  private_key_path = var.oci_private_key_path
  fingerprint      = var.oci_fingerprint
  region           = var.oci_region
}
