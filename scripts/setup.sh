#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "=== Rocket.Chat + OpenClaw setup ==="

# ── .env ────────────────────────────────────────────────────────────────────
if [[ -f .env ]]; then
  echo "[✓] .env already exists — skipping copy"
else
  cp .env.example .env
  echo "[✓] Created .env from .env.example"
fi

# ── Generate gateway token ──────────────────────────────────────────────────
if grep -q 'OPENCLAW_GATEWAY_TOKEN=0000' .env 2>/dev/null; then
  TOKEN="$(openssl rand -hex 32)"
  sed -i.bak "s|^OPENCLAW_GATEWAY_TOKEN=.*|OPENCLAW_GATEWAY_TOKEN=${TOKEN}|" .env
  rm -f .env.bak
  echo "[✓] Generated random OPENCLAW_GATEWAY_TOKEN"
else
  echo "[✓] OPENCLAW_GATEWAY_TOKEN already set"
fi

# ── Directories ─────────────────────────────────────────────────────────────
mkdir -p openclaw-config/agents/main
echo "[✓] Config directories verified"

# ── SOUL.md ─────────────────────────────────────────────────────────────────
if [[ ! -f openclaw-config/agents/main/SOUL.md ]]; then
  cp openclaw-config/agents/admin/SOUL.md openclaw-config/agents/main/SOUL.md 2>/dev/null || true
  echo "[✓] Copied agent SOUL.md"
fi

echo ""
echo "Next steps:"
echo "  1. Edit .env — fill in ANTHROPIC_API_KEY and ROCKET_CHAT_PASSWORD"
echo "  2. Run: docker compose up -d"
echo "  3. Wait for Rocket.Chat to start (~60s): docker compose logs -f rocketchat"
echo "  4. Open https://chat.balalexv.tech and create the bot user (see README)"
echo "  5. Restart OpenClaw: docker compose restart openclaw"
echo ""
echo "Done!"
