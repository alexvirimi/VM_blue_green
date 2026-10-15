# Datos y recursos compartidos por varios archivos

data "aws_availability_zones" "available" {
  state = "available"

  # CKV_AWS_394: fija la identidad de la zona para que el conjunto no se amplie
  # silenciosamente si AWS anade una nueva AZ a la region.
  filter {
    name   = "zone-name"
    values = ["${var.aws_region}a"]
  }
}

data "aws_caller_identity" "current" {}
