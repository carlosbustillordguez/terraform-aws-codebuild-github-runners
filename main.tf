data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "pat" {
  count = var.pat_aws_secret_name != "" ? 1 : 0

  name = var.pat_aws_secret_name
}

################################################################################
# Local Values
################################################################################

locals {
  # A list of strings with the subnets ARNs
  codebuild_subnets_arn = formatlist(
    "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/%s",
  var.codebuild_vpc_config.subnets)

  # Fixed tags
  fixed_tags = {
    Terraform          = true
    TerraformWorkspace = terraform.workspace
  }

  common_tags = merge(local.fixed_tags, var.tags)
}


################################################################################
# IAM Resources
################################################################################

## CodeBuild Base Policy

resource "aws_iam_policy" "base" {
  name        = "CodeBuildBasePolicy-${var.codebuild_project_name}-${var.aws_region}"
  description = "CodeBuild Base Policy"
  path        = "/"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.codebuild_project_name}",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.codebuild_project_name}:*"
        ],
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::codepipeline-${var.aws_region}-*",
        ],
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
      },
      {
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:report-group/${var.codebuild_project_name}-*"
        ],
        "Action" : [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ]
      }
    ]
  })

  tags = local.common_tags
}

## CodeBuild CloudWatch Logs Policy
resource "aws_iam_policy" "codebuild_cw_logs" {
  count = var.codebuild_logs_config.cloudwatch_logs != null ? 1 : 0

  name        = "CodeBuildCloudWatchLogsPolicy-${var.codebuild_project_name}-${var.aws_region}"
  description = "CodeBuild CloudWatch Logs Policy"
  path        = "/"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${var.codebuild_logs_config.cloudwatch_logs.group_name}",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${var.codebuild_logs_config.cloudwatch_logs.group_name}:*"
        ],
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      }
    ]
  })

  tags = local.common_tags
}

## CodeBuild S3 Logs Policy
resource "aws_iam_policy" "codebuild_s3_logs" {
  count = var.codebuild_logs_config.s3_logs != null ? 1 : 0

  name        = "CodeBuildS3LogsPolicy-${var.codebuild_project_name}-${var.aws_region}"
  description = "CodeBuild S3 Logs Policy"
  path        = "/"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${var.codebuild_logs_config.s3_logs.location}",
          "arn:aws:s3:::${var.codebuild_logs_config.s3_logs.location}/*"
        ],
        "Action" : [
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
      }
    ]
  })

  tags = local.common_tags
}

## CodeBuild Secrets Manager Source Credentials Policy
resource "aws_iam_policy" "secret_manager" {
  count = var.pat_aws_secret_name != "" ? 1 : 0

  name        = "CodeBuildSecretsManagerSrcCredsPolicy-${var.codebuild_project_name}-${var.aws_region}"
  description = "CodeBuild Secrets Manager Source Credentials Policy"
  path        = "/"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Resource" : [
          data.aws_secretsmanager_secret.pat[0].arn
        ],
        "Action" : [
          "secretsmanager:GetSecretValue"
        ]
      }
    ]
  })

  tags = local.common_tags
}

## CodeBuild VPC Policy
resource "aws_iam_policy" "codebuild_vpc" {
  name        = "CodeBuildVpcPolicy-${var.codebuild_project_name}-${var.aws_region}"
  description = "CodeBuild VPC Policy"
  path        = "/"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterfacePermission"
        ],
        "Resource" : "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
        "Condition" : {
          "StringEquals" : {
            "ec2:Subnet" : local.codebuild_subnets_arn,
            "ec2:AuthorizedService" : "codebuild.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

## IAM role to be assumed by CodeBuild
resource "aws_iam_role" "codebuild" {
  name        = "github-runners-codebuild-${var.codebuild_project_name}"
  description = "Service role used by CodeBuild Project ${var.codebuild_project_name}"
  path        = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  tags = local.common_tags
}

## IAM Policies assigment to CodeBuild Service Role
resource "aws_iam_role_policy_attachment" "base" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.base.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_cw_logs" {
  count = var.codebuild_logs_config.cloudwatch_logs != null ? 1 : 0

  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild_cw_logs[0].arn
}

resource "aws_iam_role_policy_attachment" "codebuild_s3_logs" {
  count = var.codebuild_logs_config.s3_logs != null ? 1 : 0

  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild_s3_logs[0].arn
}

resource "aws_iam_role_policy_attachment" "secret_manager" {
  count = var.pat_aws_secret_name != "" ? 1 : 0

  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.secret_manager[0].arn
}

resource "aws_iam_role_policy_attachment" "codebuild_vpc" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild_vpc.arn
}


################################################################################
## CodeBuild Project Resources
################################################################################

## Manages a CodeBuild webhook, which is an endpoint accepted by the CodeBuild service
## to trigger builds from source code repositories.
## The CodeBuild service will automatically create and delete GitHub organization webhook
## using its granted OAuth permissions.
resource "aws_codebuild_webhook" "this" {
  project_name = aws_codebuild_project.this.name

  build_type = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }

  scope_configuration {
    name  = var.github_organization_name
    scope = "GITHUB_ORGANIZATION"
  }
}


## CodeBuild Project
resource "aws_codebuild_project" "this" {
  name           = var.codebuild_project_name
  description    = var.codebuild_project_description
  build_timeout  = 60
  queued_timeout = 480
  service_role   = aws_iam_role.codebuild.arn

  source {
    type            = "GITHUB"
    location        = "CODEBUILD_DEFAULT_WEBHOOK_SOURCE_LOCATION"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = false
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = var.codebuild_project_environment.compute_type
    image                       = var.codebuild_project_environment.image
    type                        = var.codebuild_project_environment.type
    image_pull_credentials_type = var.codebuild_project_environment.image_pull_credentials_type
    privileged_mode             = var.codebuild_project_environment.privileged_mode
  }

  vpc_config {
    vpc_id             = var.codebuild_vpc_config.vpc_id
    subnets            = var.codebuild_vpc_config.subnets
    security_group_ids = var.codebuild_vpc_config.security_group_ids
  }

  dynamic "logs_config" {
    for_each = length(var.codebuild_logs_config) > 0 ? [1] : []

    content {
      dynamic "cloudwatch_logs" {
        for_each = var.codebuild_logs_config.cloudwatch_logs != null ? { key = var.codebuild_logs_config["cloudwatch_logs"] } : {}

        content {
          status      = lookup(cloudwatch_logs.value, "status", null)
          group_name  = lookup(cloudwatch_logs.value, "group_name", null)
          stream_name = lookup(cloudwatch_logs.value, "stream_name", null)
        }
      }

      dynamic "s3_logs" {
        for_each = var.codebuild_logs_config.s3_logs != null ? { key = var.codebuild_logs_config["s3_logs"] } : {}

        content {
          status              = lookup(s3_logs.value, "status", null)
          location            = lookup(s3_logs.value, "location", null)
          encryption_disabled = lookup(s3_logs.value, "encryption_disabled", null)
        }
      }
    }
  }

  tags = local.common_tags
}
