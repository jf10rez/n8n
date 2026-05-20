# ==============================================================================
# Custom n8n Dockerfile
# ==============================================================================
# Based on the official, highly-optimized n8n alpine image.
# This custom image adds helpful tools (git, python3, curl, jq) for use in
# n8n workflows (e.g. within "Execute Command" nodes) while maintaining security
# and a slim footprint.
# ==============================================================================

FROM docker.n8n.io/n8nio/n8n:latest

# Switch to root to install system-wide utilities
USER root

# Install system dependencies
# - curl & jq: for quick CLI API calls and JSON parsing
# - git & openssh-client: for interacting with Git repositories
# - python3 & py3-pip: for running Python scripts directly in n8n workflows
# - bash: for more advanced shell scripts
RUN apk add --no-cache \
    curl \
    git \
    openssh-client \
    python3 \
    py3-pip \
    bash \
    jq

# Upgrade pip and install a basic set of Python libraries (optional/customizable)
# RUN pip3 install --no-cache-dir --upgrade pip requests

# Ensure the n8n storage directory (/home/node/.n8n) has correct permissions
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

# Switch back to the non-root node user (Security Best Practice)
USER node

# Expose n8n default port
EXPOSE 5678

# The default command inherited from the parent image is "n8n start",
# so no need to redeclare it unless you have a custom start script.
