#!/usr/bin/env bash
set -euo pipefail

ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" ]]; then
    echo "Skipping: Legion is only supported on x86_64 (current: $ARCH)."
    exit 0
fi

curl -L --fail "https://github.com/ShadowElixir/legion-kvm/releases/latest/download/legion-linux-x86_64" -o /usr/bin/legion
chmod +x /usr/bin/legion