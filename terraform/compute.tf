# ============================================
# Terraform — Compute
# ============================================
# Duas VMs Always Free:
#   - oci_core_instance.main : aplicação (subnet pública)
#   - oci_core_instance.obs  : observabilidade (subnet dedicada)
#
# shape_config só é enviado para shapes Flex (A1.Flex). Para shapes fixos
# (E2.1.Micro) o provedor não aceita/deriva o valor, por isso o bloco é
# condicional.

locals {
  main_is_flex = var.vm_shape == "VM.Standard.A1.Flex"
  obs_is_flex  = var.obs_vm_shape == "VM.Standard.A1.Flex"
}

# --- Imagem Oracle Linux 8 compatível com o shape da aplicação ---
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

# --- VM da aplicação (Always Free) ---
resource "oci_core_instance" "main" {
  compartment_id      = var.oci_tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "vm-${var.tag_project}-${var.tag_environment}"
  shape               = var.vm_shape

  dynamic "shape_config" {
    for_each = local.main_is_flex ? [1] : []

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
    display_name           = "vnic-${var.tag_project}-${var.tag_environment}"
    hostname_label         = "equipesudo"
    skip_source_dest_check = false
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
  }

  lifecycle {
    # A VM já está em execução e serve a aplicação. Como o boot volume contém
    # os dados do Docker (incluindo o volume do MongoDB), não queremos que a
    # descoberta automática de uma imagem mais nova recrie a instância. Pinamos
    # a imagem e o shape atuais; atualizações de SO/imagem devem ser feitas de
    # forma deliberada (removendo este ignore_changes).
    ignore_changes = [source_details, shape_config]
  }

  freeform_tags = local.common_tags
}

# ============================================
# VM de observabilidade (Always Free)
# ============================================
# Hospeda Grafana + Prometheus + Loki + OpenTelemetry Collector.
# Fica na subnet de observabilidade e só aceita telemetria (OTLP) da subnet
# da aplicação — ver oci_core_security_list.obs.

data "oci_core_images" "oracle_linux_obs" {
  compartment_id   = var.oci_tenancy_ocid
  operating_system = "Oracle Linux"
  shape            = var.obs_vm_shape

  filter {
    name   = "display_name"
    values = ["Oracle-Linux-8.*"]
    regex  = true
  }

  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

resource "oci_core_instance" "obs" {
  compartment_id      = var.oci_tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "vm-${var.tag_project}-obs-${var.tag_environment}"
  shape               = var.obs_vm_shape

  dynamic "shape_config" {
    for_each = local.obs_is_flex ? [1] : []

    content {
      ocpus         = var.obs_vm_ocpus
      memory_in_gbs = var.obs_vm_memory_gb
    }
  }

  source_details {
    source_id   = data.oci_core_images.oracle_linux_obs.images[0].id
    source_type = "image"
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.obs.id
    assign_public_ip       = true
    display_name           = "vnic-${var.tag_project}-obs-${var.tag_environment}"
    hostname_label         = "equipesudoobs"
    skip_source_dest_check = false
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
  }

  lifecycle {
    ignore_changes = [source_details]
  }

  freeform_tags = local.common_tags
}
