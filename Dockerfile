# Stage 1: Patching with Node 24 LTS
FROM node:24-alpine AS builder

# Force update npm and the specific vulnerable library identified in your Trivy scan
RUN npm install -g npm@latest fast-xml-parser@5.3.5

# Stage 2: Final n8n Production Image
FROM n8nio/n8n:latest

USER root

# Inject the patched global modules from the Node 24 builder
# This bypasses the 'apk/apt not found' errors in the final image
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin/npm /usr/local/bin/npm

# Choreo Compliance: Fix permissions for UID 10001
# We use chmod 777 for high compatibility in restricted environments
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chmod -R 777 /home/node/.n8n /opt/n8n/config

# Runtime Entrypoint to source your Neon DB .env file
RUN printf '#!/bin/sh\n\
if [ -f "/opt/n8n/config/.env" ]; then\n\
  echo "Loading environment from /opt/n8n/config/.env..."\n\
  export $(grep -v "^#" /opt/n8n/config/.env | xargs)\n\
else\n\
  echo "Waiting for .env mount at /opt/n8n/config/.env..."\n\
fi\n\
exec n8n start' > /entrypoint.sh && chmod +x /entrypoint.sh

# Choreo Security Requirement (UID 10001)
USER 10001
WORKDIR /home/node

ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n

# Port exposure for the Choreo reverse proxy
EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]
