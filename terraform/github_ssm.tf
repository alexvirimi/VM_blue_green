data "aws_iam_policy_document" "github_ansible_ssm" {
  statement {
    actions = ["ssm:StartSession"]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.app.id}",
      "arn:aws:ssm:${var.aws_region}::document/SSM-SessionManagerRunShell",
    ]
  }
  statement {
    actions   = ["ssm:TerminateSession", "ssm:ResumeSession"]
    resources = ["arn:aws:ssm:*:*:session/$${aws:userid}-*"]
  }
  statement {
    actions   = ["ssm:DescribeInstanceInformation", "ec2:DescribeInstances"]
    resources = ["*"]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.ansible_ssm.arn}/*"]
  }
  statement {
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.ansible_ssm.arn]
  }
}

resource "aws_iam_role_policy" "github_ansible_ssm" {
  name   = "${var.project_name}-github-ansible-ssm"
  role   = var.github_actions_role_name
  policy = data.aws_iam_policy_document.github_ansible_ssm.json
}