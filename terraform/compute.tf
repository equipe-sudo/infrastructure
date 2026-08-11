# ============================================
# Terraform — Compute (VM E2.1.Micro)
# ============================================

# --- Imagem Oracle Linux 8 (x86_64) ---
data "oci_core_images" "oracle_linux" {
  compartment_id   = var.oci_tenancy_ocid
  operating_system = "Oracle Linux"

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

# --- VM E2.1.Micro (Always Free AMD) ---
resource "oci_core_instance" "main" {
  compartment_id      = var.oci_tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "vm-${var.tag_project}-${var.tag_environment}"
  shape               = var.vm_shape

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

  freeform_tags = local.common_tags
}
