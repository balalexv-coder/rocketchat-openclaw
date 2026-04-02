# Rocket.Chat + OpenClaw — Self-Hosted Deployment

Self-hosted [Rocket.Chat](https://rocket.chat) paired with a dedicated [OpenClaw](https://github.com/openclaw/openclaw) AI-assistant instance, deployed via Docker Compose on a VPS.

| Service | Internal address | External |
|---------|-----------------|---------|
| Rocket.Chat | `rocketchat:3100` | `https://chat.balalexv.tech` |
| OpenClaw | `openclaw:18790` | `https://chat.balalexv.tech/openclaw/` |
| MongoDB | `mongo:27017` | internal only |

## Prerequisites

- Docker >= 24 and Docker Compose v2
- A server reachable at `187.124.171.212` with ports 80, 443 open
- DNS `A` record: `chat.balalexv.tech → 187.124.171.212`
- Caddy (or another reverse proxy) running on the host, **outside** this Compose stack
- An Anthropic API key

## Quick start

```bash
git clone <this-repo> rocketchat-openclaw
cd rocketchat-openclaw

# 1. Run the setup script (copies .env, generates a gateway token)
bash scripts/setup.sh

# 2. Fill in the required secrets
$EDITOR .env

# 3. Start everything
docker compose up -d

# 4. Tail logs until Rocket.Chat is ready
docker compose logs -f rocketchat
```

Open `https://chat.balalexv.tech` once Rocket.Chat reports it is listening.

## Bot user setup

OpenClaw authenticates to Rocket.Chat as a regular bot user.

1. Log in to Rocket.Chat as an administrator.
2. Go to **Administration → Users → New User**.
3. Fill in:
   - **Name**: OpenClaw
   - **Username**: `openclaw-bot` (must match `ROCKET_CHAT_USER` in `.env`)
   - **Password**: strong password (must match `ROCKET_CHAT_PASSWORD` in `.env`)
   - **Role**: `bot`
4. Save, then restart the OpenClaw container so it picks up the credentials:

```bash
docker compose restart openclaw
```

## openclaw-rocketchat plugin install

The `openclaw-rocketchat` community npm package must be installed inside the running OpenClaw container:

```bash
docker compose exec openclaw npm install -g openclaw-rocketchat
docker compose restart openclaw
```

OpenClaw will discover and load the plugin automatically on next start.

## Caddy reverse proxy

Copy (or include) the snippet in `caddy/Caddyfile` into your Caddy configuration and reload:

```bash
sudo caddy reload --config /etc/caddy/Caddyfile
```

Key points:
- The `/openclaw/` path prefix is handled **before** the Rocket.Chat catch-all.
- WebSocket upgrade is handled automatically by Caddy's `reverse_proxy` directive.
- TLS certificates are obtained automatically via ACME (Let's Encrypt / ZeroSSL).

## Environment variables

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Anthropic API key for the OpenClaw AI provider |
| `OPENCLAW_GATEWAY_TOKEN` | 64-char hex token securing the OpenClaw gateway |
| `ROOT_URL` | Public URL of Rocket.Chat (used by the browser) |
| `ROCKET_CHAT_URL` | Internal URL OpenClaw uses to reach Rocket.Chat |
| `ROCKET_CHAT_USER` | Rocket.Chat bot account username |
| `ROCKET_CHAT_PASSWORD` | Rocket.Chat bot account password |
| `MONGO_URL` | MongoDB connection string for Rocket.Chat |
| `MONGO_OPLOG_URL` | MongoDB oplog connection string for Rocket.Chat |

## Project structure

```
.
├── caddy/
│   └── Caddyfile            # Caddy reverse-proxy snippet
├── openclaw-config/
│   ├── openclaw.json        # OpenClaw configuration
│   └── agents/
│       └── admin/
│           └── SOUL.md      # Agent personality / role definition
├── scripts/
│   └── setup.sh             # First-run helper
├── docker-compose.yml
├── .env.example
└── .gitignore
```

## Updating

```bash
docker compose pull
docker compose up -d
```

## Stopping / cleanup

```bash
# Stop containers, keep volumes
docker compose down

# Stop containers AND delete all data volumes (destructive!)
docker compose down -v
```
