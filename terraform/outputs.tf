output "vm_public_ip" {
  description = "Dirección IPv4 pública de la VM para Ansible y HTTP."
  value       = aws_instance.app.public_ip
}

output "ssh_user" {
  description = "Usuario SSH predeterminado de la AMI oficial Ubuntu 22.04."
  value       = "ubuntu"
}

output "ecr_repository_url" {
  description = "URI del repositorio privado ECR donde se publican las imágenes Docker."
  value       = aws_ecr_repository.app.repository_url
}

output "ec2_instance_id" {
  description = "ID de la instancia EC2 del laboratorio."
  value       = aws_instance.app.id
}

output "security_group_id" {
  description = "ID del Security Group que permite HTTP y SSH limitado."
  value       = aws_security_group.app.id
}

output "github_actions_role_arn" {
  description = "ARN del rol OIDC publicador de ECR; null si no se configuró proveedor OIDC."
  value       = var.github_oidc_provider_arn == null ? null : aws_iam_role.github_actions[0].arn
}

output "aws_account_id" {
  description = "ID de la cuenta AWS seleccionada por las credenciales activas."
  value       = data.aws_caller_identity.current.account_id
}

output "availability_zone" {
  description = "Zona de disponibilidad de la VM."
  value       = aws_subnet.public.availability_zone
}
