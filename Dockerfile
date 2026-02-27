# Stage 1: Patching
FROM node:25.7.0-alpine3.23 AS builder
RUN npm install -g npm@11.11.0 && \
    npm install -g n8n@latest fast-xml-parser@5.3.5 form-data@4.0.4 --force

# Stage 2: Production
FROM n8nio/n8n:latest

USER root

# Copy patched libraries
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
# Copy only the n8n related binaries to avoid overwriting base system tools
COPY --from=builder /usr/local/bin/n8n /usr/local/bin/n8n

# Choreo Compliance
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chown -R 10001:0 /home/node /opt/n8n/config /usr/local/lib/node_modules && \
    chmod -R 775 /home/node /opt/n8n/config

# Entrypoint setup
RUN printf '#!/bin/sh\n\
if [ -f "/opt/n8n/config/.env" ]; then\n\
  echo "Loading environment from /opt/n8n/config/.env..."\n\
  export $(grep -v "^#" /opt/n8n/config/.env | xargs)\n\
fi\n\
exec /usr/local/bin/n8n start' > /entrypoint.sh && \
    chmod +x /entrypoint.sh && \
    chown 10001:0 /entrypoint.sh

USER 10001
WORKDIR /home/node
ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n

EXPOSE 5678
ENTRYPOINT ["/entrypoint.sh"]
