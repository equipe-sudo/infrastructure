# ============================================
# Terraform — Provider e Backend (PM-04 / Smart Construction)
# ============================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ============================================
  # Estado remoto — AWS S3
  # ============================================
  # Guarda o terraform.tfstate no bucket S3 da infra principal, em chave
  # própria (`pm04/terraform.tfstate`), permitindo que o apply rode no
  # GitHub Actions sem depender do estado local de uma máquina.
  #
  # ⚠️ Blocos de backend NÃO aceitam variáveis (`var.aws_region`). O `region`
  # é fixo aqui e pode ser sobrescrito no init, se o bucket for criado em
  # outra região:
  #   terraform init -backend-config="region=sa-east-1"
  backend "s3" {
    bucket = "equipe-sudo-tfstate"
    key    = "pm04/terraform.tfstate"
    region = "us-east-1"
  }
}

# Credenciais vêm do ambiente padrão da AWS (AWS_ACCESS_KEY_ID /
# AWS_SECRET_ACCESS_KEY, ~/.aws/credentials ou perfil via AWS_PROFILE).
provider "aws" {
  region = var.aws_region
}

# ============================================
# Tags comuns (padrão da equipe)
# ============================================
locals {
  common_tags = {
    Project     = var.instance_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
