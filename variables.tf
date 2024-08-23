variable "tags" {
  description = "Tags added to all supported resources."
  type        = map(any)
  default     = {}
}

variable "aws_region" {
  description = "The AWS region to provision the resources."
  type        = string
}

variable "codebuild_project_name" {
  description = "The name of the CodeBuild build project."
  type        = string
}

variable "codebuild_project_description" {
  description = "The description of the CodeBuild build project."
  type        = string
}

variable "codebuild_project_environment" {
  description = <<EOT
  The CodeBuild environment configuration.
  `compute_type`: (Required) Information about the compute resources the build project will use.
  `image`: (Required) Docker image to use for this build project.
           Valid values include Docker images provided by CodeBuild, DockerHub images and full
           Docker repository URIs such as those for ECR.
  `type`: (Required) Type of build environment to use for related builds.
  `image_pull_credentials_type`: (Optional) Type of credentials AWS CodeBuild uses to pull images in your build.
  `privileged_mode`: (Optional) Whether to enable running the Docker daemon inside a Docker container.
  EOT
  type = object({
    compute_type                = string
    image                       = string
    type                        = string
    image_pull_credentials_type = optional(string, "CODEBUILD")
    privileged_mode             = optional(bool, true)
  })
  default = {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }
}

variable "codebuild_vpc_config" {
  description = <<EOT
  The VPC configuration to provision the CodeBuild Runners.
  `security_group_ids`: (Required) Security group IDs to assign to running builds.
  `subnets`: (Required) Subnet IDs within which to run builds.
  `vpc_id`: (Required) ID of the VPC within which to run builds.
  EOT
  type = object({
    security_group_ids = list(string)
    subnets            = list(string)
    vpc_id             = string
  })
}

variable "codebuild_logs_config" {
  description = <<EOT
  CodeBuild logs configuration.
  `cloudwatch_logs`: (Optional) Configuration to store logs on AWS CloudWatch.
    - `status`: Current status of logs in CloudWatch Logs for a build project. Valid values: `ENABLED`, `DISABLED`.
    - `group_name`: Group name of the logs in CloudWatch Logs.
    - `stream_name`: Prefix of the log stream name of the logs in CloudWatch Logs.
  `s3_logs`: (Optional) Configuration to store logs on AWS S3.
    - `status`: Current status of logs in S3 for a build project. Valid values: `ENABLED`, `DISABLED`.
    - `location`: Name of the S3 bucket and the path prefix for S3 logs. Must be set if status is ENABLED, otherwise it must be empty.
    - `encryption_disabled`: Whether to disable encrypting S3 logs.
  EOT
  type = object({
    cloudwatch_logs = optional(object({
      status      = string
      group_name  = string
      stream_name = string
    }))
    s3_logs = optional(object({
      status              = string
      location            = string
      encryption_disabled = bool
    }))
  })
  default = {}
}

variable "github_organization_name" {
  description = "The name of the GitHub organization to add the webhook for AWS CodeBuild Runners."
  type        = string
}

variable "pat_aws_secret_name" {
  description = "The name of the AWS Secret Manager secret with the personal access token with access to GitHub."
  type        = string
  default     = ""
}
