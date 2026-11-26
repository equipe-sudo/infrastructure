# ============================================
# Terraform — VPC + Subnets + Gateways + Rotas (PM-04)
# ============================================

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "vpc-${var.instance_name}-${var.environment}" })
}

# --- Internet Gateway (egress da subnet pública) ---
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, { Name = "igw-${var.instance_name}-${var.environment}" })
}

# --- Route Table pública (subnet pública → Internet Gateway) ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, { Name = "rt-sc-public-${var.environment}" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================
# NAT do banco: a VM app atua como NAT gateway (masquerade)
# ============================================
# Sem NAT Gateway gerenciado (custa ~US$32/mês): a VM app faz MASQUERADE
# (role ansible `nat`) e a route table da subnet privada aponta 0.0.0.0/0
# para a ENI primária da VM app. Para isso a VM app tem source_dest_check
# desabilitado (ver compute.tf) — sem isso a AWS descarta o tráfego de
# terceiros que atravessa a instância.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, { Name = "rt-sc-private-${var.environment}" })
}

# ⚠️ O provedor AWS v5 removeu o argumento `instance_id` do aws_route. O alvo
# de rota via instância (NAT instance) agora é a ENI primária da instância.
resource "aws_route" "db_nat_via_app" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.app.primary_network_interface_id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ============================================
# Subnets
# ============================================

# --- Subnet pública (aplicação) ---
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.app_subnet_cidr
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "sn-sc-public-${var.environment}" })
}

# --- Subnet privada (banco, SEM IP público) ---
# map_public_ip_on_launch = false (default): nenhuma instância desta subnet
# recebe IP público. O egress sai via route table privada (NAT na VM app).
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.db_subnet_cidr
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, { Name = "sn-sc-private-${var.environment}" })
}
