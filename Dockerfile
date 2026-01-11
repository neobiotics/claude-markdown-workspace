FROM ubuntu:24.04

# System packages
RUN apt-get update && apt-get install -y \
    openssh-server \
    ssh-import-id \
    curl git vim htop ripgrep jq sudo \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# SSH setup
RUN mkdir /var/run/sshd \
    && mkdir -p /root/.ssh \
    && chmod 700 /root/.ssh \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config \
    && echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Workspace
RUN mkdir -p /workspace/notes

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
