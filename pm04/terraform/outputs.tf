# ============================================
# Terraform — Outputs (PM-04)
# ============================================

output "app_vm_public_ip" {
  description = "IP público da VM de aplicação"
  value       = oci_core_instance.app.public_ip
}

output "app_vm_private_ip" {
  description = "IP privado da VM de aplicação (usado pela API para conectar ao banco)"
  value       = oci_core_instance.app.private_ip
}

output "db_vm_private_ip" {
  description = "IP privado da VM de banco (PostgreSQL 17 exclusivo)"
  value       = oci_core_instance.db.private_ip
}

output "db_vm_public_ip" {
  description = "IP público da VM de banco — sempre vazio, pois a subnet é privada"
  value       = ""
}

output "vcn_id" {
  description = "OCID da VCN"
  value       = oci_core_vcn.main.id
}

output "app_subnet_id" {
  description = "OCID da subnet pública (aplicação)"
  value       = oci_core_subnet.public.id
}

output "db_subnet_id" {
  description = "OCID da subnet privada (banco)"
  value       = oci_core_subnet.private.id
}

output "ssh_command_app" {
  description = "Comando SSH para acessar a VM de aplicação"
  value       = "ssh opc@${oci_core_instance.app.public_ip}"
}
