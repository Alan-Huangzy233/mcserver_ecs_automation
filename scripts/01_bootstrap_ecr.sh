#!/usr/bin/env bash
set -euo pipefail

echo "Initializing Terraform bootstrap directory..."
terraform -chdir=terraform/bootstrap init

echo "Formatting Terraform bootstrap files..."
terraform -chdir=terraform/bootstrap fmt

echo "Validating Terraform bootstrap configuration..."
terraform -chdir=terraform/bootstrap validate

echo "Creating ECR repository..."
terraform -chdir=terraform/bootstrap apply -auto-approve

echo "Saving ECR repository URI to .ecr_uri..."
terraform -chdir=terraform/bootstrap output -raw repository_url | tee .ecr_uri

echo
echo "ECR bootstrap complete."
echo "Repository URI:"
cat .ecr_uri
