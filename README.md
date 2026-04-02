# Rocket.Chat + OpenClaw — Self-Hosted Deployment

Self-hosted [Rocket.Chat](https://rocket.chat) with a dedicated [OpenClaw](https://github.com/openclaw/openclaw) AI assistant, deployed via Docker Compose.

| Service     | Internal             | External                                   |
|-------------|---------------------|--------------------------------------------|
| Rocket.Chat | `rocketchat:3100`   | `https://chat.balalexv.tech`               |
| OpenClaw    | `openclaw:18790`    | `https://chat.balalexv.tech/openclaw/`     |
| MongoDB     | `mongo:27017`       | internal only                              |

## Prerequisites

- Docker >= 24, Docker Compose v2
- Server at `187.124.171.212` with ports 80, 443 open
- DNS A record: `chat.balalexv.tech → 187.124.171.212`
- Caddy on the host (outside this Compose stack)
- Anthropic API key

## Quick Start

```bash
git clone https://github.com/balalexv-coder/rocketchat-openclaw.git
cd rocketchat-openclaw

# 1. Setup — creates .env, generates gateway token
bash scripts/setup.sh

# 2. Fill in secrets
nano .env

# 3. Launch
docker compose up -d

# 4. Watch Rocket.Chat startup (~60s)
docker compose logs -f rocketchat
```

Open `https://chat.balalexv.tech` once Rocket.Chat is ready.

## Bot User Setup

1. Log in to Rocket.Chat as admin
2. **Administration → Users → New User**
   - Name: `OpenClaw`
   - Username: `openclaw-bot` (must match `ROCKET_CHAT_USER` in `.env`)
   - Password: strong password (must match `ROCKET_CHAT_PASSWORD` in `.env`)
   - Role: `bot`
3. Restart OpenClaw to pick up credentials:

```bash
docker compose restart openclaw
```

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Caddy      │────▶│  Rocket.Chat │◀───▶│   MongoDB   │
│  (TLS/proxy) │     │   :3100      │     │   :27017    │
│              │     └──────────────┘     └─────────────┘
│              │     ┌──────────────┐
│              │────▶│   OpenClaw   │
│              │     │   :18790     │
└─────────────┘     └──────────────┘
```

- **Caddy** terminates TLS, proxies `/openclaw/*` to OpenClaw, everything else to Rocket.Chat
- **OpenClaw** connects to Rocket.Chat via the `openclaw-rocketchat` plugin (baked into the Docker image)
- **MongoDB** runs as a replica set (required by Rocket.Chat)

## Caddy Setup

Copy `caddy/Caddyfile` into your host Caddy config and reload:

```bash
sudo cp caddy/Caddyfile /etc/caddy/Caddyfile.d/chat.balalexv.tech
sudo caddy reload --config /etc/caddy/Caddyfile
```

TLS certificates are obtained automatically (Let's Encrypt / ZeroSSL).

## Environment Variables

| Variable                 | Description                                    |
|--------------------------|------------------------------------------------|
| `ANTHROPIC_API_KEY`      | Anthropic API key                              |
| `OPENCLAW_GATEWAY_TOKEN` | 64-char hex token for OpenClaw gateway         |
| `ROOT_URL`               | Public Rocket.Chat URL                         |
| `ROCKET_CHAT_USER`       | Bot account username                           |
| `ROCKET_CHAT_PASSWORD`   | Bot account password                           |
| `MONGO_URL`              | MongoDB connection string                      |
| `MONGO_OPLOG_URL`        | MongoDB oplog connection string                |

## File Structure

```
├── Dockerfile.openclaw          # OpenClaw image + rocketchat plugin
├── docker-compose.yml           # All services
├── .env.example                 # Template for secrets
├── caddy/
│   └── Caddyfile                # Reverse proxy config
├── openclaw-config/
│   ├── openclaw.json            # OpenClaw configuration
│   └── agents/
│       └── admin/
│           └── SOUL.md          # Agent personality
└── scripts/
    └── setup.sh                 # First-run helper
```

## Operations

```bash
# Update images
docker compose pull
docker compose up -d --build

# View logs
docker compose logs -f openclaw

# Stop (keep data)
docker compose down

# Stop and DELETE all data
docker compose down -v
```

## Notes

- This is a **completely separate** OpenClaw instance (port 18790) — no connection to any existing OpenClaw deployment
- The `openclaw-rocketchat` plugin is pre-installed via `Dockerfile.openclaw`
- MongoDB requires a replica set — `mongo-init` handles initialization automatically
- OpenClaw config is bind-mounted from `./openclaw-config/` → `/home/node/.openclaw/`
