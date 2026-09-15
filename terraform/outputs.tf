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

# --- Observabilidade ---

output "obs_vm_id" {
  description = "OCID da instância de observabilidade"
  value       = oci_core_instance.obs.id
}

output "obs_vm_public_ip" {
  description = "IP público da VM de observabilidade"
  value       = oci_core_instance.obs.public_ip
}

output "obs_vm_private_ip" {
  description = "IP privado da VM de observabilidade (usado pela app para enviar OTLP)"
  value       = oci_core_instance.obs.private_ip
}

output "obs_ssh_command" {
  description = "Comando SSH para acessar a VM de observabilidade"
  value       = "ssh opc@${oci_core_instance.obs.public_ip}"
}

output "otel_exporter_otlp_endpoint" {
  description = "Endpoint OTLP/HTTP que a aplicação deve usar para enviar métricas e logs"
  value       = "http://${oci_core_instance.obs.private_ip}:4318"
}

output "obs_subnet_id" {
  description = "OCID da subnet de observabilidade"
  value       = oci_core_subnet.obs.id
}
