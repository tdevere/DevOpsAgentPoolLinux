#!/usr/bin/env bash
set -e

# Required env vars: AZP_URL, AZP_TOKEN, AZP_POOL, AZP_AGENT_NAME
if [ -z "$AZP_URL" ] || [ -z "$AZP_TOKEN" ]; then
  echo "ERROR: AZP_URL and AZP_TOKEN must be set"
  exit 1
fi

# Default pool/agent name
AZP_POOL=${AZP_POOL:-Default}
AZP_AGENT_NAME=${AZP_AGENT_NAME:-$(hostname)}

echo "→ Configuring Azure Pipelines agent"
./config.sh \
  --unattended \
  --url "$AZP_URL" \
  --auth pat \
  --token "$AZP_TOKEN" \
  --pool "$AZP_POOL" \
  --agent "$AZP_AGENT_NAME" \
  --acceptTeeEula

cleanup() {
  echo "→ Removing Azure Pipelines agent"
  ./config.sh remove --unattended --auth pat --token "$AZP_TOKEN"
}
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

echo "→ Running Azure Pipelines agent"
exec ./run.sh
