output "codebuild_webhook_url" {
  description = "The URL to the webhook."
  value       = aws_codebuild_webhook.this.url
}

output "codebuild_webhook_payload_url" {
  description = "The CodeBuild endpoint where webhook events are sent."
  value       = aws_codebuild_webhook.this.payload_url
}
