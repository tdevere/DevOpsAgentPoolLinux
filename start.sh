#!/usr/bin/env bash
set -euo pipefail

# Required env vars: AZP_URL, AZP_TOKEN
if [ -z "${AZP_URL:-}" ] || [ -z "${AZP_TOKEN:-}" ]; then
  echo "ERROR: AZP_URL and AZP_TOKEN must be set"
  exit 1
fi

# Default values
AZP_POOL=${AZP_POOL:-Default}
AZP_AGENT_NAME=${AZP_AGENT_NAME:-$(hostname)}

echo ">> Azure DevOps agent startup"
echo "   URL:   $AZP_URL"
echo "   Pool:  $AZP_POOL"
echo "   Agent: $AZP_AGENT_NAME"

# If already configured, remove old registration
if [ -f ".agent" ]; then
  echo ">> Removing existing agent configuration"
  ./config.sh remove --unattended \
    --url   "$AZP_URL" \
    --auth  pat \
    --token "$AZP_TOKEN"

  # clean up any leftover state
  rm -rf _work externals .credentials .agent
fi

echo ">> Configuring agent..."
./config.sh --unattended \
  --url   "$AZP_URL" \
  --auth  pat \
  --token "$AZP_TOKEN" \
  --pool  "$AZP_POOL" \
  --agent "$AZP_AGENT_NAME" \
  --acceptTeeEula

# Graceful cleanup on termination signals
cleanup() {
  echo ">> Removing agent registration..."
  ./config.sh remove --unattended --auth pat --token "$AZP_TOKEN"
}
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

echo ">> Starting agent loop"
exec ./run.sh
