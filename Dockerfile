# Use the official n8n image
FROM n8nio/n8n:latest

# Switch to root to fix permissions for Choreo
USER root

# Choreo requires a numeric UID between 10000-20000
# We don't need to create a named user; just setting the ID is enough
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chown -R 10001:10001 /home/node /opt/n8n/config

# Create a simplified entrypoint script using standard shell (sh)
RUN printf '#!/bin/sh\n\
if [ -f "/opt/n8n/config/.env" ]; then\n\
  echo "Loading environment variables from /opt/n8n/config/.env"\n\
  export $(grep -v "^#" /opt/n8n/config/.env | xargs)\n\
fi\n\
exec n8n start' > /entrypoint.sh && chmod +x /entrypoint.sh

# Explicitly set the numeric user
USER 10001
WORKDIR /home/node

# Set n8n specific paths
ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n

# Expose n8n default port
EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]
