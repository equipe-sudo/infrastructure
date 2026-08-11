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
}

variable "vm_ocpus" {
  description = "Número de OCPUs"
  type        = number
  default     = 2
}

variable "vm_memory_gb" {
  description = "Memória RAM em GB"
  type        = number
  default     = 12
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
