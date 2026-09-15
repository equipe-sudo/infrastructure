# ============================================
# Terraform — Variáveis
# ============================================

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
  description = "CIDR da VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

# --- Compute ---
variable "vm_shape" {
  description = "Shape da VM"
  type        = string
  default     = "VM.Standard.A1.Flex"

  validation {
    condition     = var.vm_shape == "VM.Standard.A1.Flex"
    error_message = "Use VM.Standard.A1.Flex para obter o maior limite Always Free: ate 4 OCPUs e 24 GB RAM."
  }
}

variable "vm_ocpus" {
  description = "Número de OCPUs da VM A1.Flex. No Always Free, o limite total é 4 OCPUs."
  type        = number
  default     = 2

  validation {
    condition     = var.vm_ocpus >= 1 && var.vm_ocpus <= 4
    error_message = "vm_ocpus deve ficar entre 1 e 4 para respeitar o limite Always Free do A1.Flex."
  }
}

variable "vm_memory_gb" {
  description = "Memória RAM em GB da VM A1.Flex. No Always Free, o limite total é 24 GB."
  type        = number
  default     = 12

  validation {
    condition     = var.vm_memory_gb >= 1 && var.vm_memory_gb <= 24
    error_message = "vm_memory_gb deve ficar entre 1 e 24 para respeitar o limite Always Free do A1.Flex."
  }
}

variable "ssh_public_key_path" {
  description = "Caminho da chave pública SSH"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# --- Tags ---
variable "tag_project" {
  description = "Nome do projeto"
  type        = string
  default     = "equipe-sudo"
}

variable "tag_environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

variable "tag_managed_by" {
  description = "Ferramenta de gerenciamento"
  type        = string
  default     = "terraform"
}
