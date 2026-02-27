# Stage 1: Secure Build & Patch with Node 24 LTS
FROM node:24-alpine AS builder

# Update npm to the latest version and patch the vulnerable library
RUN npm install -g npm@latest fast-xml-parser@5.3.5

# Stage 2: Final Production n8n Image
FROM n8nio/n8n:latest

USER root

# Copy patched global modules from the Node 24 builder
# This bypasses the need for apk/apt in the final image
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin/npm /usr/local/bin/npm

# Choreo Compliance: Direct permission handling for UID 10001
# We use chmod 777 for high compatibility in restricted cloud environments
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chmod -R 777 /home/node/.n8n /opt/n8n/config

# Runtime Entrypoint to source your Neon DB .env file
RUN printf '#!/bin/sh\n\
if [ -f "/opt/n8n/config/.env" ]; then\n\
  echo "Loading environment from /opt/n8n/config/.env..."\n\
  export $(grep -v "^#" /opt/n8n/config/.env | xargs)\n\
else\n\
  echo "No .env found at /opt/n8n/config/.env - using defaults."\n\
fi\n\
exec n8n start' > /entrypoint.sh && chmod +x /entrypoint.sh

# Choreo Security requirement (UID 10001)
USER 10001
WORKDIR /home/node

ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n
ENV NODE_VERSION=24

# Port exposure for Choreo
EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]
