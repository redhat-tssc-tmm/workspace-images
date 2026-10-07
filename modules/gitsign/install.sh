#!/usr/bin/env bash
set -e

# --- Part 1: Download gitsign from TAS cli-server ---
CLI_SERVER="http://cli-server.trusted-artifact-signer.svc:8080"
GITSIGN_URL="${CLI_SERVER}/clients/linux/gitsign-amd64.gz"

echo "Downloading gitsign from TAS cli-server..."
for i in $(seq 1 30); do
  if curl -sfL "${GITSIGN_URL}" | gunzip > /usr/local/bin/gitsign 2>/dev/null; then
    chmod +x /usr/local/bin/gitsign
    echo "gitsign installed successfully."
    gitsign version 2>/dev/null || echo "gitsign binary installed (version check skipped)."
    break
  fi
  echo "  cli-server not ready, retrying in 10s... (attempt ${i}/30)"
  sleep 10
  if [ "$i" -eq 30 ]; then
    echo "ERROR: Failed to download gitsign after 30 attempts."
    exit 1
  fi
done

# --- Part 2: Download gitsign-credential-cache from upstream GitHub releases ---
# RHTAS does not ship gitsign-credential-cache; it comes from upstream sigstore/gitsign.
CACHE_VERSION="0.17.1"
CACHE_ARCH="amd64"
CACHE_ASSET="gitsign-credential-cache_${CACHE_VERSION}_linux_${CACHE_ARCH}"
CACHE_BASE="https://github.com/sigstore/gitsign/releases/download/v${CACHE_VERSION}"

echo "Downloading gitsign-credential-cache v${CACHE_VERSION} from GitHub..."
tmp="$(mktemp -d)"
curl -fsSL -o "$tmp/$CACHE_ASSET" "$CACHE_BASE/$CACHE_ASSET"
curl -fsSL -o "$tmp/checksums.txt" "$CACHE_BASE/checksums.txt"
(cd "$tmp" && sha256sum --ignore-missing -c checksums.txt)
install -m 0755 "$tmp/$CACHE_ASSET" /usr/local/bin/gitsign-credential-cache
rm -rf "$tmp"
echo "gitsign-credential-cache installed successfully."
gitsign-credential-cache --version 2>/dev/null || echo "gitsign-credential-cache binary installed (version check skipped)."
