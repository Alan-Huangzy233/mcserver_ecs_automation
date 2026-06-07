#!/usr/bin/env bash
set -euxo pipefail

echo "Current directory:"
pwd

echo "Repository files:"
ls -la

echo "Checking .ecr_uri..."
if [ ! -f ".ecr_uri" ]; then
  echo "Error: .ecr_uri not found."
  echo "Run ./scripts/01_bootstrap_ecr.sh first."
  exit 1
fi

ECR_URI="$(cat .ecr_uri)"
AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
LOCAL_IMAGE_NAME="minecraft-ecs-automation"
IMAGE_TAG="latest"

echo "AWS account: $ACCOUNT_ID"
echo "AWS region: $AWS_REGION"
echo "ECR URI: $ECR_URI"

echo
echo "Checking ECR repository exists..."
aws ecr describe-repositories --repository-names minecraft-ecs-automation --region "$AWS_REGION"

echo
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo
echo "Building Docker image..."
docker build -t "${LOCAL_IMAGE_NAME}:${IMAGE_TAG}" .

echo
echo "Tagging Docker image..."
docker tag "${LOCAL_IMAGE_NAME}:${IMAGE_TAG}" "${ECR_URI}:${IMAGE_TAG}"

echo
echo "Pushing Docker image to ECR..."
docker push "${ECR_URI}:${IMAGE_TAG}"

echo
echo "Docker image pushed successfully:"
echo "${ECR_URI}:${IMAGE_TAG}"
