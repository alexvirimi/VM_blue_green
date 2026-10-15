resource "aws_s3_bucket" "ansible_ssm" {
  bucket        = "${var.project_name}-ansible-ssm-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "ansible_ssm" {
  bucket                  = aws_s3_bucket.ansible_ssm.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "ansible_ssm" {
  bucket = aws_s3_bucket.ansible_ssm.id
  rule {
    id     = "limpiar-temporales"
    status = "Enabled"
    filter {}
    expiration { days = 1 }
  }
}

data "aws_iam_policy_document" "ansible_ssm_bucket" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.ansible_ssm.arn}/*"]
  }
  statement {
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.ansible_ssm.arn]
  }
}

resource "aws_iam_role_policy" "app_ansible_ssm_bucket" {
  name   = "${var.project_name}-ansible-ssm-bucket"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.ansible_ssm_bucket.json
}

output "ansible_ssm_bucket" {
  value = aws_s3_bucket.ansible_ssm.bucket
}