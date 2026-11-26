# ============================================
# Terraform — Compute (PM-04)
# ============================================
# Duas VMs Always Free:
#   - oci_core_instance.app : aplicação (Next.js + FastAPI + Nginx + 2× SeaweedFS) — subnet pública
#   - oci_core_instance.db  : banco (PostgreSQL 17 exclusivo) — subnet privada
#
# shape_config só é enviado para shapes Flex (A1.Flex). Para shapes fixos
# (E2.1.Micro) o provedor não aceita/deriva o valor, por isso o bloco é
# condicional.

locals {
  is_flex = var.vm_shape == "VM.Standard.A1.Flex"
}

# --- Imagem Oracle Linux 8 compatível com o shape ---
data "oci_core_images" "oracle_linux" {
  compartment_id   = var.oci_tenancy_ocid
  operating_system = "Oracle Linux"
  shape            = var.vm_shape

  filter {
    name   = "display_name"
    values = ["Oracle-Linux-8.*"]
    regex  = true
  }

  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

# --- Domínio de disponibilidade ---
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_tenancy_ocid
}

# ============================================
# VM da aplicação (subnet pública, IP público)
# ============================================
resource "oci_core_instance" "app" {
  compartment_id      = var.oci_tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "vm-sc-app-${var.environment}"
  shape               = var.vm_shape

  dynamic "shape_config" {
    for_each = local.is_flex ? [1] : []

    content {
      ocpus         = var.vm_ocpus
      memory_in_gbs = var.vm_memory_gb
    }
  }

  source_details {
    source_id   = data.oci_core_images.oracle_linux.images[0].id
    source_type = "image"
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.public.id
    assign_public_ip       = true
    display_name           = "vnic-sc-app-${var.environment}"
    hostname_label         = "scapp"
    skip_source_dest_check = false
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
  }

  lifecycle {
    # Pinamos a imagem para que a publicação de uma imagem Oracle Linux 8 mais
    # nova não recrie a instância (que conterá o boot volume da aplicação).
    # O shape_config NÃO é ignorado: resize de A1.Flex é aplicado in-place.
    ignore_changes = [source_details]
  }

  freeform_tags = local.common_tags
}

# ============================================
# VM do banco (subnet privada, SEM IP público)
# Executa exclusivamente o PostgreSQL 17. Os SeaweedFS (editorial e privado)
# ficam na VM de aplicação, junto aos demais componentes.
# ============================================
resource "oci_core_instance" "db" {
  compartment_id      = var.oci_tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "vm-sc-db-${var.environment}"
  shape               = var.vm_shape

  dynamic "shape_config" {
    for_each = local.is_flex ? [1] : []

    content {
      ocpus         = var.vm_ocpus
      memory_in_gbs = var.vm_memory_gb
    }
  }

  source_details {
    source_id   = data.oci_core_images.oracle_linux.images[0].id
    source_type = "image"
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.private.id
    assign_public_ip       = false
    display_name           = "vnic-sc-db-${var.environment}"
    hostname_label         = "scdb"
    skip_source_dest_check = false
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
  }

  lifecycle {
    # Mesmo raciocínio da VM de aplicação: evita recriação por nova imagem.
    ignore_changes = [source_details]
  }

  freeform_tags = local.common_tags
}
