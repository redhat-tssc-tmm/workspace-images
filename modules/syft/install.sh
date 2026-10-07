#!/usr/bin/env bash
set -e

SYFT_VERSION="${SYFT_VERSION:-1.54.1}"
ARCH="amd64"
ASSET="syft_${SYFT_VERSION}_linux_${ARCH}.rpm"
BASE="https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}"

echo "Downloading syft v${SYFT_VERSION}..."
tmp="$(mktemp -d)"
curl -fsSL -o "$tmp/$ASSET" "$BASE/$ASSET"
rpm -ivh "$tmp/$ASSET"
rm -rf "$tmp"

echo "syft installed successfully."
syft version 2>/dev/null || echo "syft binary installed."
