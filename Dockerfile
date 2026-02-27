# Use the official n8n image
FROM n8nio/n8n:latest

# Switch to root to configure permissions for Choreo
USER root

# Create directories and fix permissions for UID 10001
# Note: Debian-based images use /home/node as the default home
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chown -R 10001:10001 /home/node /opt/n8n/config

# Create the entrypoint script using standard shell syntax
# This script will load variables from your mounted .env file
RUN printf '#!/bin/sh\n\
if [ -f "/opt/n8n/config/.env" ]; then\n\
  echo "Loading environment variables from /opt/n8n/config/.env..."\n\
  export $(grep -v "^#" /opt/n8n/config/.env | xargs)\n\
fi\n\
exec n8n start' > /entrypoint.sh && chmod +x /entrypoint.sh

# Choreo security requirement: Run as non-root (UID 10000-20000)
USER 10001
WORKDIR /home/node

# Tell n8n where to find its data
ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n

# Expose n8n default port
EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]
