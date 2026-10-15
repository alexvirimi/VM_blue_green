variable "aws_region" {
  description = "Región del laboratorio. Confirma la región permitida por AWS Academy."
  type        = string
  default     = "us-east-2"
}

variable "team" {
  description = "Etiqueta del equipo para identificar y filtrar recursos."
  type        = string
  default     = "equipo-taller"
}

variable "project_name" {
  description = "Prefijo para los recursos del proyecto."
  type        = string
  default     = "vm-blue-green"
}

variable "environment" {
  description = "Etiqueta del entorno."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "Bloque IPv4 de la VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Bloque IPv4 de la única subred pública del laboratorio."
  type        = string
  default     = "10.30.1.0/24"
}

variable "ssh_allowed_cidr" {
  description = "CIDR IPv4 autorizado para SSH. Usa tu IP pública con /32; nunca uses 0.0.0.0/0."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ssh_allowed_cidr)) && can(regex("/32$", var.ssh_allowed_cidr))
    error_message = "ssh_allowed_cidr debe ser una dirección IPv4 válida con máscara /32."
  }
}

variable "key_name" {
  description = "Nombre de un key pair de EC2 que ya existe en AWS. Terraform no crea ni descarga claves."
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2. t3.micro sirve como tamaño inicial si AWS Academy lo permite."
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size_gib" {
  description = "Tamaño del volumen raíz cifrado en GiB."
  type        = number
  default     = 16

  validation {
    condition     = var.root_volume_size_gib >= 8 && var.root_volume_size_gib <= 100
    error_message = "root_volume_size_gib debe estar entre 8 y 100 GiB."
  }
}

variable "ecr_repository_name" {
  description = "Nombre del repositorio privado de imágenes Docker en ECR."
  type        = string
  default     = "vm-blue-green"
}

variable "github_oidc_provider_arn" {
  description = "ARN de un proveedor OIDC existente para token.actions.githubusercontent.com. Si es null, no se crea el rol publicador de GitHub."
  type        = string
  default     = null
  nullable    = true
}

variable "github_owner" {
  description = "Usuario u organización dueña del repositorio de GitHub."
  type        = string
  default     = "alexvirimi"
}

variable "github_repository" {
  description = "Nombre del repositorio autorizado a publicar imágenes en ECR."
  type        = string
  default     = "VM_blue_green"
}

variable "github_branch" {
  description = "Rama autorizada por el rol OIDC de publicación."
  type        = string
  default     = "main"
}

variable "github_actions_role_name" {
  description = "Nombre del rol IAM de GitHub Actions limitado a publicar imágenes en el ECR de este proyecto."
  type        = string
  default     = "vm-blue-green-github-ecr-publisher"
}
