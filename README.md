# Claude Code + NoteDiscovery Setup

Self-hosted Markdown Notes with Web UI and Claude Code CLI via SSH.

## Overview

| Service | Purpose | Access |
|---------|---------|--------|
| **NoteDiscovery** | Web UI for Markdown Notes | `http://server:8800` |
| **Claude Code** | AI Assistant via SSH | `ssh -p 2222 root@server` |

Both containers share the same notes directory.

## File Structure

```
project/
├── docker-compose.yml
├── .env                    # Create from .env.example
├── .env.example
├── claude-ssh/
│   ├── Dockerfile
│   └── entrypoint.sh
├── claude-data/            # Created automatically (Claude Config)
└── notes/                  # Your Markdown Notes
```

## Setup

### 1. Clone repository / Copy files

### 2. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env`:
```bash
GITHUB_USERS=your-github-username
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

**Multiple GitHub users:** `GITHUB_USERS=user1,user2,user3` (no spaces)

### 3. Create notes directory (optional)

```bash
mkdir -p notes
```

### 4. Start

```bash
docker compose up -d --build
```

First build takes ~5 minutes (npm install).

## Usage

### Web UI (NoteDiscovery)

Open browser: `http://server:8800`

### Claude Code via SSH

```bash
ssh -p 2222 root@server
cd /workspace/notes
claude
```

**Useful Claude Code commands:**
- `/status` - Auth method, model, account
- `/cost` - API usage costs
- `/doctor` - Check installation
- `/init` - Create CLAUDE.md for project

## How it works

### SSH Key Import

The container automatically fetches SSH keys from GitHub on startup:
1. Reads `GITHUB_USERS` environment variable
2. `ssh-import-id-gh` fetches keys from `https://github.com/<user>.keys`
3. Keys are written to `/root/.ssh/authorized_keys`

### API Key Setup

Instead of browser OAuth, the API key is configured directly:
1. Key is exported in `/root/.bashrc`
2. `~/.claude.json` marks the key as trusted (last 20 characters)
3. Onboarding is skipped

### Persistence

| Path | Bind Mount | Persistent? |
|------|------------|-------------|
| `/workspace/notes` | `./notes` | ✅ |
| `/root/.claude` | `./claude-data` | ✅ |
| `/root/.claude.json` | - | ❌ (recreated on start) |

## Troubleshooting

### SSH Permission denied

```bash
# Check if key exists on GitHub
curl https://github.com/YOUR_USERNAME.keys

# Check container logs
docker compose logs claude-code
```

### Claude Code doesn't start / wants OAuth

```bash
# Check inside container
docker exec -it claude-code bash
echo $ANTHROPIC_API_KEY
cat /root/.claude.json
```

### Show logs

```bash
docker compose logs -f
docker compose logs -f claude-code
```

### Rebuild after changes

```bash
docker compose down && docker compose up -d --build
```

## Customization

### Change notes path

Adjust both volumes in `docker-compose.yml`:
```yaml
volumes:
  - /your/path:/app/data          # NoteDiscovery
  - /your/path:/workspace/notes   # Claude Code
```

### Enable NoteDiscovery authentication

```yaml
notediscovery:
  environment:
    - AUTHENTICATION_ENABLED=true
    - AUTHENTICATION_PASSWORD=your-password
```

### Use different model

In Claude Code: `/model` or on startup: `claude --model opus`
