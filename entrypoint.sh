#!/bin/bash
set -e

# Import SSH keys from GitHub
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

    # Make API key available for SSH sessions
    if ! grep -q "ANTHROPIC_API_KEY" /root/.bashrc 2>/dev/null; then
        echo "export ANTHROPIC_API_KEY=\"$ANTHROPIC_API_KEY\"" >> /root/.bashrc
    fi

    # Last 20 characters for trust config
    ANTHROPIC_API_KEY_LAST_20="${ANTHROPIC_API_KEY: -20}"

    # ~/.claude.json - mark key as trusted + skip onboarding
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

# Start SSH server
exec /usr/sbin/sshd -D
