#!/usr/bin/env bash
set -euo pipefail

if [ ! -f ".nlb_dns" ]; then
  echo "Error: .nlb_dns not found."
  echo "Run ./scripts/03_apply_infra.sh first."
  exit 1
fi

NLB_DNS="$(tr -d '\n' < .nlb_dns)"
PORT="25565"

CLUSTER_NAME="$(terraform -chdir=terraform/infra output -raw ecs_cluster_name)"
SERVICE_NAME="$(terraform -chdir=terraform/infra output -raw ecs_service_name)"

echo "This script performs a controlled ECS restart."
echo "For a stateful Minecraft server using EFS, this avoids running two tasks against the same world data."
echo

echo "Scaling ECS service down to 0 tasks..."
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --desired-count 0 \
  --query "service.{serviceName:serviceName,status:status,desired:desiredCount,running:runningCount,pending:pendingCount}" \
  --output table

echo
echo "Waiting for ECS service to stop all tasks..."
for i in {1..40}; do
  STATUS_OUTPUT="$(aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services "$SERVICE_NAME" \
    --query "services[0].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount}" \
    --output json)"

  echo "Stop check $i/40:"
  echo "$STATUS_OUTPUT" | jq .

  DESIRED="$(echo "$STATUS_OUTPUT" | jq -r '.desired')"
  RUNNING="$(echo "$STATUS_OUTPUT" | jq -r '.running')"
  PENDING="$(echo "$STATUS_OUTPUT" | jq -r '.pending')"

  if [ "$DESIRED" = "0" ] && [ "$RUNNING" = "0" ] && [ "$PENDING" = "0" ]; then
    echo "All ECS tasks are stopped."
    break
  fi

  if [ "$i" = "40" ]; then
    echo "Error: ECS service did not scale down in time."
    exit 1
  fi

  sleep 15
done

echo
echo "Scaling ECS service back up to 1 task..."
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --desired-count 1 \
  --query "service.{serviceName:serviceName,status:status,desired:desiredCount,running:runningCount,pending:pendingCount}" \
  --output table

echo
echo "Waiting for ECS service to run 1 task..."
for i in {1..40}; do
  STATUS_OUTPUT="$(aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services "$SERVICE_NAME" \
    --query "services[0].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount}" \
    --output json)"

  echo "Start check $i/40:"
  echo "$STATUS_OUTPUT" | jq .

  DESIRED="$(echo "$STATUS_OUTPUT" | jq -r '.desired')"
  RUNNING="$(echo "$STATUS_OUTPUT" | jq -r '.running')"
  PENDING="$(echo "$STATUS_OUTPUT" | jq -r '.pending')"

  if [ "$DESIRED" = "1" ] && [ "$RUNNING" = "1" ] && [ "$PENDING" = "0" ]; then
    echo "ECS service is running again."
    break
  fi

  if [ "$i" = "40" ]; then
    echo "Error: ECS service did not scale back up in time."
    exit 1
  fi

  sleep 15
done

echo
echo "Waiting 60 seconds for the Minecraft server and NLB health check..."
sleep 60

echo
echo "Testing Minecraft server after controlled ECS restart..."
echo "Command: nmap -sV -Pn -p T:${PORT} ${NLB_DNS}"
echo

nmap -sV -Pn -p "T:${PORT}" "$NLB_DNS"
