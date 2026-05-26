#!/bin/sh
# Rogue Gateway — launch script with auto-discovered token
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GATEWAY_DIR="$(dirname "$SCRIPT_DIR")"

cd "$GATEWAY_DIR"

# Generate/read auth token
TOKEN_FILE="$HOME/.config/rogue/gateway-token"
mkdir -p "$(dirname "$TOKEN_FILE")"
if [ ! -f "$TOKEN_FILE" ]; then
    python3 -c "import secrets; print(secrets.token_urlsafe(32))" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
fi

echo "Rogue Gateway token: $(head -c 12 "$TOKEN_FILE")..."
echo ""

exec python3 -m uvicorn rogue_gateway.main:app --host 0.0.0.0 --port "${ROGUE_PORT:-8787}" "$@"
