#!/usr/bin/env bash
set -euo pipefail
curl -L --fail "https://github.com/brcly/linuwux-runtime/releases/latest/download/LinUwUx.so" -o /usr/lib64/LinUwUx.so
chmod 0755 /usr/lib64/LinUwUx.so
