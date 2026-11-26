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
  description = "Nome base da aplicação, usado nas tags Name da VPC/key pair."
  type        = string
  default     = "smart-construction"
}

# --- AWS ---

variable "instance_type" {
  description = "Tipo de instância EC2. AWS Free Tier: t3.micro (2 vCPU / 1 GB)."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t2.micro"], var.instance_type)
    error_message = "Use t3.micro ou t2.micro (ambos Free Tier)."
  }
}

variable "aws_region" {
  description = "Região AWS onde a infra será provisionada."
  type        = string
  default     = "us-east-1"
}

# --- Networking ---

variable "vpc_cidr" {
  description = "CIDR da VPC do PM-04 (faixa 10.10.x para não conflitar com a infra existente em 10.0.x)."
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

# --- SSH ---

variable "ssh_public_key_path" {
  description = "Caminho da chave pública SSH (injetada nas instâncias via key pair)."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
