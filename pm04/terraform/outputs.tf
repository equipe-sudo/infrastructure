# ============================================
# Terraform — Outputs (PM-04)
# ============================================

output "app_vm_public_ip" {
  description = "IP público da VM de aplicação"
  value       = aws_instance.app.public_ip
}

output "app_vm_private_ip" {
  description = "IP privado da VM de aplicação (usado pela API para conectar ao banco)"
  value       = aws_instance.app.private_ip
}

output "db_vm_private_ip" {
  description = "IP privado da VM de banco (PostgreSQL 17 exclusivo)"
  value       = aws_instance.db.private_ip
}

output "db_vm_public_ip" {
  description = "IP público da VM de banco — sempre vazio: a VM não tem IP público (subnet privada, egress via NAT na VM app)."
  value       = ""
}

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "ssh_command_app" {
  description = "Comando SSH para acessar a VM de aplicação"
  value       = "ssh ec2-user@${aws_instance.app.public_ip}"
}
