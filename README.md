# Claude Code + NoteDiscovery Setup

Self-hosted Markdown Notes mit Web UI und Claude Code CLI via SSH.

## Übersicht

| Service | Zweck | Zugang |
|---------|-------|--------|
| **NoteDiscovery** | Web UI für Markdown Notes | `http://server:8800` |
| **Claude Code** | AI-Assistant via SSH | `ssh -p 2222 root@server` |

Beide Container teilen sich das gleiche Notes-Verzeichnis.

## Dateistruktur

```
project/
├── docker-compose.yml
├── .env                    # Aus .env.example erstellen
├── .env.example
├── claude-ssh/
│   ├── Dockerfile
│   └── entrypoint.sh
├── claude-data/            # Wird automatisch erstellt (Claude Config)
└── notes/                  # Deine Markdown Notes
```

## Setup

### 1. Repository klonen / Dateien kopieren

### 2. Environment-Variablen konfigurieren

```bash
cp .env.example .env
```

`.env` bearbeiten:
```bash
GITHUB_USERS=dein-github-username
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

**Mehrere GitHub-User:** `GITHUB_USERS=user1,user2,user3` (ohne Leerzeichen)

### 3. Notes-Verzeichnis anlegen (optional)

```bash
mkdir -p notes
```

### 4. Starten

```bash
docker compose up -d --build
```

Erster Build dauert ~5 Minuten (npm install).

## Verwendung

### Web UI (NoteDiscovery)

Browser öffnen: `http://server:8800`

### Claude Code via SSH

```bash
ssh -p 2222 root@server
cd /workspace/notes
claude
```

**Nützliche Befehle in Claude Code:**
- `/status` - Auth-Methode, Model, Account
- `/cost` - Bisherige API-Kosten
- `/doctor` - Installation prüfen
- `/init` - CLAUDE.md für Projekt erstellen

## Wie es funktioniert

### SSH-Key Import

Der Container holt SSH-Keys automatisch von GitHub beim Start:
1. `GITHUB_USERS` wird gelesen
2. `ssh-import-id-gh` holt Keys von `https://github.com/<user>.keys`
3. Keys werden in `/root/.ssh/authorized_keys` geschrieben

### API Key Setup

Statt Browser-OAuth wird der API Key direkt konfiguriert:
1. Key wird in `/root/.bashrc` exportiert
2. `~/.claude.json` markiert den Key als trusted (letzten 20 Zeichen)
3. Onboarding wird übersprungen

### Persistenz

| Pfad | Bind Mount | Persistiert? |
|------|------------|--------------|
| `/workspace/notes` | `./notes` | ✅ |
| `/root/.claude` | `./claude-data` | ✅ |
| `/root/.claude.json` | - | ❌ (wird bei Start neu erstellt) |

## Troubleshooting

### SSH Permission denied

```bash
# Prüfen ob Key auf GitHub ist
curl https://github.com/DEIN_USERNAME.keys

# Container Logs checken
docker compose logs claude-code
```

### Claude Code startet nicht / will OAuth

```bash
# Im Container prüfen
docker exec -it claude-code bash
echo $ANTHROPIC_API_KEY
cat /root/.claude.json
```

### Logs anzeigen

```bash
docker compose logs -f
docker compose logs -f claude-code
```

### Rebuild nach Änderungen

```bash
docker compose down && docker compose up -d --build
```

## Anpassungen

### Notes-Pfad ändern

In `docker-compose.yml` beide Volumes anpassen:
```yaml
volumes:
  - /dein/pfad:/app/data          # NoteDiscovery
  - /dein/pfad:/workspace/notes   # Claude Code
```

### NoteDiscovery Auth aktivieren

```yaml
notediscovery:
  environment:
    - AUTHENTICATION_ENABLED=true
    - AUTHENTICATION_PASSWORD=dein-passwort
```

### Anderes Model verwenden

In Claude Code: `/model` oder beim Start: `claude --model opus`
