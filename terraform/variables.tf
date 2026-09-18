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

variable "obs_subnet_cidr" {
  description = "CIDR da subnet de observabilidade (isolada da subnet da aplicacao)"
  type        = string
  default     = "10.0.2.0/24"
}

# --- Compute ---
variable "vm_shape" {
  description = "Shape da VM da aplicação. Sempre Free: VM.Standard.E2.1.Micro (AMD, 1 GB) ou VM.Standard.A1.Flex (ARM, até 4 OCPU/24 GB no total)."
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

# --- Compute: observabilidade ---
variable "obs_vm_shape" {
  description = "Shape da VM de observabilidade (Grafana/Prometheus/Loki/OTel Collector)."
  type        = string
  default     = "VM.Standard.E2.1.Micro"

  validation {
    condition = contains(
      ["VM.Standard.E2.1.Micro", "VM.Standard.A1.Flex"],
      var.obs_vm_shape
    )
    error_message = "Use VM.Standard.E2.1.Micro (Always Free AMD) ou VM.Standard.A1.Flex (Always Free ARM)."
  }
}

variable "obs_vm_ocpus" {
  description = "OCPUs da VM de observabilidade (usado apenas em shapes Flex)."
  type        = number
  default     = 1
}

variable "obs_vm_memory_gb" {
  description = "Memória RAM (GB) da VM de observabilidade (usado apenas em shapes Flex)."
  type        = number
  default     = 1
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
