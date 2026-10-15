provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      team        = var.team
      project     = var.project_name
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}
