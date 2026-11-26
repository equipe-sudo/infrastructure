# ============================================
# Terraform — VCN + Subnets + Gateways + Security Lists (PM-04)
# ============================================

# --- Tags comuns (padrão da equipe) ---
locals {
  common_tags = {
    Project     = var.instance_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# --- VCN ---
resource "oci_core_vcn" "main" {
  compartment_id = var.oci_tenancy_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "vcn-${var.instance_name}-${var.environment}"
  dns_label      = "scpm04"

  freeform_tags = local.common_tags
}

# --- Internet Gateway (egress da subnet pública) ---
resource "oci_core_internet_gateway" "main" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "igw-${var.instance_name}-${var.environment}"
  enabled        = true

  freeform_tags = local.common_tags
}

# --- Route Table padrão (subnet pública → Internet Gateway) ---
resource "oci_core_default_route_table" "public" {
  manage_default_resource_id = oci_core_vcn.main.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main.id
  }

  freeform_tags = local.common_tags
}

# --- NAT do banco: a VM app atua como NAT gateway (masquerade) ---
# O Always Free desta tenancy tem limite 0 de NAT gateways, então a VM app
# faz o NAT do tráfego de SAÍDA do banco (Docker/pacotes/OS updates). O banco
# NÃO tem IP público; a route table da subnet do banco aponta 0.0.0.0/0 para
# o IP privado da VM app, que aplica MASQUERADE (ver role ansible `nat`).
resource "oci_core_route_table" "private" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "rt-${var.instance_name}-private-${var.environment}"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.app_private_ips.private_ips[0].id
  }

  freeform_tags = local.common_tags
}

# ============================================
# Security List — subnet pública (aplicação)
# ============================================
resource "oci_core_security_list" "public" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "sl-${var.instance_name}-public-${var.environment}"

  # SSH (gestão) — única porta de administração aberta para a internet
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 22
      max = 22
    }

    description = "SSH (gestão)"
  }

  # HTTP — tráfego web
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 80
      max = 80
    }

    description = "HTTP"
  }

  # HTTPS — tráfego web seguro
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 443
      max = 443
    }

    description = "HTTPS"
  }

  # ICMP path MTU discovery (necessário para egress saudável via IGW)
  ingress_security_rules {
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    icmp_options {
      type = 3
      code = 4
    }

    description = "ICMP path MTU discovery"
  }

  # Egress total (Cloudflare Tunnel, pulls, atualizações)
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"

    description = "Egress total"
  }

  freeform_tags = local.common_tags
}

# ============================================
# Security List — subnet privada (banco)
# ============================================
resource "oci_core_security_list" "private" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "sl-${var.instance_name}-private-${var.environment}"

  # PostgreSQL — aceito SOMENTE da subnet pública da aplicação.
  # A porta 5432 NUNCA é exposta à internet (não há regra com source 0.0.0.0/0).
  ingress_security_rules {
    protocol    = "6"
    source      = var.app_subnet_cidr
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 5432
      max = 5432
    }

    description = "PostgreSQL (apenas da subnet da aplicação)"
  }

  # SSH (gestão) — aceito SOMENTE da subnet da aplicação (bastion).
  # O Ansible chega ao banco via ProxyCommand atravessando a VM app.
  ingress_security_rules {
    protocol    = "6"
    source      = var.app_subnet_cidr
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 22
      max = 22
    }

    description = "SSH (bastion, apenas da subnet da aplicação)"
  }

  # ICMP intra-VCN (diagnóstico/ping dentro da própria VCN)
  ingress_security_rules {
    protocol    = "1"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"

    icmp_options {
      type = 3
      code = 4
    }

    description = "ICMP path MTU discovery (intra-VCN)"
  }

  ingress_security_rules {
    protocol    = "1"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"

    icmp_options {
      type = 8
      code = 0
    }

    description = "ICMP ping (intra-VCN)"
  }

  # Egress total — roteado via Internet Gateway (OS updates/pacotes do banco)
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"

    description = "Egress total (via Internet Gateway)"
  }

  freeform_tags = local.common_tags
}

# ============================================
# Subnets
# ============================================

# --- Subnet pública (aplicação) ---
# Sem route_table_id explícito: usa a route table padrão da VCN, que já aponta
# 0.0.0.0/0 para o Internet Gateway (ver oci_core_default_route_table.public).
resource "oci_core_subnet" "public" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  cidr_block     = var.app_subnet_cidr
  display_name   = "sn-${var.instance_name}-public-${var.environment}"
  dns_label      = "pm04pub"

  prohibit_public_ip_on_vnic = false
  security_list_ids          = [oci_core_security_list.public.id]

  freeform_tags = local.common_tags
}

# --- Subnet do banco (privada, SEM IP público) ---
# Subnet dedicada ao banco. Roteia 0.0.0.0/0 para o IP privado da VM app
# (que faz NAT/masquerade). Nenhuma VNIC desta subnet pode ter IP público.
resource "oci_core_subnet" "private" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  cidr_block     = var.db_subnet_cidr
  display_name   = "sn-${var.instance_name}-private-${var.environment}"
  dns_label      = "pm04prv"
  route_table_id = oci_core_route_table.private.id

  prohibit_public_ip_on_vnic = true
  security_list_ids          = [oci_core_security_list.private.id]

  freeform_tags = local.common_tags
}
