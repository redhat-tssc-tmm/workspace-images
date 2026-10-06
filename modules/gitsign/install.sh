#!/usr/bin/env bash
set -e

CLI_SERVER="http://cli-server.trusted-artifact-signer.svc:8080"
GITSIGN_URL="${CLI_SERVER}/clients/linux/gitsign-amd64.gz"

echo "Downloading gitsign from TAS cli-server..."
for i in $(seq 1 30); do
  if curl -sfL "${GITSIGN_URL}" | gunzip > /usr/local/bin/gitsign 2>/dev/null; then
    chmod +x /usr/local/bin/gitsign
    echo "gitsign installed successfully."
    gitsign version 2>/dev/null || echo "gitsign binary installed (version check skipped)."
    exit 0
  fi
  echo "  cli-server not ready, retrying in 10s... (attempt ${i}/30)"
  sleep 10
done

echo "ERROR: Failed to download gitsign after 30 attempts."
exit 1
