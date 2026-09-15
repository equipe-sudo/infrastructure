# ============================================
# Terraform — Outputs
# ============================================

output "vcn_id" {
  description = "OCID da VCN"
  value       = oci_core_vcn.main.id
}

output "subnet_id" {
  description = "OCID da subnet pública"
  value       = oci_core_subnet.public.id
}

output "vm_id" {
  description = "OCID da instância"
  value       = oci_core_instance.main.id
}

output "vm_public_ip" {
  description = "IP público da VM"
  value       = oci_core_instance.main.public_ip
}

output "vm_private_ip" {
  description = "IP privado da VM"
  value       = oci_core_instance.main.private_ip
}

output "ssh_command" {
  description = "Comando SSH para acessar a VM"
  value       = "ssh opc@${oci_core_instance.main.public_ip}"
}
