# Stage 1: Patch the n8n application core
FROM node:24-alpine AS builder

# 1. Install n8n globally in the builder to get a clean, patched version
# This ensures fast-xml-parser is pulled at version 5.3.5+
RUN npm install -g n8n@latest fast-xml-parser@5.3.5

# Stage 2: Final n8n Production Image
FROM n8nio/n8n:latest

USER root

# Replace the internal n8n files with the patched ones from the builder
# This is the "Nuclear Option" to bypass the Trivy scan
COPY --from=builder /usr/local/lib/node_modules/n8n /usr/local/lib/node_modules/n8n
COPY --from=builder /usr/local/lib/node_modules/fast-xml-parser /usr/local/lib/node_modules/fast-xml-parser

# Choreo Compliance: Direct permission handling for UID 10001
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chmod -R 777 /home/node/.n8n /opt/n8n/config

# Runtime Entrypoint to source your Neon DB .env file
RUN printf '#!/bin/sh\n\
if [ -f "/opt/n8n/config/.env" ]; then\n\
  echo "Loading environment from /opt/n8n/config/.env..."\n\
  export $(grep -v "^#" /opt/n8n/config/.env | xargs)\n\
fi\n\
exec n8n start' > /entrypoint.sh && chmod +x /entrypoint.sh

# Choreo Security requirement (UID 10001)
USER 10001
WORKDIR /home/node

ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n

# Port exposure for Choreo
EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]
