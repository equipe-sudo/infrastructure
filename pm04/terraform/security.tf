# ============================================
# Terraform — Security Groups (PM-04)
# ============================================

# ============================================
# SG — aplicação (subnet pública)
# ============================================
resource "aws_security_group" "app" {
  name        = "sg-sc-app-${var.environment}"
  description = "Aplicação Smart Construction — SSH/HTTP/HTTPS públicos"
  vpc_id      = aws_vpc.main.id

  # SSH (gestão) — única porta de administração aberta para a internet
  ingress {
    description = "SSH (gestao)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP — tráfego web
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS — tráfego web seguro
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress total (Cloudflare Tunnel, pulls, atualizações)
  egress {
    description = "Egress total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "sg-sc-app-${var.environment}" })
}

# ============================================
# SG — banco (subnet privada)
# ============================================
resource "aws_security_group" "db" {
  name        = "sg-sc-db-${var.environment}"
  description = "Banco PostgreSQL 17 — acesso privado, apenas da subnet da aplicação"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL — aceito SOMENTE da subnet pública da aplicação.
  # A porta 5432 NUNCA é exposta à internet (não há regra com source 0.0.0.0/0).
  ingress {
    description = "PostgreSQL (apenas da subnet da aplicacao)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.app_subnet_cidr]
  }

  # SSH (gestão) — aceito SOMENTE da subnet da aplicação (bastion).
  # O Ansible chega ao banco via ProxyCommand atravessando a VM app.
  ingress {
    description = "SSH (bastion, apenas da subnet da aplicacao)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.app_subnet_cidr]
  }

  # Egress total — roteado via NAT na VM app (OS updates/pacotes do banco)
  egress {
    description = "Egress total (via NAT na VM app)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "sg-sc-db-${var.environment}" })
}
