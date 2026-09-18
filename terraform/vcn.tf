# ============================================
# Terraform — VCN + Subnet + Security + Gateway
# ============================================

# --- Tags comuns ---
locals {
  common_tags = {
    Project     = var.tag_project
    Environment = var.tag_environment
    ManagedBy   = var.tag_managed_by
  }
}

# --- VCN ---
resource "oci_core_vcn" "main" {
  compartment_id = var.oci_tenancy_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "vcn-${var.tag_project}-${var.tag_environment}"
  dns_label      = "equipesudo"

  freeform_tags = local.common_tags
}

# --- Internet Gateway ---
resource "oci_core_internet_gateway" "main" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "igw-${var.tag_project}-${var.tag_environment}"
  enabled        = true

  freeform_tags = local.common_tags
}

# --- Route Table (padrão via IGW) ---
resource "oci_core_default_route_table" "main" {
  manage_default_resource_id = oci_core_vcn.main.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main.id
  }

  freeform_tags = local.common_tags
}

# --- Subnet Pública ---
resource "oci_core_subnet" "public" {
  compartment_id             = var.oci_tenancy_ocid
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = var.subnet_cidr
  display_name               = "sn-${var.tag_project}-public-${var.tag_environment}"
  dns_label                  = "public"
  prohibit_public_ip_on_vnic = false

  freeform_tags = local.common_tags
}

# --- Security List ---
resource "oci_core_default_security_list" "main" {
  manage_default_resource_id = oci_core_vcn.main.default_security_list_id

  # SSH (gerenciamento) — única porta aberta para internet
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 22
      max = 22
    }

    description = "Acesso SSH"
  }

  # ICMP (ping / path MTU discovery)
  ingress_security_rules {
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    icmp_options {
      type = 3
      code = 4
    }

    description = "ICMP"
  }

  # ICMP type 8 (echo request)
  ingress_security_rules {
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    icmp_options {
      type = 8
      code = 0
    }

    description = "ICMP ping"
  }

  # node_exporter (métricas de host) — aceito SOMENTE da subnet da observabilidade.
  # O Prometheus roda na VM de observabilidade e faz o scrape (modelo pull) das
  # duas VMs na porta 9100. É uma leitura de métricas, não um caminho de dados.
  ingress_security_rules {
    protocol    = "6"
    source      = var.obs_subnet_cidr
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 9100
      max = 9100
    }

    description = "node_exporter (scrape do Prometheus)"
  }

  # Egress — todo tráfego de saída (necessário para Cloudflare Tunnel,
  # Docker pulls do OCIR, e atualizações do sistema)
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"

    description = "Egress total"
  }

  freeform_tags = local.common_tags
}

# ============================================
# Observabilidade — subnet dedicada + Security List
# ============================================
# A VM de observabilidade fica em uma subnet própria para permitir isolamento
# real: a única comunicação aceita da subnet da aplicação é o envio de
# telemetria (OTLP 4317/4318). Nenhum outro tráfego originado na aplicação é
# permitido, e a observabilidade nunca inicia conexão para a aplicação.

resource "oci_core_security_list" "obs" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "sl-${var.tag_project}-obs-${var.tag_environment}"

  # SSH administrativo
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 22
      max = 22
    }

    description = "Acesso SSH administrativo"
  }

  # OTLP gRPC — aceito SOMENTE da subnet da aplicação
  ingress_security_rules {
    protocol    = "6"
    source      = var.subnet_cidr
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 4317
      max = 4317
    }

    description = "OTLP gRPC enviado pela aplicacao"
  }

  # OTLP HTTP — aceito SOMENTE da subnet da aplicação
  ingress_security_rules {
    protocol    = "6"
    source      = var.subnet_cidr
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 4318
      max = 4318
    }

    description = "OTLP HTTP enviado pela aplicacao"
  }

  # ICMP intra-VCN (diagnóstico)
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

  # Egress total — necessário para pull de imagens, Cloudflare Tunnel, DNS
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"

    description = "Egress total"
  }

  freeform_tags = local.common_tags
}

resource "oci_core_subnet" "obs" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  cidr_block     = var.obs_subnet_cidr
  display_name   = "sn-${var.tag_project}-obs-${var.tag_environment}"
  dns_label      = "obs"

  prohibit_public_ip_on_vnic = false
  security_list_ids          = [oci_core_security_list.obs.id]

  freeform_tags = local.common_tags
}
