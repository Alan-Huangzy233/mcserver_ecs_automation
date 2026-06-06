#!/usr/bin/env bash
set -euo pipefail

echo "WARNING: This will destroy the AWS resources for the Minecraft ECS project."
echo "Do not run this before grading unless you are sure you no longer need the deployment."
echo
read -r -p "Type DESTROY to continue: " CONFIRM

if [ "$CONFIRM" != "DESTROY" ]; then
  echo "Destroy cancelled."
  exit 0
fi

if [ -f ".ecr_uri" ]; then
  ECR_URI="$(cat .ecr_uri)"
  IMAGE_URI="${ECR_URI}:latest"
  echo "Using image URI: $IMAGE_URI"
fi

echo
echo "Destroying ECS/EFS/NLB infrastructure..."
terraform -chdir=terraform/infra destroy -auto-approve \
  -var="container_image=${IMAGE_URI:-placeholder}"

echo
echo "Destroying ECR repository..."
terraform -chdir=terraform/bootstrap destroy -auto-approve

echo
echo "Removing local generated files..."
rm -f .ecr_uri .nlb_dns terraform-output.json

echo
echo "Destroy complete."
