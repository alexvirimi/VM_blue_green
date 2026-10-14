# Datos y recursos compartidos por varios archivos

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
