#!/usr/bin/env bash
set -euo pipefail

if [ ! -f ".ecr_uri" ]; then
  echo "Error: .ecr_uri not found."
  echo "Run ./scripts/01_bootstrap_ecr.sh and ./scripts/02_build_push.sh first."
  exit 1
fi

ECR_URI="$(cat .ecr_uri)"
IMAGE_URI="${ECR_URI}:latest"

echo "Using Docker image:"
echo "$IMAGE_URI"

echo
echo "Initializing Terraform infra directory..."
terraform -chdir=terraform/infra init

echo
echo "Formatting Terraform infra files..."
terraform -chdir=terraform/infra fmt

echo
echo "Validating Terraform infra configuration..."
terraform -chdir=terraform/infra validate

echo
echo "Applying Terraform infra changes..."
terraform -chdir=terraform/infra apply -auto-approve \
  -var="container_image=${IMAGE_URI}"

echo
echo "Saving NLB DNS name to .nlb_dns..."
terraform -chdir=terraform/infra output -raw nlb_dns_name | tee .nlb_dns

CLUSTER_NAME="$(terraform -chdir=terraform/infra output -raw ecs_cluster_name)"
SERVICE_NAME="$(terraform -chdir=terraform/infra output -raw ecs_service_name)"

echo
echo "Waiting for ECS service to become stable..."
aws ecs wait services-stable \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME"

echo
echo "Infrastructure deployment complete."
echo "Minecraft server address:"
terraform -chdir=terraform/infra output -raw minecraft_server_address
