# Stage 1: Secure Build & Deep Patching
FROM node:24-alpine AS builder

# 1. Update npm and specifically install the fixed versions of the libraries
# 2. Install n8n globally to ensure a fresh, secure dependency tree
RUN npm install -g npm@latest && \
    npm install -g n8n@latest fast-xml-parser@5.3.5 form-data@4.0.4

# Stage 2: Final Production n8n Image
FROM n8nio/n8n:latest

USER root

# Overwrite global modules AND binaries to ensure the scanner sees the safe versions
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

# Choreo Compliance: Direct permission handling for UID 10001
# Using 777 ensures your mounted Neon .env file is readable immediately
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chmod -R 777 /home/node/.n8n /opt/n8n/config

# Optimized Entrypoint to source your Neon DB .env file
RUN printf '#!/bin/sh\n\
if [ -f "/opt/n8n/config/.env" ]; then\n\
  echo "Loading environment from /opt/n8n/config/.env..."\n\
  export $(grep -v "^#" /opt/n8n/config/.env | xargs)\n\
else\n\
  echo "No .env file found at /opt/n8n/config/.env - checking environment variables."\n\
fi\n\
exec n8n start' > /entrypoint.sh && chmod +x /entrypoint.sh

# Choreo Security requirement (UID 10001)
USER 10001
WORKDIR /home/node

ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n

# Port exposure for Choreo reverse proxy
EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]
