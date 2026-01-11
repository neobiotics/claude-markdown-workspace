# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker Compose setup for NoteDiscovery (markdown viewer) and Claude Code (official Anthropic AI assistant) with SSH access. Uses Anthropic API keys instead of third-party providers.

## Architecture

```
Host → SSH (port 2222) → Claude Code Container (/workspace/notes)
Host → HTTP (port 8800) → NoteDiscovery Container (/app/data)
```

Both containers share the same `./notes` directory.

## Common Commands

### Initial Setup

```bash
# 1. Configure environment
cp .env.example .env

# 2. Edit .env and set:
#    GITHUB_USERS=your-github-username
#    ANTHROPIC_API_KEY=sk-ant-xxxxx

# 3. Build and start
docker compose up -d --build

# First build takes ~5 minutes (npm install)

# 4. Connect via SSH
ssh -p 2222 root@localhost

# 5. Inside container, navigate to notes
cd /workspace/notes

# 6. Start Claude Code
claude
```

### Day-to-day Operations

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Rebuild after Dockerfile changes
docker compose up -d --build

# View logs
docker compose logs -f
docker compose logs -f claude-code

# SSH into Claude Code container
ssh -p 2222 root@localhost

# Access NoteDiscovery web UI
# Open browser to: http://localhost:8800
```

## Configuration Files

### .env

Required environment variables:

```bash
# Comma-separated GitHub usernames for SSH key import
GITHUB_USERS=username1,username2

# Anthropic API key from https://console.anthropic.com/settings/keys
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

SSH keys are fetched from `https://github.com/{username}.keys` during container startup.

### Dockerfile

Ubuntu 24.04 based image with:
- Claude Code CLI (official @anthropic-ai/claude-code package)
- OpenSSH server
- Development tools: git, vim, ripgrep, jq, htop
- Node.js environment

SSH server configured for:
- Root login enabled
- Public key authentication only (no passwords)
- Keys imported from GitHub

### entrypoint.sh

Container startup script:
1. Imports SSH keys from GitHub users specified in `GITHUB_USERS`
2. Exports `ANTHROPIC_API_KEY` to root's `.bashrc`
3. Creates `/root/.claude.json` with:
   - API key marked as trusted (last 20 characters)
   - Onboarding marked as completed
   - Trust dialog accepted
4. Starts SSH daemon

This configuration bypasses the OAuth flow and uses direct API key authentication.

### docker-compose.yml

Defines two services:
- **notediscovery**: Web UI for viewing markdown files
- **claude-code**: SSH container with Claude Code CLI

Both mount `./notes` directory but at different paths.

## Directory Structure

```
.
├── docker-compose.yml          # Service definitions
├── .env                        # Secrets (gitignored)
├── .env.example                # Template
├── Dockerfile                  # Claude Code SSH container
├── entrypoint.sh               # Container startup script
├── claude-data/                # Persistent Claude config
│   └── (Claude Code data)      # (created on first run)
└── notes/                      # Shared markdown files
```

## Anthropic API Key Setup

1. Go to https://console.anthropic.com/settings/keys
2. Click **"Create Key"**
3. Copy the API key (starts with `sk-ant-`)
4. Add to `.env` as `ANTHROPIC_API_KEY=sk-ant-...`

**Important**: Keep your API key secret. Never commit it to version control.

## SSH Access Details

### How SSH Authentication Works

1. Container starts and runs `entrypoint.sh`
2. Script calls `ssh-import-id-gh {GITHUB_USERS}`
3. Public keys downloaded from `https://github.com/{username}.keys`
4. Keys added to `/root/.ssh/authorized_keys`
5. SSH daemon starts on port 22 (mapped to host port 2222)

### Adding/Removing Users

Edit `.env` and change `GITHUB_USERS`, then restart:
```bash
docker compose down
docker compose up -d
```

### Manual Key Management

If you need to add keys manually (without GitHub):
```bash
# Connect to running container
docker compose exec claude-code bash

# Add key to authorized_keys
echo "ssh-rsa AAAA..." >> /root/.ssh/authorized_keys
```

## Claude Code Configuration

### Authentication Flow

Instead of OAuth browser flow, this setup:
1. Uses API key directly via `ANTHROPIC_API_KEY` environment variable
2. Marks the key as trusted in `~/.claude.json` (last 20 characters)
3. Sets `hasCompletedOnboarding: true` to skip onboarding prompts
4. Sets `hasTrustDialogAccepted: true` to skip API key trust prompts

This allows Claude Code to work in a headless SSH environment.

### Useful Claude Code Commands

Once inside the SSH session:

```bash
# Start Claude Code
claude

# Within Claude Code session:
/status         # Show auth method, model, account info
/cost           # Display API usage and costs
/doctor         # Check installation and configuration
/init           # Create CLAUDE.md for current project
/model          # Change model (sonnet, opus, haiku)
/clear          # Clear conversation history
/help           # Show all available commands
```

### Model Selection

Default model is Claude Sonnet 4.5. To use a different model:

```bash
# Start with specific model
claude --model opus
claude --model haiku

# Or change during session
/model opus
```

## Persistent Data

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `./notes` | `/workspace/notes` | Markdown files (shared with NoteDiscovery) |
| `./notes` | `/app/data` | NoteDiscovery data directory |
| `./claude-data` | `/root/.claude` | Claude Code conversation history, cache |
| N/A | `/root/.claude.json` | Config file (recreated on each start) |

**Note**: `.claude.json` is recreated on container startup from environment variables. Don't manually edit it; changes will be lost.

## Workflow

### Typical Development Session

1. **SSH into container**: `ssh -p 2222 root@localhost`
2. **Navigate to notes**: `cd /workspace/notes`
3. **Start Claude Code**: `claude`
4. **Work on notes** with AI assistance
5. **View in browser**: Open `http://localhost:8800` to see rendered markdown
6. **Exit**: Type `exit` or Ctrl+D

### Working with Notes

Notes are stored in `./notes` and synchronized in real-time:
- Claude Code sees them at `/workspace/notes`
- NoteDiscovery serves them from `/app/data`
- Changes made via Claude Code are immediately visible in NoteDiscovery

## Troubleshooting

### SSH Connection Refused

```bash
# Check if container is running
docker compose ps

# Check SSH daemon logs
docker compose logs claude-code

# Verify SSH keys were imported
docker compose exec claude-code cat /root/.ssh/authorized_keys

# Test key format on GitHub
curl https://github.com/YOUR_USERNAME.keys
```

### Claude Code Wants OAuth / API Key Not Recognized

```bash
# Verify API key is set in container
docker compose exec claude-code env | grep ANTHROPIC

# Check .claude.json was created
docker compose exec claude-code cat /root/.claude.json

# Verify API key format
# Should start with: sk-ant-

# Test API key manually (from inside container)
docker compose exec claude-code bash
echo $ANTHROPIC_API_KEY
claude --version
```

### GitHub Keys Not Importing

If `GITHUB_USERS` is set but SSH still fails:

1. Verify GitHub username is correct
2. Ensure you have SSH keys added to your GitHub account: https://github.com/settings/keys
3. Test key availability: `curl https://github.com/YOUR_USERNAME.keys`
4. Restart container: `docker compose restart claude-code`

### NoteDiscovery Not Loading

```bash
# Check container status
docker compose ps notediscovery

# View logs
docker compose logs -f notediscovery

# Verify notes directory exists and has files
ls -la ./notes

# Restart service
docker compose restart notediscovery
```

### Permission Issues with Notes

If you can't edit files in `./notes`:

```bash
# Check ownership
ls -la ./notes

# Fix permissions (from host)
sudo chown -R $(id -u):$(id -g) ./notes

# Or fix from container
docker compose exec claude-code chown -R root:root /workspace/notes
```

### API Rate Limits / Cost Concerns

```bash
# Inside Claude Code session, check costs
/cost

# Monitor usage in Anthropic Console
# https://console.anthropic.com/settings/usage
```

## Optional: NoteDiscovery Authentication

To enable password protection for NoteDiscovery, edit `docker-compose.yml`:

```yaml
notediscovery:
  environment:
    - AUTHENTICATION_ENABLED=true
    - AUTHENTICATION_PASSWORD=your-secure-password
```

Then restart: `docker compose up -d`

## Security Considerations

⚠️ **Default setup has limited authentication**:
- NoteDiscovery web UI is publicly accessible on port 8800 (unless auth enabled)
- SSH is only as secure as your GitHub account and SSH keys
- API key is stored in plaintext in `.env` file
- Intended for **local development** or **trusted networks only**

For production use with remote access:
- Enable NoteDiscovery authentication
- Use firewall rules to restrict port access
- Consider using the `opencode-authelia-setup` project for 2FA

## Differences from opencode-notediscovery

| Feature | This Project (Claude Code) | opencode-notediscovery |
|---------|----------------------------|------------------------|
| AI Provider | Anthropic (official) | OVH AI Endpoints |
| Model | Claude Sonnet 4.5 | Meta-Llama-3.3-70B |
| Authentication | API Key | API Key (OVH) |
| CLI Tool | @anthropic-ai/claude-code | opencode-ai |
| Configuration | ~/.claude.json | opencode.json |
| Cost | Pay-per-use (Anthropic) | Pay-per-use (OVH) |
| Setup Complexity | Low | Low |

## Git Configuration in Container

Since `/root/.ssh` is not persistent, use Personal Access Token for GitHub authentication:

```bash
# Configure git to store credentials in persistent directory
git config --global credential.helper 'store --file=/root/.claude/.git-credentials'

# On first push, Git will ask for credentials:
git push
# Username: neobiotics
# Password: <paste personal access token>

# Token is stored in /root/.claude/.git-credentials (survives container restarts)
```

**Create Personal Access Token**:
1. https://github.com/settings/tokens/new
2. Note: `claude-workspace`
3. Expiration: 90 days or longer
4. Scopes: Check `repo`
5. Generate and copy token

## Differences from opencode-authelia-setup

| Feature | This Project | opencode-authelia-setup |
|---------|--------------|-------------------------|
| Authentication | None (SSH keys only) | 2FA (Authelia) |
| Remote Access | Manual port forwarding | Tailscale Funnel |
| Complexity | Simple (2 services) | Complex (6 services) |
| Use Case | Local development | Production/remote access |
