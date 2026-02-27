# Stage 1: Build/Patching
FROM node:25.7.0-alpine3.23 AS builder

# Check your version here - changed to a known stable or 'latest'
RUN npm install -g npm@11.11.0 && \
    npm install -g n8n@latest fast-xml-parser@5.3.5 form-data@4.0.4 --force

# Stage 2: Final n8n Production Image
# Note: Ensure 1.23.23 is the actual version you want; 
# official images usually follow n8nio/n8n:1.x.y
FROM n8nio/n8n:latest

USER root

# Copy only the global modules we updated/patched
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

# Choreo Compliance: Creating directories and setting permissions for UID 10001
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chown -R 10001:0 /home/node /opt/n8n/config && \
    chmod -R 775 /home/node /opt/n8n/config

# Fixed Entrypoint script with proper escaping
RUN printf '#!/bin/sh\n\
if [ -f "/opt/n8n/config/.env" ]; then\n\
  echo "Loading environment from /opt/n8n/config/.env..."\n\
  export $(grep -v "^#" /opt/n8n/config/.env | xargs)\n\
fi\n\
exec n8n start' > /entrypoint.sh && chmod +x /entrypoint.sh

# Choreo Security Requirement
USER 10001
WORKDIR /home/node

ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n

EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]
