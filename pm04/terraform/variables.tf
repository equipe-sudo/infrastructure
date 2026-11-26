# ============================================
# Terraform — Variáveis (PM-04 / Smart Construction)
# ============================================

# --- Identificação do projeto / ambiente ---

variable "environment" {
  description = "Ambiente de deploy (dev/homolog/prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "homolog", "prod"], var.environment)
    error_message = "environment deve ser um de: dev, homolog, prod."
  }
}

variable "instance_name" {
  description = "Nome base da aplicação, usado nos display_name de VCN/subnets/security lists."
  type        = string
  default     = "smart-construction"
}

# --- OCI Authentication ---

variable "oci_tenancy_ocid" {
  description = "OCID do tenancy OCI"
  type        = string
  sensitive   = true
}

variable "oci_user_ocid" {
  description = "OCID do usuário OCI"
  type        = string
  sensitive   = true
}

variable "oci_fingerprint" {
  description = "Fingerprint da chave API"
  type        = string
  sensitive   = true
}

variable "oci_private_key_path" {
  description = "Caminho da chave privada da API OCI"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "oci_region" {
  description = "Região OCI"
  type        = string
  default     = "sa-saopaulo-1"
}

# --- Networking ---

variable "vcn_cidr" {
  description = "CIDR da VCN do PM-04 (faixa 10.10.x para não conflitar com a infra existente em 10.0.x)."
  type        = string
  default     = "10.10.0.0/16"
}

variable "app_subnet_cidr" {
  description = "CIDR da subnet pública (aplicação). É a origem autorizada para a porta 5432 do banco."
  type        = string
  default     = "10.10.1.0/24"
}

variable "db_subnet_cidr" {
  description = "CIDR da subnet privada (banco). Sem IP público."
  type        = string
  default     = "10.10.2.0/24"
}

# --- Compute ---

variable "vm_shape" {
  description = "Shape das VMs. Sempre Free: VM.Standard.E2.1.Micro (AMD, 1 GB) ou VM.Standard.A1.Flex (ARM, até 4 OCPU/24 GB no total)."
  type        = string
  default     = "VM.Standard.E2.1.Micro"

  validation {
    condition = contains(
      ["VM.Standard.E2.1.Micro", "VM.Standard.A1.Flex"],
      var.vm_shape
    )
    error_message = "Use VM.Standard.E2.1.Micro (Always Free AMD) ou VM.Standard.A1.Flex (Always Free ARM)."
  }
}

variable "vm_ocpus" {
  description = "Número de OCPUs das VMs A1.Flex. No Always Free, o limite total é 4 OCPUs."
  type        = number
  default     = 2

  validation {
    condition     = var.vm_ocpus >= 1 && var.vm_ocpus <= 4
    error_message = "vm_ocpus deve ficar entre 1 e 4 para respeitar o limite Always Free do A1.Flex."
  }
}

variable "vm_memory_gb" {
  description = "Memória RAM em GB das VMs A1.Flex. No Always Free, o limite total é 24 GB."
  type        = number
  default     = 12

  validation {
    condition     = var.vm_memory_gb >= 1 && var.vm_memory_gb <= 24
    error_message = "vm_memory_gb deve ficar entre 1 e 24 para respeitar o limite Always Free do A1.Flex."
  }
}

variable "ssh_public_key_path" {
  description = "Caminho da chave pública SSH (injetada nas VMs via cloud-init/metadata)."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
