# ============================================
# Terraform — Compute (PM-04)
# ============================================
# Duas instâncias EC2 (Amazon Linux 2023, t3.micro Free Tier):
#   - aws_instance.app : aplicação (Next.js + FastAPI + Nginx + 2× SeaweedFS) — subnet pública
#   - aws_instance.db  : banco (PostgreSQL 17 exclusivo) — subnet privada, SEM IP público

# ============================================
# AMI — Amazon Linux 2023 (x86_64, não-minimal)
# ============================================
# O filtro `al2023-ami-2*` casa a imagem padrão (`al2023-ami-2023.x...x86_64`)
# e EXCLUI a variante `al2023-ami-minimal-*` (nome começa com "m") e a
# arquitetura arm64 (`...-aarch64`), que não serviriam para o perfil atual.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================
# Key Pair — SSH (chave pública de var.ssh_public_key_path)
# ============================================
resource "aws_key_pair" "main" {
  key_name   = "key-sc-${var.environment}"
  public_key = file(pathexpand(var.ssh_public_key_path))

  tags = merge(local.common_tags, { Name = "key-sc-${var.environment}" })
}

# ============================================
# VM da aplicação (subnet pública, IP público)
# ============================================
resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

  # NAT do banco: a app roteia/masqueradeia o tráfego da subnet privada.
  # source_dest_check = false é OBRIGATÓRIO para a instância aceitar e
  # encaminhar pacotes que não são destinados a ela (ver role ansible `nat`).
  source_dest_check = false

  lifecycle {
    # Evita recriação da instância quando a AWS publica uma AL2023 mais nova
    # (o disco da aplicação contém estado do deploy). A AMI é resolvida uma vez.
    ignore_changes = [ami]
  }

  tags = merge(local.common_tags, { Name = "vm-sc-app-${var.environment}" })
}

# ============================================
# VM do banco (subnet privada, SEM IP público)
# Executa exclusivamente o PostgreSQL 17. Os SeaweedFS (editorial e privado)
# ficam na VM de aplicação, junto aos demais componentes.
# ============================================
resource "aws_instance" "db" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.db.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [ami]
  }

  tags = merge(local.common_tags, { Name = "vm-sc-db-${var.environment}" })
}
