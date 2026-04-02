#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# ── .env ────────────────────────────────────────────────────────────────────
if [[ -f .env ]]; then
  echo "[setup] .env already exists — skipping copy."
else
  cp .env.example .env
  echo "[setup] Copied .env.example → .env"
fi

# ── Generate gateway token ──────────────────────────────────────────────────
if grep -q 'OPENCLAW_GATEWAY_TOKEN=0000' .env 2>/dev/null; then
  TOKEN="$(openssl rand -hex 32)"
  # Portable in-place sed (works on both GNU and BSD/macOS)
  sed -i.bak "s|^OPENCLAW_GATEWAY_TOKEN=.*|OPENCLAW_GATEWAY_TOKEN=${TOKEN}|" .env && rm -f .env.bak
  echo "[setup] Generated random OPENCLAW_GATEWAY_TOKEN."
else
  echo "[setup] OPENCLAW_GATEWAY_TOKEN already set — skipping."
fi

# ── Required directories ─────────────────────────────────────────────────────
mkdir -p openclaw-config/agents/admin
echo "[setup] Config directories verified."

# ── Reminder ────────────────────────────────────────────────────────────────
echo ""
echo "Next steps:"
echo "  1. Edit .env and fill in ANTHROPIC_API_KEY, ROCKET_CHAT_USER, ROCKET_CHAT_PASSWORD."
echo "  2. Run: docker compose up -d"
echo "  3. Open https://chat.balalexv.tech and complete the Rocket.Chat setup wizard."
echo "  4. Create the bot user account (see README.md)."
echo "  5. Install the openclaw-rocketchat plugin inside the OpenClaw container (see README.md)."
