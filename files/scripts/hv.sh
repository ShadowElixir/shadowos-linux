#!/usr/bin/env bash
set -euo pipefail

ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" ]]; then
    echo "Skipping: LinUwUx.so runtime is only supported on x86_64 (current: $ARCH)."
    exit 0
fi

curl -L --fail "https://github.com/brcly/linuwux-runtime/releases/latest/download/LinUwUx.so" -o /usr/lib64/LinUwUx.so
chmod 0755 /usr/lib64/LinUwUx.so

cat << 'EOF' > /usr/bin/hv
#!/usr/bin/env bash
export LD_PRELOAD="${LD_PRELOAD:+$LD_PRELOAD:}LinUwUx.so"
exec "$@"
EOF

chmod +x /usr/bin/hv