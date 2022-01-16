output "deployer_user_key" {
  value = aws_iam_access_key.deployer_key.id
}

output "deployer_user_secret" {
  value     = aws_iam_access_key.deployer_key.secret
  sensitive = true
}

output "ecr_repository_url" {
  value = aws_ecr_repository.ecr_repo.repository_url
}