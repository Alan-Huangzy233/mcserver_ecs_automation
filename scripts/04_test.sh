#!/usr/bin/env bash
set -euo pipefail

if [ ! -f ".nlb_dns" ]; then
  echo "Error: .nlb_dns not found."
  echo "Run ./scripts/03_apply_infra.sh first."
  exit 1
fi

NLB_DNS="$(tr -d '\n' < .nlb_dns)"
PORT="25565"

echo "Minecraft server endpoint:"
echo "${NLB_DNS}:${PORT}"
echo

echo "Checking ECS service status..."
CLUSTER_NAME="$(terraform -chdir=terraform/infra output -raw ecs_cluster_name)"
SERVICE_NAME="$(terraform -chdir=terraform/infra output -raw ecs_service_name)"

aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --query "services[0].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount}" \
  --output table

echo
echo "Testing Minecraft server with nmap..."
echo "Command: nmap -sV -Pn -p T:${PORT} ${NLB_DNS}"
echo

for i in {1..10}; do
  echo "nmap attempt $i/10..."

  NMAP_OUTPUT="$(nmap -sV -Pn -p "T:${PORT}" "$NLB_DNS" || true)"
  echo "$NMAP_OUTPUT"

  if echo "$NMAP_OUTPUT" | grep -q "${PORT}/tcp open"; then
    echo
    echo "Minecraft server is reachable on TCP ${PORT}."
    exit 0
  fi

  if [ "$i" = "10" ]; then
    echo
    echo "Error: Minecraft server did not become reachable on TCP ${PORT}."
    exit 1
  fi

  echo
  echo "Port is not open yet. Waiting 30 seconds before retrying..."
  sleep 30
done
