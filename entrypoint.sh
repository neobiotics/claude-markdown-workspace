#!/bin/bash
set -e

# SSH Keys von GitHub importieren
if [ -n "$GITHUB_USERS" ]; then
    echo "Importing SSH keys from GitHub..."
    ssh-import-id-gh ${GITHUB_USERS//,/ }
    echo "SSH keys imported."
else
    echo "WARNING: No GITHUB_USERS set. SSH login will not work!"
fi

# Claude Code API Key Setup
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "Setting up Claude Code API key..."
    
    # API Key für SSH Sessions verfügbar machen
    if ! grep -q "ANTHROPIC_API_KEY" /root/.bashrc 2>/dev/null; then
        echo "export ANTHROPIC_API_KEY=\"$ANTHROPIC_API_KEY\"" >> /root/.bashrc
    fi
    
    # Letzten 20 Zeichen für Trust-Config
    ANTHROPIC_API_KEY_LAST_20="${ANTHROPIC_API_KEY: -20}"
    
    # ~/.claude.json - Key als trusted markieren + Onboarding überspringen
    cat <<EOF > /root/.claude.json
{
  "customApiKeyResponses": {
    "approved": ["$ANTHROPIC_API_KEY_LAST_20"],
    "rejected": []
  },
  "hasCompletedOnboarding": true,
  "hasTrustDialogAccepted": true
}
EOF
    
    echo "Claude Code configured with API key."
else
    echo "WARNING: No ANTHROPIC_API_KEY set. Claude Code will require OAuth login."
fi

# SSH Server starten
exec /usr/sbin/sshd -D
