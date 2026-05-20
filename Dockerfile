# ==============================================================================
# Custom n8n Dockerfile (Alpine-based, Multi-stage)
# ==============================================================================
# We leverage a multi-stage build to solve two major challenges:
# 1. Bypassing compilation errors of native Node modules (like isolated-vm). We do
#    this by copying the pre-compiled, official n8n build from 'n8nio/n8n:latest'.
# 2. Retaining the complete 'apk' package manager of Alpine Linux, which was
#    stripped out of n8n's hardened/distroless production image.
#
# This results in an ultra-lightweight Alpine-based image with zero compilation
# overhead and full custom packages (python3, git, curl, jq).
# ==============================================================================

# Stage 1: Reference the official pre-compiled n8n image (contains pre-compiled native addons)
FROM n8nio/n8n:latest AS official_n8n

# Stage 2: Build our custom, package-rich Alpine runtime image
FROM node:24-alpine

# Switch to root to install system-wide utilities
USER root

# Install standard command-line tools and scripting languages
# Since this is a standard Node image, 'apk' is 100% present and functional!
RUN apk add --no-cache \
    curl \
    git \
    openssh-client \
    python3 \
    py3-pip \
    bash \
    jq

# Copy ALL pre-compiled global node_modules (n8n + dependencies like semver)
COPY --from=official_n8n /usr/local/lib/node_modules /usr/local/lib/node_modules

# Create symlink for the n8n CLI binary (must be a symlink so Node.js resolves
# modules correctly relative to /usr/local/lib/node_modules/n8n/bin/n8n)
RUN ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n

# Set up the data directory and ensure correct permissions for the non-root 'node' user
WORKDIR /data
RUN mkdir -p /home/node/.n8n /data && chown -R node:node /home/node/.n8n /data

# Switch back to the non-root node user (Security Best Practice)
USER node

# Expose n8n default port
EXPOSE 5678

# Command to launch n8n
CMD ["n8n", "start"]
